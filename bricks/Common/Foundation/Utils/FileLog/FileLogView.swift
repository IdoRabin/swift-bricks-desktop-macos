//
//  FileLogView.swift
//  Bricks
//
//  Created by Ido on 29/01/2022.
//

import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("FileLogView")

protocol FileLogViewObserver : AnyObject {
    func fileLogView(_ fileLogView:FileLogView, didSelectRows:IndexSet)
}


class FileLogView: NSTableView {

    struct Line : Equatable, CustomStringConvertible {
        let row:UInt
        let stringValue:String
        
        // MARK: Equatable
        static func ==(lhs:Line, rhs:Line)->Bool {
            return lhs.row == rhs.row
        }
        
        var description: String {
            return "\(String(format: "%4d", row))  |  \(stringValue)"
        }
    }

    class Lines {
        var minRow : UInt = 0
        var maxRow : UInt = 0
        var rows : [UInt:Line] = [:]
        init (minRowIdx : UInt, maxRowIdx : UInt) {
            minRow = minRowIdx
            maxRow = maxRowIdx
        }
        static var empty : Lines {
            return Lines(minRowIdx: 0, maxRowIdx: 0)
        }
        var isEmpty : Bool {
            return rows.count == 0
        }
        
        func calcMinMax() {
            var minR : UInt = 999999
            var maxR : UInt = 0
            for (nr, _) in rows {
                minR = min(minR, nr)
                maxR = max(maxR, nr)
            }
            minRow = minR
            maxRow = maxR
        }
        
        var asString : String {
            var result : String = ""
            for row in minRow...maxRow {
                if let line = self.rows[row], line.stringValue.count > 0 {
                    if result != "" {
                        result += "\n"
                    }
                    result += line.description
                }
            }
            
            dlog?.info("asString: \(result)")
            return result
        }
    }
    
    typealias TextChunkIndex = UInt
    
    // MARK: Const
    private let LINES_MIN_CHUNK_SIZE = (Debug.IS_DEBUG ? 16 :  512)
    
    // MARK: Static
    
    // MARK: Properties / members
    var observers = ObserversArray<FileLogViewObserver>()
    private (set) var chunkSize : Int = 16
    private (set) var lines : [TextChunkIndex:Lines] = [:]
    var cellFont : NSFont = NSFont.monospacedDigitSystemFont(ofSize: 14.0, weight: .regular) {
        didSet {
            self.reloadData()
        }
    }
    private (set) var lineNrFormatStr = "%5d"
    
    // MARK: Private
    private func validated()->Bool {
        if self.dataSource !== self {
            dlog?.warning("must have self as datasource")
            return false
        }
        if self.delegate !== self {
            dlog?.warning("must have self as delegate")
            return false
        }
        return true
    }
    
    private func calcLinesShown() {
        DispatchQueue.mainIfNeeded {
            let ttleAndFooter : CGFloat = 44.0
            
            var hgt = self.frame.height - ttleAndFooter
            if let scroll = self.superviewWhichMatches({ view in
                view is NSScrollView
            }) {
                hgt = scroll.frame.height - ttleAndFooter
            }
            let font = self.font ?? NSFont.systemFont(ofSize: 14)
            let lineHeight = ceil(font.ascender - font.descender) +   /* line spacing: */(font.xHeight * 0.6)
            let newCapacity = UInt(max(floor(hgt / lineHeight) * 1.1 /* extra few lines */, CGFloat(self.LINES_MIN_CHUNK_SIZE)))
            
            self.chunkSize = max(Int(newCapacity), self.LINES_MIN_CHUNK_SIZE)
            
            // Calc the specific lines shown, and the text chunks needed:
            let lineRange = self.rows(in: self.enclosingScrollView?.documentVisibleRect ?? CGRect.zero)
            let minLineIndex = UInt(lineRange.lowerBound)
            let maxLineIndex = UInt(lineRange.upperBound)
            let minChunk = self.chunkIndex(for: minLineIndex)
            let maxChunk = self.chunkIndex(for: maxLineIndex)
            // dlog?.info("calcLinesShown: \(minLineIndex)...\(maxLineIndex) chunkSize: \(newCapacity) lines minChunk:\(minChunk) maxChunk:\(maxChunk)")
            self.curChunkIndexes = [minChunk, maxChunk].uniqueElements().sorted()
        }
    }
    
