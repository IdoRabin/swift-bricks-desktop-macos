//
//  Logger.swift
//  testSwift
//
//  Created by Ido Rabin for Sync.AI on 30/10/2017.
//  Copyright © 2017 Ido Rabin. All rights reserved.
//

import Foundation

fileprivate enum DLogLevel {
    case info
    case success
    case fail
    case note
    case warning
    case todo
    case raisePrecondition
}

typealias DLogKeys = Array<String>
typealias DLogFilterSet = Set<String>

extension Array where Element : Equatable {
    
    func uniqueElements()->[Element]{
        var result : [Element] = []
        for item in self {
            if result.contains(item) == false {
                result.append(item)
            }
        }
        return result
    }
}

class DSLogger {
    
    // MARK: types
    typealias Completion = (_ didOccur:Bool)->(Void)
    typealias ExpectedItem = (string:String, step:Int, completion: Completion?)
    
    // Mark: Testing static members
    private static let MAX_CACHE_SIZE = 32
    private static let MAX_EXPECT_WAIT = 32
    private static var expectStepCounter : Int = 0
    private static var stringsToExpect: [ExpectedItem] = []
    private static var filterOut:DLogFilterSet = [] // When empty, all logs are output, otherwise, keys that are included are logged out
    private static var filterIn:DLogFilterSet = [] // When empty, all logs are output, otherwise, keys that are included are the only ones output - this takes precedence over filterOut
    private static var alwaysPrinted:[DLogLevel] = [.warning, .fail, .raisePrecondition, .note] // Will allow printing even when filtered out using filter
    
    // MARK: Private date stamp
    private static let dateFormatter = DateFormatter()
    private let keys:DLogKeys
    
    private var _indentLevel : Int = 0
    private var indentLevel : Int {
        get {
            return _indentLevel
        }
        set {
            _indentLevel = min(max(newValue, 0), 16)
        }
    }
    
    // MARK: Testing
    init(keys:DLogKeys) {
        DSLogger.dateFormatter.dateFormat = "HH:mm:ss.SSS"
        self.keys = keys.uniqueElements()
    }
    
    /// Add log (string) keys into the filter, only these keys will be logged from now on
    ///
    /// - Parameter keys: keys to filter (only these will be printed into log, unless in .alwaysPrinted array)
    public static func filterOnlyKeys(_ keys:DLogKeys) {
        filterIn.formUnion(keys)
    }
    
    /// Remove log (string) keys from the filter, these keys will not be able to log from now on
    ///
    /// - Parameter keys: keys to unfilter (will note be printed into log)
    public static func unfilterOnlyKeys(_ keys:DLogKeys) {
        filterIn.subtract(keys)
    }
    
    /// Add log (string) keys into the filter, these keys will not be logged from now on
    ///
    /// - Parameter keys: keys to filter (will not be printed into log, unless in .alwaysPrinted array
    public static func filterOutKeys(_ keys:DLogKeys) {
        filterOut.formUnion(keys)
    }
    
    /// Remove log (string) keys from the filter, these keys will be able to log from now on
    ///
    /// - Parameter keys: keys to unfilter (will be printed into log)
    public static func unfilterOutKeys(_ keys:DLogKeys) {
        filterOut.subtract(keys)
    }
    
    /// Supress log calls containing the given string for the near future log calls
    ///
    /// The function saves the string to expect for MAX_CACHE_SIZE_CALLS.
    /// The function is used to catch future logs
    /// If during these series of calls the string expected did occur, the logging will be surpressed (ignored)
    /// - Parameter containedString: the string for the logging mechanism to ignore in the next x expected log calls
    public func testingIgnore(containedString:String) {
        #if TESTING
            // Add new completion to see if it will be called in the future
            DSLogger.stringsToExpect.append((string: containedString, step:DSLogger.expectStepCounter, completion:nil))
            
            if (DSLogger.stringsToExpect.count > DSLogger.MAX_CACHE_SIZE) {
                // Pop oldest completion as failed
                let older = DSLogger.stringsToExpect.remove(at: 0)
                if let acompletion = older.completion {
                    acompletion(false)
                }
            }
        #endif
    }
    
