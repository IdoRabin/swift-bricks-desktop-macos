//
//  FileLog.swift
//  Bricks
//
//  Created by Ido on 19/01/2022.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("FileLog")
fileprivate let dlogMapping : DSLogger? = nil // DLog.forClass("FileLog-Mapping")
fileprivate let dlogReadlines : DSLogger? = nil // DLog.forClass("FileLog-Read")

class FileLog : NSObject/* for allowing NSTableView delegation*/, WhenLoadedable {
    internal var loadingHelper = LoadingHelper(for: FileLog.self)
    static let LOG_CACHE_KEYS_KEY = "fileLog.fileLogLastCachesKeys"
    
    typealias LineNr = UInt
    
    let DEBUG_CLEAR_CACHES_ON_INIT = IS_DEBUG && true
    let DEBUG_LOG_FIRST_LINES = IS_DEBUG && false
    let DEFAULT_BLOCK_LINES_AMOUNT = 32
    let DEFAULT_AVG_LINE_LENGTH = 32
    
    // MARK: Static vars
    private static var _allActiveLogPaths : [String] = []
    
    // MARK: Properties / Members
    let encoding : String.Encoding
    let path : String!
    let dateFormatter = DateFormatter(dateFormat: "HH:mm:ss.A") // With miliseconds
    
    public var isPrefixesWithDateTime : Bool = true
    private(set) var lastBytes : String = ""
    private let fileHandle : FileHandle!
    private let avgLineLength : AverageAccumulator!
    private let linePositions : Cache<LineNr, NSRange>!
    @AppSettable([:],   name: LOG_CACHE_KEYS_KEY) static var fileLogLastCachesKeys : [String:String]
    
    private let queue = DispatchQueue.global()
    private var isMappingLines = false
    private var _queuedLines : [String] = []
    private var _isSavingLines : Bool = false
    private var _isNeedsSave : Bool = false
    
    var isNeedsSave : Bool {
        return self._isNeedsSave || (/* todo: fix not safe...*/_queuedLines.count > 0) || avgLineLength.isNeedsSave || linePositions.isNeedsSave
    }
    
    var count : Int? {
        if self.isLoaded {
            return linePositions.count
        }
        return nil
    }
    
    var averageLineLength : Int {
        if avgLineLength.count > 20 {
            return Int(avgLineLength.average)
        }
        
        return DEFAULT_AVG_LINE_LENGTH
    }
    