    private func setupScrollView() {
        self.enclosingScrollView?.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(contentViewDidChangeBounds), name: NSView.boundsDidChangeNotification, object: self.enclosingScrollView?.contentView)
    }

    @objc
    func contentViewDidChangeBounds(_ notification: Notification) {
        guard let _ = self.enclosingScrollView?.documentView else { return }

        if let _ = self.enclosingScrollView?.contentView {
            // var pos = "middle"
            // if clipView.bounds.origin.y <= 0 {
            //     pos = "top"
            // } else if clipView.bounds.origin.y + clipView.bounds.height >= documentView.bounds.height {
            //     pos = "bottom"
            // }
            self.calcLinesShown()
        }
    }
    
    private var _lastLoadedChunkIndex : [TextChunkIndex] = []
    private var _curChunkIndexes : [TextChunkIndex] = []
    private(set) var curChunkIndexes : [TextChunkIndex] {
        get {
            return _curChunkIndexes
        }
        set {
            if _curChunkIndexes != newValue {
                _curChunkIndexes = newValue
                loadLinesShown()
            }
        }
    }
    
    var maxChunkIndex :UInt {
        return UInt(floor(Float(self.fileLog?.count ?? 0) / max(Float(self.chunkSize), 1.0)))
    }
    
    private func loadChunkIfNeeded(chunkIndex:UInt, completion:@escaping (Bool)->Void) {
        
        let lnes = self.lines[chunkIndex]
        guard let fileLog = self.fileLog, lnes == nil else {
            // if Debug.IS_DEBUG, let lnes = lnes {
            //    dlog?.note("loadLinesShown was already loaded [chunk: \(chunkIndex) lines: [\(lnes.minRow)...\(lnes.maxRow)]")
            // }
            completion(false)
            return
        }
        
        // Load cur chunk
        let minLineNr : UInt = UInt(self.chunkSize) * chunkIndex
        let maxPossibleLine = UInt(max((fileLog.count ?? 0), 0))
        let maxLineNr : UInt = min(UInt(self.chunkSize) * (chunkIndex + 1), maxPossibleLine)
        let chunkSze = maxLineNr - minLineNr
        fileLog.readLines(startingAt: minLineNr , amount: chunkSze) { result in
            switch result {
            case .failure(let error):
                dlog?.warning("loadLinesShown [\(minLineNr)...\(maxLineNr)] error: \(error.description)")
                break
            case .success(let linez):
                let updLines = self.lines[chunkIndex] ?? Lines(minRowIdx: minLineNr, maxRowIdx: minLineNr + chunkSze)
                linez.forEachIndex { index, lineStr in
                    let rowIdx = minLineNr + FileLog.LineNr(index)
                    updLines.rows[rowIdx] = Line(row:rowIdx , stringValue: lineStr)
                }
                updLines.calcMinMax() // update min max indexes using the rows it contains
                self.lines[chunkIndex] = updLines
                dlog?.info("readLines for chunkIdx: \(chunkIndex) [\(minLineNr)...\(maxLineNr)] | [\(updLines.minRow)...\(updLines.maxRow)] \(updLines.rows.count)")
                
                // Save last loaded chunk index
                self._lastLoadedChunkIndex.append(chunkIndex)
            }
            completion(true)
        }
    }
    
    private func loadLinesShown() {
        guard let _ /*fileLog*/ = self.fileLog else {
            lines.removeAll()
            return
        }
              
        var wasChanged = false
        var loadingChunks : Int = 0
        var digits : Int = 4
        let chunkSze = UInt(self.chunkSize + 4)
        // dlog?.info("loadLinesShown in chunk Nrs: \(self.curChunkIndexes.descriptionsJoined)")
        
        func finalExec() {
            if wasChanged && loadingChunks <= 0 {
                DispatchQueue.mainIfNeeded {
                    self.reloadData()
                }
                wasChanged = false
            }
        }
        
        for idx in self.curChunkIndexes {
            // Calc maximum line number format string:
            let minLineNr = UInt(max(Int(idx) * self.chunkSize, 0))
            digits = max(digits, Int(log(Double(minLineNr + chunkSze))) - 1)
            
            // Load lines for this chunk
            loadingChunks += 1
            self.loadChunkIfNeeded(chunkIndex: idx, completion: {(didNeed) in
                if didNeed {
                    dlog?.info("loaded chunk [\(idx)] in chunks:\(self.curChunkIndexes.descriptionsJoined)")
                    wasChanged = true
                }
                loadingChunks -= 1
                finalExec()
            })
        }
        
        // Update line number format string:
        self.lineNrFormatStr = "%\(digits)d"
        
        // Clear prev cached chunk/s
        while  _lastLoadedChunkIndex.count > 10 || lines.count > 10 {
            let removedChunkIdx = _lastLoadedChunkIndex.remove(at: 0)
            lines[removedChunkIdx] = nil
            _lastLoadedChunkIndex = _lastLoadedChunkIndex.intersection(with: lines.keysArray)
            // dlog?.info("removing chunk [\(removedChunkIdx)] - total chunks loaded: \(lines.count) | \(_lastLoadedChunkIndex.count)")
            wasChanged = true
        }
        
        if wasChanged && loadingChunks == 0 {
            finalExec()
        }
    }
    
    // MARK: Lifecycle
    private func setup() {
        DispatchQueue.main.performOncePerInstance(self) {
            self.setupScrollView()
            self.cellFont = NSFont(name: "SF Mono", size: 14.0) ?? NSFont.monospacedSystemFont(ofSize: 14.0, weight: .medium)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    // MARK: Public
    func chunkIndex(for rowIndex:UInt)->UInt {
        let chunkNr = floor(Float(rowIndex) / max(Float(self.chunkSize), 1.0))
        return UInt(clamp(value: chunkNr, lowerlimit: 0.0, upperlimit: Float(self.maxChunkIndex)))
    }
    
    weak var fileLog : FileLog? = nil {
        didSet {
            if let _ = fileLog {
                self.dataSource = self
                self.delegate = self
            }
            self.calcLinesShown()
            self.loadLinesShown()
        }
    }
    
    // MARK: Overrides
    override var frame: NSRect {
        didSet {
            self.calcLinesShown()
        }
    }
    
    func selectedLines()->Lines? {
        let sortedArr = self.selectedRowIndexes.sorted()
        guard sortedArr.count > 0 else {
            return nil
        }
        
        var result : Lines? = nil
        if let minRow = sortedArr.min(), let maxRow = sortedArr.max() {
            let minR = UInt(minRow)
            let maxR = UInt(maxRow)
            result = Lines(minRowIdx: minR, maxRowIdx: maxR)
            let minChunk = self.chunkIndex(for: minR)
            let maxChunk = self.chunkIndex(for: maxR)
            var chunksToLoad = Int(max(maxChunk - minChunk , 1))
            for chunk in minChunk...maxChunk {
                self.loadChunkIfNeeded(chunkIndex: chunk) { loaded in
                    chunksToLoad -= 1
                    // When last chunk is loaded:
                    if chunksToLoad <= 0 {
                        for row in minR...maxR {
                            let achunk = self.chunkIndex(for: row)
                            if let aline = self.lines[achunk]?.rows[row] {
                                result?.rows[row] = aline
                            }
                        }
                    }
                }
            }
        }
        
        return result
    }
}