    /// The function will call a given completion block when the specified string is logged
    ///
    /// The function saves the string to expect for MAX_CACHE_SIZE_CALLS.
    /// The function is used to catch future logs
    /// If during these series of calls the string expected did occur, will call the completionBlock with true and will surpress the original log
    /// If during these series of calls the string expected did not occur, will call the completionBlock with false
    /// - Parameters:
    ///   - containedString: the string to look for in future log calls
    ///   - completion: the completion block to call when the string is encountered in a log call
    public func testingExpect(containedString:String, completion: @escaping Completion) {
        #if TESTING
            // Add new completion to see if it will be called in the future
            DSLogger.stringsToExpect.append((string: containedString, step:DSLogger.expectStepCounter, completion:completion))
            
            if (DSLogger.stringsToExpect.count > DSLogger.MAX_CACHE_SIZE) {
                // Pop oldest completion as failed
                let older = DSLogger.stringsToExpect.remove(at: 0)
                if let acompletion = older.completion {
                    acompletion(false)
                }
            }
        #endif
    }
    
    /// Clears all future loggin testing expectations without logging or calling expecation completions
    /// The function is used to catch future logs
    public func clearTestingExpectations() {
        DSLogger.expectStepCounter = 0
        DSLogger.stringsToExpect.removeAll()
    }
    
    private func isShouldPrintLog(level: DLogLevel)->Bool {
        
        // Will always allow log for items of the given levels
        if DSLogger.alwaysPrinted.contains(level) {
            return true
        }
        
        // Will fiter items based on their existance in the filter
        // When the filter is empty, will log all items
        if DSLogger.filterIn.count > 0 {
            // When our log message has a key in common with filterIn, it should log
            return DSLogger.filterIn.intersection(self.keys).count > 0
        } else if DSLogger.filterOut.count > 0 {
            // When our log message has a key in common with filterOut, it should NOT log
            return DSLogger.filterOut.intersection(self.keys).count == 0
        } else {
            return true
        }
        
        // Will not log this line
        // WILL NEVER BE EXECUTED // return false
    }
    
    /// Determine if a log is to be printed out or surpressed, passed to the testing expect system
    /// For private use (internal to this class)
    private func isShouldSurpressLog(level: DLogLevel, string:String)->Bool {
        var result = false
        
        #if TESTING
            let stringsToExpect = DSLogger.stringsToExpect
            if (stringsToExpect.count > 0) {
                // Search if any expected srting is part of the given log string
                var foundIndex : Int? = nil
                var itemsToFail:[Int] = []
                
                for (index, item) in stringsToExpect.enumerated() {
                    if string.contains(item.string) {
                        // Found an expected string contained in the given log
                        foundIndex = index
                    }
                    
                    if (DSLogger.expectStepCounter - item.step > DSLogger.MAX_EXPECT_WAIT) {
                        itemsToFail.append(index)
                    }
                }
                
                if let index = foundIndex {
                    // We remove the expected string from the waiting list
                    let item = DSLogger.stringsToExpect.remove(at: index)
                    
                    // We call the expected string with a completion
                    if let acompletion = item.completion {
                        acompletion(true)
                    }
                    
                    result = true
                }
                
                for index in itemsToFail {
                    // We remove the expected string from the waiting list
                    let item = DSLogger.stringsToExpect.remove(at: index)
                    
                    // We call the expected string with a completion
                    if let acompletion = item.completion {
                        acompletion(false)
                    }
                }
            }
            
            DSLogger.expectStepCounter += 1
        #endif
        
        // Print w/ filter
        if self.isShouldPrintLog(level: level) == false {
            result = true
        }
        
        return result // wehn not testing, should not supress log?
    }
    
    // MARK: Private
    