    // MARK: Privare
    private static func createFileIfNeeded(path:String) {
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        }
    }
    
    private func fileSize()->UInt64 {
        var result : UInt64 = 0
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: self.path)
            result = (attrs[.size] as? UInt64) ?? 0
        } catch let error {
            dlog?.info("Get file size failed with error: \(error.localizedDescription)")
        }
        return result
    }
    
    private func curHashString()->String? {
        guard linePositions.count >= 3 else {
            return nil
        }
        let result = "[\(self.fileSize())]-[\(linePositions[1].descOrNil), \(linePositions[2].descOrNil), \(linePositions[3].descOrNil)]-<\(self.lastBytes)>"
        return result.replacingOccurrences(of: "}, ", with: ";").replacingOccurrences(ofFromTo: [", " : "-", "{": ""])
    }
    
    private func isMapCachedKeysHashEquals()->Bool {
        var result = false
        guard linePositions.count >= 3 else {
            return result
        }
        
        let key = path.lastPathComponents(count: 2)
        if let hashStr = Self.fileLogLastCachesKeys[key], let curStr = self.curHashString() {
            result = (hashStr == curStr)
        }
        
        return result
    }
    
    /// Blocking: will wait for AppSettings.shared.other[fileLog.fileLogLastCachesKeys] to load
    fileprivate func waitForSettings_LOG_CACHE_KEYS() {
        // Restore from AppSettings (we need this manually because this is a static member)
        if Self.fileLogLastCachesKeys.count == 0 {
            var counter = 0
            let maxWaitcounter = 20
            while AppSettings.shared.other.index(forKey: Self.LOG_CACHE_KEYS_KEY) == nil && counter < maxWaitcounter {
                Thread.sleep(forTimeInterval: 0.05)
                counter += 1
                dlog?.info("waiting for Settings other[\(Self.LOG_CACHE_KEYS_KEY)] cnt: \(counter)")
            }
            
            if AppSettings.shared.other.index(forKey: Self.LOG_CACHE_KEYS_KEY) == nil && counter < maxWaitcounter {
                Self.fileLogLastCachesKeys = AppSettings.shared.other[Self.LOG_CACHE_KEYS_KEY] as! [String : String]
            }
        }
    }
    
    /// Returns the line number of a give offset in bytes in side the log file. (i.e lineNumberForByteOffset()
    /// NOTE: Line numbers start at 1! NOTE: If file is empty, result will be 1.
    /// - Parameter offset: byte offset for the current log file
    /// - Returns: the UInt line number of that position in the file
    private func calcLineNr(atOffset offset: UInt64)->UInt {
        var result : UInt = 0 // default
        guard offset > 1 && linePositions.count > 0 else {
            return result
        }
        
        var found = false
        for existingLineNr in stride(from: UInt(linePositions.count), to: 0, by: -1) {
            if let pos = linePositions[existingLineNr], pos.location < offset {
                result = existingLineNr + 1
                found = true
                break
            }
        }
        if IS_DEBUG && found == false {
            dlog?.note("calcLineNr Failed to find line number at byte offset position: \(offset). File size is: \(self.fileSize()). Line posses: \(linePositions.count)")
        }
        
        return result
    }
    
    private var mappingBlockSize : Int {
        
        let avgLnLn = max(self.averageLineLength, 3)
        let fileSze = self.fileSize()
        var blockSize = 32
        switch fileSze {
        case 0:
            if avgLineLength.count > 20 {
                // Keep only the last 20 line lengths
                avgLineLength.removeFirst(avgLineLength.count - 20)
            }
        case 0...128:
            blockSize = Int(fileSze)
        case 128...UInt64.max:
            fallthrough
        default:
            blockSize = max(Int(fileSze) / (avgLnLn * 32), 128)
            blockSize = min(max(blockSize, 32), Int(fileSze))
            dlogMapping?.info("mapLines average line length: \(avgLnLn) block size: \(blockSize) Bytes")
        }
        return blockSize
    }
    
    private func mapBlock(nr:Int, fileSize:UInt64, offset offst: UInt64 = 0, blockSize blockSze:Int, prefix:String)->(bytesRead:Int, ranges:[NSRange], remainder:String)? {
        var offset = offst
        var blockSize = blockSze
        var ranges : [NSRange] = []
        var remainder : String = ""
        
        do {
            if try fileHandle.offset() != offset {
                try fileHandle.seek(toOffset: offset)
            }
            
            if offset + UInt64(blockSize) > fileSize {
                 blockSize = Int(fileSize - offset)
            }
            if let data = try fileHandle.read(upToCount: blockSize) {
                var cnt = data.count
                while cnt > 2 && offset == offst {
                    if let str = String(data:data.prefix(cnt), encoding: self.encoding) {
                        if IS_DEBUG && cnt != 0 {
                            dlogMapping?.success("mapLine (\(nr)) success casting to string at:\(offset)/\(fileSize) size:\(cnt)")
                        }
                        
                        // Cast to string succeeded:
                        var rows =  str.components(separatedBy: .newlines)
                        let isEOF = Int(offset) + cnt >= fileSize
                        
                        
                        if nr == 60 || isEOF {
                            remainder = ""
                        }
                        
                        // last line if does not end with newline will be passed to next block reader
                        if str.last?.isNewline ?? false == false && isEOF == false {
                            remainder = rows.last ?? ""
                            rows.removeLast()
                        }
                        
                        // New text lines
                        dlogMapping?.info("mapBlock [\(prefix)] [\(nr)...\(nr + rows.count)] \(isEOF ? "EOF" : "")")
                        rows.forEachIndex { index, row in
                            let byteLength = row.data(using: self.encoding)?.count ?? row.count
                            if byteLength > 0 && row.count > 0 {
                                dlogMapping?.success("mapLine (\(nr + index)) bytes: \(byteLength) [\(row)]")
                                let range = NSRange(location: Int(offset), length: byteLength)
                                ranges.append(range)
                                offset += UInt64(range.length) + 1 /* newline */
                            } else {
                                
                            }
                        }
                    } else {
                        dlogMapping?.note("mapLine (\(nr)) failed casting to string at:\(offset)/\(fileSize) size:\(blockSize)")
                        cnt -= 1
                    }
                }
            } else {
                dlog?.note("mapLine (\(nr)) failed reading data at:\(offset)/\(fileSize) size:\(blockSize)")
            }
        } catch let error {
            dlog?.note("mapLine (\(nr)) error: \(error.localizedDescription)")
        }
        
        if ranges.count > 0 && offset > offst {
            return (bytesRead:Int(offset - offst), ranges:ranges, remainder:remainder)
        }
        return nil
    }
    
    /// Map all lines in the log file that we are handling into the linePositions cache
    /// - Parameters:
    ///   - initialOffset: map should start in this initial byte offset position. (Use this when adding lines)
    ///   - completion: will return when the wole mapping of the whole file from initialOffset to end has finished
    private func mapLines(initialOffset: UInt64 = 0, completion:@escaping ()->Void) {
        guard !self.isMappingLines else {
            waitFor("mapLines.waitforPrevMapping", testOnMainThread: {
                return self.isMappingLines == false
            }) { waitResult in
                completion()
            }
            return
        }
        
        let fileSze = self.fileSize()
        guard fileSze > 0 else {
            completion()
            return
        }
        
        self.isMappingLines = true
        queue.async {[self] in
            
            // Blocking:
            waitForSettings_LOG_CACHE_KEYS()
            

            let blockSize = self.mappingBlockSize
            
            // Before clearing linePositions cache
            var lineNr : UInt = self.calcLineNr(atOffset:initialOffset)
            
            do {
                try fileHandle.seek(toOffset: initialOffset)
            } catch let error {
                dlog?.info("maplLines failed seeking to 0 offset! error: \(error.localizedDescription)")
            }
            
            var eofReached = false
            var offset : UInt64 = initialOffset
            var safeCounter = 0
            var newLinePositions : [LineNr:NSRange] = [:]
            
            dlogMapping?.info("mapLines START \(path.lastPathComponent()) block size: \(blockSize) Bytes, starting at: \(initialOffset)")
            DLog.indentStart(logger: dlogMapping)
            
            var remainder : String = ""
            while safeCounter < (fileSze / 3) && !eofReached && offset < fileSze {
                if let result = self.mapBlock(nr:newLinePositions.count + 1,
                                              fileSize: fileSze,
                                              offset:offset,
                                              blockSize:blockSize,
                                              prefix: remainder) {
                    result.ranges.forEachIndex { index, range in
                        newLinePositions[lineNr + UInt(index)] = range
                    }
                    lineNr += UInt(result.ranges.count)
                    remainder = result.remainder
                    offset += UInt64(result.bytesRead)
                    
                    if offset >= fileSze {
                        eofReached = true
                    }
                }
                
                // Safety first
                safeCounter += 1
            }

            if IS_DEBUG && safeCounter >= fileSze / 3 /**/ {
                dlog?.note("mapLines DONE safeCounter overflow - while loop issue.")
            }
            
            if eofReached {
                dlogMapping?.info("mapLines DONE reached eof: \(offset) / \(fileSze) with: \(self.count?.description ?? "<not loaded>" ) lines mapped.")
                
                if initialOffset == 0 {
                    self.linePositions.clear()
                }
                self.linePositions.add(dictionary: newLinePositions)
                
                // Save hash string
                if newLinePositions.count >= 3, let curHash = self.curHashString() {
                    let lpath = self.path.lastPathComponents(count: 2)
                    DispatchQueue.main.safeSync {
                        Self.fileLogLastCachesKeys[lpath] = curHash
                    }
                }
            }
            
            DLog.indentEnd(logger: dlogMapping)
            
            // Call completion
            dlog?.info("mapLines WRAPPING \(newLinePositions.count) new lines")
            
            DispatchQueue.main.async {
                AppSettings.shared.saveIfNeeded()
                dlog?.info("mapLines DONE (\(self.linePositions.count))")
                self.isMappingLines = false
                completion()
            }
        }
    }
    
    private func internal_appendAndSaveLines(_ linesForQ:[String]) {
        TimedEventFilter.shared.filterEvent(key: "FileLog_\(path.lastPathComponents(count: 2))_internal_appendAndSaveLines", threshold: 0.1, accumulating: linesForQ, completion: { linesez in
            if let lines = linesez?.flattened, lines.count > 0 {
                self._isNeedsSave = true
                self.queue.asyncIfNeeded {[self] in
                    do {
                        try fileHandle.seekToEnd()
                        
                        // All lines -> to string
                        let str = lines.joined(separator: "\n").appending("\n")
                        
                        // Save string
                        if str.count > lines.count, let data = str.data(using: encoding) {
                            let sze = fileSize()
                            dlog?.info("internal_appendAndSaveLines adding +\(lines.count) to \(linePositions.count) lines, \(data.count) bytes added.")
                            try fileHandle.write(contentsOf: data)
                            
                            let subData = data.subdata(in: data.endIndex.advanced(by: -4)..<data.endIndex)
                            lastBytes = self.stringForBytesHash(data: subData)
                            
                            DLog.indentStart(logger: dlog)
                            self.mapLines(initialOffset: sze) {
                                // Save helpers
                                self.avgLineLength.saveIfNeeded()
                                self.linePositions.saveIfNeeded()
                                DLog.indentEnd(logger: dlog)
                                self._isNeedsSave = false
                            }
                        } else {
                            dlog?.note("internal_appendAndSaveLines failed sizes or creting data from the lines.")
                        }
                    } catch let error {
                        dlog?.note("internal_appendAndSaveLines failed adding lines error: \(error.localizedDescription)")
                    }
                }
            } else {
                dlog?.note("internal_appendAndSaveLines accumulated lines was empty or nil")
            }
        })
    }
    
    private func addTimestampPrefix(toLine: String)->String {
        let timeStamp = dateFormatter.string(from: Date())
        return timeStamp + " " + toLine
    }
    
    private func mutateLinesIfNeeded(_ lines:[String])->[String] {
        return lines.compactMap { line in
            var result = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if result.count > 0 {
                if self.isPrefixesWithDateTime {
                    // Add timestamp prefix
                    result = self.addTimestampPrefix(toLine: result)
                }
                
                self.avgLineLength.add(amount: 1, value: result.count + 1)
                return result
            }
            return  nil
        }
    }
    
    private func internal_appendLines(_ untimedLines:[String], depth:UInt) {
        dlog?.todo("TEMP - no append lines!!")
        return // TEMP
        
        
        guard depth < 10 else {
            dlog?.note("internal_appendLines depth >= 10")
            return
        }
        
        guard untimedLines.count > 0 else {
            dlog?.note("internal_appendLines lines count is 0")
            return
        }
        
        if IS_DEBUG, untimedLines.count > 1000 {
            dlog?.note("internal_appendLines: It is reccommended to use less lines / more frequently the append operation.")
        }
        
        let lines = mutateLinesIfNeeded(untimedLines)
        
        // Wait for next save / sync
        guard !self._isSavingLines &&
              !self.isMappingLines else {
                  
            self._isNeedsSave = true
            self.queue.asyncAfter(delayFromNow: 0.07) {
                self._queuedLines.append(contentsOf: lines)
                dlog?.note("internal_appendLines will delay [depth: \(depth)]")
                let lnes = Array(self._queuedLines)
                self._queuedLines.removeAll()
                self.internal_appendLines(lnes, depth: depth + 1)
                return
            }
            return
        }
        
        // Save NOW!
        self.internal_appendAndSaveLines(lines)
    }
    
    // MARK: Public
    
    /// Append a single line to the log file
    /// NOTE: Line must be more than 0 chars long
    /// - Parameter line: line to append
    func appendLine(_ line:String) {
        guard line.count > 0 else {
            return
        }
        self.appendLines([line])
    }
    
    /// Append lines to the current log file
    /// - Parameter lines: lines to append to the log file.
    func appendLines(_ lines:[String]) {
        self.internal_appendLines(lines, depth: 0)
    }
    
    func outOfBoundsError(startingAt lineNr:LineNr, amount:UInt)->AppError? {
        var detail : String = ""
        var result : AppError? = nil
        let cnt =  linePositions.count
        if lineNr >= cnt {
            detail = "lines to read [\(lineNr)...\(lineNr + amount)] \(lineNr) out of bounds [0...\(cnt)] - min above maximum"
        } else if amount <= 0 {
            detail = "lines to read [\(lineNr)...\(lineNr + amount)] out of bounds [0..\(cnt - Int(lineNr))] - below minimum"
        } else if Int(lineNr + amount) > cnt {
            detail = "lines to read [\(lineNr)...\(lineNr + amount)] out of bounds [0..\(cnt)] - max above maximum"
        }
        
        if detail != "" {
           result = AppError(AppErrorCode.misc_failed_reading, detail: "FileLog.readLines \(detail)")
        }

        return result
    }
    
    /// Read and returns the lines in the file from line number, accumulating a total amount of "amount" lines.
    /// - Parameters:
    ///   - lineNr: line number to begin the read
    ///   - amount: amount of lines to read (inlcuding line at lineNr)
    ///   - completion: completion with the read lines or nil
    func readLines(startingAt lineNr:LineNr, amount:UInt, completion: @escaping (Result<[String], AppError>)->Void) {
        let outOfBoundsError = self.outOfBoundsError(startingAt: lineNr, amount: amount)
        guard outOfBoundsError == nil else {
            let error = outOfBoundsError!
            dlog?.note("readLines out of bounds error: \(error.desc) \((error.details?.first).descOrNil)")
            DispatchQueue.mainIfNeeded {
                completion(.failure(error))
            }
            return
        }
        
        let linesAmt = max(amount - 1, 0)
        dlogReadlines?.info("readLines: \(lineNr)...\(lineNr + linesAmt) START")
        queue.async {[self] in
            var result : [String] = []
            if let pos = self.linePositions[lineNr], let lastPos = self.linePositions[lineNr + linesAmt] {
                do {
                    dlogReadlines?.info("readLines: from pos: [\(pos.location) to \(lastPos.upperBound)]")
                    for offset in 0...1 {
                        try fileHandle.seek(toOffset: UInt64(pos.location + offset))
                        var data : Data? = nil
                        if lineNr + linesAmt >= self.linePositions.count - 2 {
                            data = try fileHandle.readToEnd()
                        } else {
                            let len = lastPos.upperBound  - pos.lowerBound
                            data = try fileHandle.read(upToCount: len)
                        }
                        
                        if let data = data {
                            if let str = String(data: data, encoding: self.encoding)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                                var lnes : [String] = str.components(separatedBy: .newlines).compactMap({ line in
                                    let result = line.trimmingPrefixCharacters(in: .whitespacesAndNewlines)
                                    return (result.count > 0) ? result : nil
                                })
                                lnes = Array(lnes.prefix(Int(amount)))
                                
                                if lnes.count == amount {
                                    result.append(contentsOf: lnes)
                                } else {
                                    dlog?.warning("Amount \(amount) != found \(lnes.count) lines")
                                }
                                break // loaded lines
                            } else {
                                if offset == 1 {
                                    dlog?.warning("readLines Failed casting data count: \(data.count) to string: [\(pos.lowerBound)...\(pos.upperBound)]")
                                    // failed loading, re-read data, with 1 byte offset
                                }
                            }
                        } else {
                            if offset == 1 {
                                dlog?.warning("readLines Failed loading data: [\(pos.lowerBound)...\(pos.upperBound)]")
                            }
                            // failed loading, re-read data, with 1 byte offset
                        }
                    }
                    
                } catch let error {
                    dlogReadlines?.note("readLines Failed seeking or reading at offset:\(pos.location). error:\(error.localizedDescription)")
                    DispatchQueue.mainIfNeeded {
                        completion(.failure(AppError(AppErrorCode.misc_failed_reading, detail: "readLines Failed seeking or reading at offset:\(pos.location).", underlyingError: error)))
                    }
                    return
                }
            } else {
                dlogReadlines?.note("readLines Failed locating pos \(lineNr) + amount \(amount) in \(linePositions.count) linePositions.")
            }
            
            // Call completion when done
            DispatchQueue.mainIfNeeded {
                if result.count == 0 {
                    let firstPos = self.linePositions[lineNr]
                    let lastPos = self.linePositions[lineNr + amount]
                    dlog?.note("readLines failed seeking: \(lineNr) [\(lineNr)...\(lineNr + amount)] | [\(firstPos.descOrNil)...\(lastPos.descOrNil)]")
                    completion(.failure(AppError(AppErrorCode.misc_failed_reading, detail: "readLines Failed seeking or reading (0 lines result).")))
                    return
                }
                else if result.count != amount {
                    
                    if !self.isMappingLines {
                        dlog?.note("readLines at lineNr: \(lineNr) found: \(result.count) lines, instead of expected: \(amount) lines. Will remap all lines!")
                        self.mapLines {
                            completion(.success(result))
                        }
                    } else if result.count < amount {
                        dlog?.note("readLines at lineNr: \(lineNr) found: \(result.count) lines, isMappingLines was true. END")
                    }
                } else {
                    dlogReadlines?.success("readLines: \(lineNr) - \(lineNr + linesAmt) END")
                    completion(.success(result))
                }
                
            }
        }
    }
    
    func saveIfNeeded() {
        guard self.isNeedsSave else {
            return
        }
        save()
    }
    
    func save() {
        guard _isSavingLines == false else {
            queue.asyncAfter(delayFromNow: 0.1) {
                if self.isNeedsSave {
                    self.saveIfNeeded()
                }
            }
            return
        }
        
        // Debugging
        if IS_DEBUG && self.isNeedsSave == false {
            dlog?.note("save() called when save is not needed!")
        }
        
        self.linePositions.saveIfNeeded()
        self.avgLineLength.saveIfNeeded()
        do {
            try self.fileHandle.synchronize()
        } catch let error {
            dlog?.info(".save failed saving. error: \(error.localizedDescription)")
        }
        self._isNeedsSave = false
        self._isSavingLines = false
    }
    
    // MARK: Lifecycle
    fileprivate func stringForBytesHash(data:Data)->String {
        return (String(data: data, encoding: encoding) ?? "").hashValue.description
    }
    
    fileprivate func extractLast4BytesHash() {
        let offset = self.fileSize()
        do {
            let amount : UInt64 = 8
            if offset > amount {
                try fileHandle.seek(toOffset: offset - amount)
                if let data = try fileHandle.readToEnd() {
                    lastBytes = self.stringForBytesHash(data: data)
                }
            } else {
                lastBytes = "".hashValue.description
            }
            
            try fileHandle.seek(toOffset: 0)
        } catch let error {
            dlog?.note("error readin last 4 bytes error: \(error.localizedDescription)")
        }
    }
    
    init(path : String, encoding : String.Encoding = .utf8) {
        
        // Init required properties
        self.encoding = encoding
        self.path = path
        self.dateFormatter.timeZone = Calendar.current.timeZone
        Self.createFileIfNeeded(path: path)
        fileHandle = FileHandle(forUpdatingAtPath: path)
        let name =  "FileLog_\(path.lastPathComponent())".replacingOccurrences(ofFromTo: [".log":""])
        linePositions = Cache<LineNr, NSRange>(name: name + "_nlPositions", maxSize: 2048, attemptLoad: false)
        avgLineLength = AverageAccumulator(named: name + "_averages", persistentInFile: true, maxSize: 4096)
        dlog?.info("init [\(path.lastPathComponent())] cached nlPositions: \(linePositions.count)")
        
        
        // Super init
        super.init()
        
        // And read last 4 bytes
        self.extractLast4BytesHash()
        
        DispatchQueue.mainIfNeeded {
            if !Self._allActiveLogPaths.contains(path) {
                Self._allActiveLogPaths.append(path)
            } else {
                dlog?.note("_allActiveLogPaths already contains active log at path [\(path)]")
            }
        }
        
        if DEBUG_CLEAR_CACHES_ON_INIT {
            Self.fileLogLastCachesKeys.removeAll()
            self.avgLineLength.clear()
            self.linePositions.clear()
        }
        
        //
        self.mapLines {
            //
        }
        
        loadingHelper.startedLoading(waitForCondition: {
            self.isMappingLines == false
        }, context: "FileLog.\(name).init", userInfo: nil) { info, result in
            dlog?.info("FileLog.\(name) loading completed. count: \(self.linePositions.count)")
            // Clear loading helper
            self.loadingHelper.callCompletionsAndClear()
            self.debugLogsAfterLoad()
        }
    }
    
    deinit {
        queue.safeSync {[self] in
            
            // Save misc items
            self.avgLineLength.saveIfNeeded()
            self.linePositions.saveIfNeeded()
            do {
                try fileHandle.synchronize()
                try fileHandle.close()
            } catch {
                
            }
            
            dlog?.info("deinit \(self) in quque")
            let apath = self.path!
            DispatchQueue.mainIfNeeded {
                Self._allActiveLogPaths.remove(elementsEqualTo: apath)
            }
        }
        dlog?.info("deinit \(self)")
    }
    
    func debugLogsAfterLoad() {
        guard DEBUG_LOG_FIRST_LINES else {
            return
        }
        
        // NOTE: Ranges are {x..<y}, i.e upperbound is NOT included
        // A half-open interval from a lower bound up to, but not including, an upper bound
        var ranges : [Range<Int>] = []
        var lineIndex : Int = 0
        var safeCount = self.fileSize()
        while lineIndex < self.linePositions.count - 1, safeCount > 0 {
            let add = min(linePositions.count - lineIndex, 19)
            ranges.append(lineIndex..<(lineIndex + add))
            lineIndex += add - 1
            safeCount -= 1 // safety for while
        }
        
        dlog?.info("debugLogsAfterLoad will log ranges:\(ranges.descriptionsJoined)")
        
        ranges.forEachIndex({ index, range in
            DispatchQueue.main.asyncAfter(delayFromNow: 0.05 * Double(index)) {
                self.readLines(startingAt: FileLog.LineNr(range.lowerBound), amount: FileLog.LineNr(range.count)) { response in
                    switch response {
                    case .failure(let error):
                        dlog?.note("failure \(error.localizedDescription)")
                    case .success(let lines):
                        // NOTE: Ranges are {x..<y}, i.e upperbound is NOT included
                        dlog?.success("loaded lines: [\(range.lowerBound)...\(range.upperBound - 1)]\n\(lines.descriptionLines)")
                    }
                }
            }
        })
    }
    
}