    private func logLineHeader()->String {
        let indentStr = String(repeating: "  ", count: indentLevel)
        return DSLogger.dateFormatter.string(from: Date()) + " | [" + self.keys.joined(separator: ".") + "] " + indentStr
    }
    
    private func println(_ str: String) {
        
        let arr : [String] = str.split(separator: "\n").map(String.init)
        for s in arr {
            //NSLog(s)
            print(logLineHeader() + s.trimmingCharacters(in: ["\""]))
        }
    }
    
    private func debugPrintln(_ str: String)  {
        let arr : [String] = str.split(separator: "\n").map(String.init)
        for s in arr {
            //NSLog(s)
            print(logLineHeader() + s.trimmingCharacters(in: ["\""]))
        }
    }
    
    private func stringFromAny(_ value:Any?) -> String {
        
        if let nonNil = value, !(nonNil is NSNull) {
            
            return String(describing: nonNil)
        }
        
        return ""
    }
    
    /// Log items as an informative log call
    ///
    /// - Parameters:
    ///   - items: Items to log
    ///   - indent: indent level (default 0)
    public func info(_ items: String, indent: Int = 0) {
        if (!isShouldSurpressLog(level:.info, string: items)) {
            debugPrintln(String(repeating: " ", count: indent) + items)
        }
    }
    
    /// Log items as a "success" log call. Will prefix a checkmark (✔) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func success(_ items: String) {
        if (!isShouldSurpressLog(level:.success, string: items)) {
            debugPrintln("✔ \(items)")
        }
    }
    
    /// Log items as a "fail" log call. Will prefix a red x mark (✘) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func fail(_ items: String) {
        if (!isShouldSurpressLog(level:.fail, string: items)) {
            debugPrintln("✘ \(items)")
        }
    }
    
    public func successOrFail(condition:Bool, items: String) {
        if condition && (!isShouldSurpressLog(level:.fail, string: items)) {
            debugPrintln("✔ \(items)")
        } else {
            debugPrintln("✘ \(items)")
        }
    }
    
    /// Log items as a "note" log call. Will prefix an orange warning sign (⚠️️) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func note(_ items: String) {
        if (!isShouldSurpressLog(level:.note, string: items)) {
            debugPrintln("⚠️️ \(items)")
        }
    }
    
    /// Log items as a "todo" log call. Will prefix with a TODO: (👁 TODO:) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func todo(_ items: String) {
        if (!isShouldSurpressLog(level:.note, string: items)) {
            debugPrintln("👁 TODO: \(items)")
        }
    }

    /// Log items as a "warning" log call. Will prefix a red exclemation mark (❗) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func warning(_ items: String) {
        if (!isShouldSurpressLog(level:.warning, string: items)) {
            println("❗ \(items)")
        }
    }
    
    /// Log items as a "raisePreconditionFailure" log call. Will prefix a big red X mark (❌) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func raisePreconditionFailure(_ items: String) {
        if (!isShouldSurpressLog(level:.raisePrecondition , string: items)) {
            println("❌ \(items)")
            preconditionFailure("DLog.fatal: \(items)")
        }
    }
    
    public func raiseAssertFailure(_ items: String) {
        if (!isShouldSurpressLog(level:.raisePrecondition , string: items)) {
            println("❌ \(items)")
            assertionFailure("DLog.fatal: \(items)")
        }
    }
    
    // MARK: Indents
    func indentedBlock(_ block:()->Void) {
        self.indentLevel += 1
        block()
        self.indentLevel -= 1
    }
    func indentStart() {
        self.indentLevel += 1
    }
    func indentEnd() {
        self.indentLevel -= 1
    }
}

/// Logger utility for swift
enum DLog : String {
    
    // Basic activity
    case appDelegate = "appDelegate"
    case docHistory = "docHistory"
    case db = "db"
    case misc = "misc"
    case drawing = "drawingBoard"
    case ui = "ui"
    case document = "document"
    case brick  = "brick" // push notification / messaging
    case splash = "splash"
    case settings = "settings"
    case menu = "menu"
    case util = "util"
    case analyzer = "analyzer"
    case vcs = "vcs"
    
    // Testing
    case testing = "testing"
    
    // MARK: Public logging functions
    private static var instances : [String:DSLogger] = [:]
    
    static private func instance(keys : DLogKeys)->DSLogger {
        let key = keys.joined(separator: ".")
        if let instance = DLog.instances[key] {
            return instance
        } else {
            let instance = DSLogger(keys: keys)
            DLog.instances[key] = instance
            return instance
        }
    }
    
    static private func instance(key : String) -> DSLogger? {
        return DLog.instance(keys: [key])
    }
    
    subscript(key : String) -> DSLogger? {
        get {
            return self[[self.rawValue, key]]
        }
    }
    
    subscript(key : DLog) -> DSLogger? {
        get {
            return self[[self.rawValue, key.rawValue]]
        }
    }
    
    subscript(keys : [DLog]) -> DSLogger? {
        get {
            var arr : DLogKeys = [self.rawValue]
            for key in keys {
                arr.append(key.rawValue)
            }
            return self[arr]
        }
    }
    
    subscript(keys : DLogKeys) -> DSLogger? {
        get {
            var arr : DLogKeys = [self.rawValue]
            arr.append(contentsOf: keys)
            return DLog.instance(keys: arr)
        }
    }
    
    subscript(keys : DLog...) -> DSLogger? {
        get {
            var arr : DLogKeys = [self.rawValue]
            for key in keys {
                arr.append(key.rawValue)
            }
            return self[arr]
        }
    }
    
    subscript(keys : String...) -> DSLogger? {
        get {
            var keyz = Array(keys)
            keyz.append(self.rawValue)
            return DLog.instance(keys: keyz)
        }
    }
    
    public func info(_ items: String, indent: Int = 0) {
        self[self.rawValue]?.info(items, indent: indent)
    }
    
    public func success(_ items: String) {
        self[self.rawValue]?.success(items)
    }
    
    public func fail(_ items: String) {
        self[self.rawValue]?.fail(items)
    }
    
    public func note(_ items: String) {
        self[self.rawValue]?.note(items)
    }
    
    public func todo(_ items: String) {
        self[self.rawValue]?.todo(items)
    }
    
    /// Log items as a "warning" log call. Will prefix a red exclemation mark (❗) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func warning(_ items: String) {
        self[[self.rawValue]]?.warning(items)
    }
    
    /// Log items as a "raisePreconditionFailure" log call. Will prefix a big red X mark (❌) before the logged string.
    ///
    /// - Parameter items: Items to log
    public func raisePreconditionFailure(_ items: String) {
        self[self.rawValue]?.raisePreconditionFailure(items)
    }
    
    public static func info(_ items: String, indent: Int = 0) {
        DLog.instance(key:"*")?.info(items, indent: indent)
    }
    
    public static func success(_ items: String) {
        DLog.instance(key:"*")?.success(items)
    }
    
    public static func fail(_ items: String) {
        DLog.instance(key:"*")?.fail(items)
    }
    
    public static func note(_ items: String) {
        DLog.instance(key:"*")?.note(items)
    }
    
    public static func todo(_ items: String) {
        DLog.instance(key:"*")?.note(items)
    }
    
    public static func warning(_ items: String) {
        DLog.instance(key:"*")?.warning(items)
    }
    
    public static func raisePreconditionFailure(_ items: String) {
        DLog.instance(key:"*")?.raisePreconditionFailure(items)
    }
    
    public static func filterKeys(_ keys:DLogKeys) {
        DSLogger.filterOutKeys(keys)
    }
    
    public static func unfilterKeys(_ keys:DLogKeys) {
        DSLogger.unfilterOutKeys(keys)
    }
    
    public static func forClass(_ name:String)->DSLogger? {
        return DLog.instance(key: name)
    }
    
    public static func forKeys(_ keys:String...)->DSLogger? {
        let keyz = DLogKeys(keys)
        return DLog.instance(keys: keyz)
    }
}
