//
//  Cache.swift
//  swiftsync
//
//  Created by Ido on 04/02/2021.
//  Copyright © 2019 . All rights reserved.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("Cache")

typealias CodableHashable = Codable & Hashable
typealias AnyCodableHashable = AnyObject & Codable & Hashable

/// Cache observer protocol - called when a cache changes
protocol CacheObserver {
    
    
    /// Notification when an item in the cache has beein updated / added
    /// - Parameters:
    ///   - uniqueCacheName: unique name of the cache
    ///   - key: cahing key for the given item
    ///   - value: item that was updated / added
    func cachItemUpdated(uniqueCacheName:String, key:Any, value:Any)
    
    
    /// Notification when the whole cache was cleared
    /// - Parameter uniqueCacheName: unique name of the cache
    func cachWasCleared(uniqueCacheName:String)
    func cachItemsWereRemoved(uniqueCacheName:String, keys:[Any])
}

typealias AnyCache = Cache<AnyHashable, AnyHashable>
class Cache<Key : Hashable, Value : Hashable> {
    
    struct ValueInfo : Hashable {
        let value:Value
        let date:Date?
    }
    
    private var _lock = NSRecursiveLock()
    private var _maxSize : UInt = 10
    private var _flushToSize : UInt? = nil
    private var _items : [Key:ValueInfo] = [:]
    private var _latestKeys : [Key] = []
    private var _lastSaveTime : Date? = nil
    private var _isNeedsSave : Bool = false
    private var _isMemoryCacheOnly : Bool = false
    private var _oldestItemsDates : [Date] = []
    private var _isFlushItemsOlderThan : TimeInterval? = Date.SECONDS_IN_A_MONTH
    public var _isSavesDates : Bool = false
    // const
    private let _maxOldestDates : UInt = 200
    
    public var name : String = ""
    public var isLog : Bool = false
    public var observers = ObserversArray<CacheObserver>()
    public var isSavesDates : Bool {
        get {
            return _isSavesDates
        }
        set {
            if newValue != _isSavesDates {
                _isSavesDates = newValue
                self.flushToDatesIfNeeded()
                self.isNeedsSave = true
            }
        }
    }
    public var isFlushItemsOlderThan : TimeInterval? {
        get {
            return _isFlushItemsOlderThan
        }
        set {
            if newValue != _isFlushItemsOlderThan {
                _isFlushItemsOlderThan = newValue
                self.flushToDatesIfNeeded()
                self.isNeedsSave = true
            }
        }
    }
    
    func log(_ string:String) {
        if isLog && IS_DEBUG {
            dlog?.info("[\(name)] \(string)")
        }
    }
    
    var maxSize : UInt {
        get {
            return _maxSize
        }
        set {
            if maxSize != newValue {
                self._maxSize = newValue
                if let flushToSize = self._flushToSize {
                    self._flushToSize = min(flushToSize, max(self.maxSize - 1, 0))
                }
                self.flushIfNeeded()
            }
        }
    }
    
    var count : Int {
        get {
            var result = 0
            self._lock.lock {
                result = self._items.count
            }
            return result
        }
    }
    
    var isMemoryCacheOnly : Bool {
        get {
            return _isMemoryCacheOnly
        }
        set {
            _isMemoryCacheOnly = newValue
        }
    }
    
    var isNeedsSave : Bool {
        get {
            return _isNeedsSave
        }
        set {
            if _isNeedsSave != newValue {
                _isNeedsSave = newValue
                if newValue {
                    self.needsSaveWasSetEvent()
                }
            }
        }
    }
    
    var lastSaveTime : Date? {
        get {
            return _lastSaveTime
        }
        set {
            if _lastSaveTime != newValue {
                _lastSaveTime = newValue
                if let date = _lastSaveTime, IS_DEBUG {
                    let interval = fabs(date.timeIntervalSinceNow)
                    switch interval {
                    case 0.0..<0.1:
                        dlog?.warning("Cache [\(self.name)] was saved multiple times in the last 0.1 sec.")
                    case 0.1..<0.2:
                        dlog?.note("Cache [\(self.name)] was saved multiple times in the last 0.2 sec.")
                    case 0.2..<0.99:
                        dlog?.note("Cache [\(self.name)] was saved multiple times in the last 1.0 sec.")
                    default:
                        break
                    }
                }
            }
        }
    }
    
    /// Initialize a Cache of elements with given kes and values with a unique name, max size and flusToSize
    /// - Parameters:
    ///   - name: unique name - this will be used for loggin and saving / loading to files. Use one unique name for each cached file. Having two instances at the same time with the same unique name may create issues. Having two instanced with the same unique name but other types for keys anfd values will for sure create undefined crashes and clashes.
    ///   - maxSize: maximum size for the cache (amount of items). Beyond this size, oldest entered items will be popped, and newwest pushed into the cache.
    ///   - flushToSize: nil or some value. When nil, the cache will pop as many items as required to remain at the maxSize level. When defined, once the caceh hits or surpasses maxSize capaity, te cache will flust and keep only the latest flushToSize elements, popping the remaining elements. flushToSize must be smaller than maxSize by at least one.
    init(name:String, maxSize:UInt, flushToSize:UInt? = 0) {
        self.name = name
        self._maxSize = max(maxSize, 1)
        if let flushToSize = flushToSize {
            self._flushToSize = min(max(flushToSize, 0), self._maxSize)
        }
        CachesHelper.shared.observers.add(observer: self)
    }
    
    deinit {
        observers.clear()
        CachesHelper.shared.observers.remove(observer: self)
    }
    
    fileprivate func needsSaveWasSetEvent() {
        // Override point
    }
    
    private func validate() {
        self._lock.lock {
            // Debug validations
            for key in self._latestKeys {
                if self._items[key] == nil {
                    dlog?.warning("[\(name)] flushed (cur count:\(self._items.count)) but no item found for \(key)")
                }
            }
            for (key, _) in self._items {
                if !_latestKeys.contains(key) {
                    dlog?.warning("[\(name)] flushed (cur count:\(self._items.count)) but key \(key) is missing in latest")
                }
            }
            
            if _items.count != self._latestKeys.count {
                dlog?.warning("[\(name)] flushed (cur count:\(self._items.count)) and some items / keys are missing")
            }
        }
    }
    
    fileprivate func flushToSizesIfNeeded() {
        self._lock.lock {
            if self._latestKeys.count > maxSize {
                let overhead = self._latestKeys.count - Int(self._flushToSize ?? self.maxSize)
                if overhead > 0 {
                    let keys = Array(self._latestKeys.prefix(overhead))
                    let dates = self._items.compactMap { (info) -> Date? in
                        return info.value.date
                    }
                    self._items.remove(valuesForKeys: keys)
                    
                    let remainingKeys = Array(self._items.keys)
                    self._latestKeys.remove { (key) -> Bool in
                        !remainingKeys.contains(key)
                    }

                    // NOTE: We are assuming only one item has this exact date,
                    self._oldestItemsDates.remove(objects: dates)
                    
                    if IS_DEBUG {
                        self.validate()
                    }
                    self.log("Flushed to size \(_latestKeys.count) items:\(self._items.count)")
                    self.isNeedsSave = true
                    
                    // Notify observers
                    observers.enumerateOnMainThread { (observer) in
                        observer.cachItemsWereRemoved(uniqueCacheName:self.name, keys: keys)
                    }
                }
            }
        }
    }
    
    fileprivate func flushToDatesIfNeeded() {
        guard self.isSavesDates else {
            return
        }
        
        guard self.isSavesDates else {
            return
        }
        
        guard let olderThanSeconds = self._isFlushItemsOlderThan else {
            return
        }
        
        // Will  not flush all the time
        TimedEventFilter.shared.filterEvent(key: "Cache_\(name)_flushToDatesIfNeeded", threshold: 0.2) {
            let clearedCount = self.clear(olderThan: olderThanSeconds)
            dlog?.info("[\(self.name)] flushToDatesIfNeeded: cleared \(clearedCount) items older than: \(olderThanSeconds) sec. ago. \(self.count) remaining.")
        }
    }
    
    private func flushIfNeeded() {
        self.flushToSizesIfNeeded()
        self.flushToDatesIfNeeded()
    }
    
    subscript (key:Key) -> Value? {
        get {
            return self.value(forKey: key)
        }
        set {
            if let value = newValue {
                self.add(key: key, value: value)
            } else {
                self.remove(key:key)
            }
        }
    }
    
    var keys : [Key] {
        get {
            var result : [Key] = []
            self._lock.lock {
                result = Array(self._items.keys)
            }
            return result
        }
    }
    
    private func addToOldestItemsDates(_ date:Date) {
        self._oldestItemsDates.append(date)
        if self._oldestItemsDates.count > self._maxOldestDates {
            self._oldestItemsDates.remove(at: 0)
        }
    }
    
    var values : [Value] {
        get {
            var result : [Value] = []
            self._lock.lock {
                result = Array(self._items.values).map({ (info) -> Value in
                    return info.value
                })
            }
            return result
        }
    }
    
    func values(forKeys keys:[Key])->[Key:Value] {
        var result : [Key:Value] = [:]
        self._lock.lock {
            for key in keys {
                if let val = self._items[key]?.value {
                    result[key] = val
                }
            }
        }
        
        return result
    }
    
    func value(forKey key:Key)->Value? {
        return self.values(forKeys: [key]).values.first
    }
    
    func hasValue(forKey key:Key)->Bool {
        return self.value(forKey: key) != nil
    }
    
    func remove(key:Key) {
        var wasRemoved = false
        self._lock.lock {
            wasRemoved = (self._items[key] != nil) // existed to begin with
            
            if let date = self._items[key]?.date {
                // NOTE: We are assuming only one item has this exact date,
                self._oldestItemsDates.remove(elementsEqualTo: date)
            }
            
            self._items[key] = nil
            self._latestKeys.remove(elementsEqualTo: key)
            self.log("Removed \(key). count:\(self.count)")
        }
        
        // Notify observers
        if wasRemoved {
            self.isNeedsSave = true
            observers.enumerateOnMainThread { (observer) in
                observer.cachItemsWereRemoved(uniqueCacheName:self.name, keys: [key])
            }
        }
    }
    
    func add(key:Key, value:Value) {
        self._lock.lock {
            self.flushIfNeeded()
            let date = self.isSavesDates ? Date() : nil
            self._items[key] = ValueInfo(value:value, date:date)
            self._latestKeys.append(key)
            self.log("Added \(key). count:\(self.count)")
            self.isNeedsSave = true
        }
        
        // Notify observers
        observers.enumerateOnMainThread { (observer) in
            observer.cachItemUpdated(uniqueCacheName:self.name, key: key, value: value)
        }
    }
    
    func clearMemory(but exceptKeys: [Key]? = nil) {
        self._lock.lock {
            if exceptKeys?.count ?? 0 == 0 {
                self._items.removeAll()
                self._latestKeys.removeAll()
                self.log("Memory Cleared all. count:\(self.count)")
            } else if let exceptKeys = exceptKeys {
                self._items.removeAll(but:exceptKeys)
                self._latestKeys.remove { (key) -> Bool in
                    return exceptKeys.contains(key)
                }
                self.log("Memory Cleared all but: \(exceptKeys.count) keys. count:\(self.count)")
            }
        }
    }
    
    func clearForMemoryWarning() {
        dlog?.info("clearForMemoryWarning 1")
        self.clearMemory()
    }
    
    func clear(but exceptKeys: [Key]? = nil) {
        self._lock.lock {
            self.clearMemory(but: exceptKeys)
            self.isNeedsSave = true
        }
        
        // Notify observers
        observers.enumerateOnMainThread { (observer) in
            observer.cachWasCleared(uniqueCacheName: self.name)
        }
    }
    
    /// will clear and flush out of the cache all items whose addition date is older than a given cutoff date. Items exatly equal to the cutoff date remain in the cache.
    /// - Parameter cutoffDate: date to compare items to
    /// - Returns: number of items removed from the cache
    @discardableResult func clear(beforeDate cutoffDate: Date)->Int {
        guard self.isSavesDates else {
            dlog?.note("clear beforeDate cannot clear when cache [\(self.name)] isSaveDates == false")
            return 0
        }
        
        var cnt = 0
        let newItems = self._items.compactMapValues { (info) -> ValueInfo? in
            if let date = info.date {
                if date.isLaterOrEqual(otherDate: cutoffDate) {
                    return info
                }
            }
            cnt += 1
            return nil
        }
        
        if IS_DEBUG {
            if cnt != self._items.count - newItems.count {
                dlog?.note("clear beforeDate validation of items removed did not come out right!")
            }
        }
        
        // Save
        if cnt > 0 {
            self._items = newItems
            self.isNeedsSave = true
        }
        
        return cnt
    }
    
    /// Will clear all items older than this amount of seconds out of the cache
    /// - Parameter olderThan: seconds of "age" - items that were added to the cache more than this amount of seconds agor will be removed out of the cache
    @discardableResult func clear(olderThan: TimeInterval)->Int {
        guard self.isSavesDates else {
            dlog?.note("clear olderThan cannot clear when cache [\(self.name)] isSaveDates == false")
            return 0
        }
        let date = Date(timeIntervalSinceNow: -olderThan)
        return self.clear(beforeDate: date)
    }
}

extension Cache : CachesEventObserver {
    func applicationDidReceiveMemoryWarning(_ application: Any) {
        self.clearForMemoryWarning()
    }
}

extension Cache where Key : CodableHashable /* saving of keys only*/ {
    
    func filePath(forKeys:Bool)->URL? {
        // .libraryDirectory -- not accessible to user by Files app
        // .cachesDirectory -- not accessible to user by Files app, for caches and temps
        // .documentDirectory -- accessible to user by Files app
        var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let fname = self.name.replacingOccurrences(of: CharacterSet.whitespaces, with: "_").replacingOccurrences(of: CharacterSet.punctuationCharacters, with: "_")
        
        url?.appendPathComponent("mncaches")
        
        if (!FileManager.default.fileExists(atPath: url!.path)) {
            do {
                try FileManager.default.createDirectory(atPath: url!.path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                dlog?.warning("filePath creating subfolder \(url?.lastPathComponent ?? "<nil>" ) failed. error:\(error)")
            }
        }
        
        if forKeys {
            url?.appendPathComponent("kays_for_\(fname).json")
        } else {
            url?.appendPathComponent("\(fname).json")
        }
        
        return url!
    }
    
    func saveKeysIfNeeded()->Bool {
        let interval = abs(self._lastSaveTime?.timeIntervalSinceNow ?? 0)
        if self.isNeedsSave && (interval == 0) || (interval > 1.0 /* second */) {
            return self.saveKeys()
        }
        return false
    }
    
    func saveKeys()->Bool{
        
        guard self._isMemoryCacheOnly == false else {
            self._lastSaveTime = Date()
            self.isNeedsSave = false
            return true
        }
        
        if let url = self.filePath(forKeys: true) {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(self.keys)
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
                self._lastSaveTime = Date()
                self.isNeedsSave = false
                dlog?.info("saveKeys Cache [\(self.name)] size:\(data.count) filename:\(url.path)")
                
                return true
            } catch {
                dlog?.raisePreconditionFailure("saveKeys Cache [\(self.name)] failed with error:\(error.localizedDescription)")
            }
        }
        
        return false
    }
    
    func loadKeys()->[Key]? {
        if let url = self.filePath(forKeys: true), FileManager.default.fileExists(atPath: url.path) {
            if let data = FileManager.default.contents(atPath: url.path) {
                let decoder = JSONDecoder()
                do {
                    // dlog?.info("loadKeys [\(self.name)] load data size:\(data.count)")
                    let loadedKeys : [Key] = try decoder.decode([Key].self, from: data)
                    dlog?.info("loadKeys [\(self.name)] \(loadedKeys.count ) keys")
                    return loadedKeys
                } catch {
                    dlog?.warning("loadKeys [\(self.name)] failed with error:\(error.localizedDescription)")
                }
            } else {
                dlog?.warning("loadKeys [\(self.name)] no data at \(url.path)")
            }
        } else {
            dlog?.warning("loadKeys [\(self.name)] no file at \(self.filePath(forKeys: true)?.path ?? "<nil>" )")
        }
        
        return nil
    }
    
    func clearForMemoryWarning() {
        dlog?.info("clearForMemoryWarning 2")
        _ = saveKeys()
        self.clearMemory()
    }
}

/* saving of cache as a whole */
extension Cache where Key : CodableHashable, Value : Codable {
    
    /// Initialize a Cache of elements with given kes and values with a unique name, max size and flusToSize
    /// - Parameters:
    ///   - name: unique name - this will be used for loggin and saving / loading to files. Use one unique name for each cached file. Having two instances at the same time with the same unique name may create issues. Having two instanced with the same unique name but other types for keys anfd values will for sure create undefined crashes and clashes.
    ///   - maxSize: maximum size for the cache (amount of items). Beyond this size, oldest entered items will be popped, and newwest pushed into the cache.
    ///   - flushToSize: nil or some value. When nil, the cache will pop as many items as required to remain at the maxSize level. When defined, once the caceh hits or surpasses maxSize capaity, te cache will flust and keep only the latest flushToSize elements, popping the remaining elements. flushToSize must be smaller than maxSize by at least one.
    ///   - attemptLoad: will attempt loading this cache immediately after init from the cache file, saved previously using saveIfNeeded(), save(), or by AutoSavedCache class.
    convenience init(name:String, maxSize:UInt, flushToSize:UInt? = 0, attemptLoad:Bool) {
        self.init(name: name, maxSize: maxSize, flushToSize: flushToSize)
        if attemptLoad {
            _ = self.load()
        }
    }
    
    struct SavableValueInfo : CodableHashable {
        let value:Value
        let date:Date?
    }
    
    fileprivate struct SavableStruct : Codable {
        var saveTimeout : TimeInterval = 0.3
        var maxSize : UInt = 10
        var flushToSize : UInt? = nil
        var items : [Key:SavableValueInfo] = [:]
        var latestKeys : [Key] = []
        var name : String = ""
        var isLog : Bool = false
        var oldestItemsDates : [Date] = []
        var isSavesDates : Bool = true
        var isFlushItemsOlderThan : TimeInterval? = nil
        
    }
    
    private func itemsToSavableItems()-> [Key:SavableValueInfo] {
        var savableItems : [Key:SavableValueInfo] = [:]
        for (key, info) in self._items {
            savableItems[key] = SavableValueInfo(value:info.value, date:info.date)
        }
        return savableItems
    }
    
    func savableItemsToItems(_ savalbelInput: [Key:SavableValueInfo])->[Key:ValueInfo] {
        var items : [Key:ValueInfo] = [:]
        for (key, info) in savalbelInput {
            items[key] = ValueInfo(value:info.value, date:info.date)
        }
        return items
    }
    
    fileprivate func createSavableStruct()->SavableStruct {
        // Overridable
        let saveItem = SavableStruct(maxSize: _maxSize,
                                     flushToSize: _flushToSize,
                                     items: self.itemsToSavableItems(),
                                     latestKeys: _latestKeys,
                                     name: self.name,
                                     isLog: self.isLog,
                                     oldestItemsDates: self._oldestItemsDates,
                                     isSavesDates: self.isSavesDates,
                                     isFlushItemsOlderThan: self._isFlushItemsOlderThan)
        return saveItem
    }
    
    @discardableResult func saveIfNeeded()->Bool {
        let interval = abs(self._lastSaveTime?.timeIntervalSinceNow ?? 0)
        if self.isNeedsSave && (interval == 0) || (interval > 1.0 /* second */) {
            return self.save()
        }
        return false
    }
    
    @discardableResult func save()->Bool{
        
        guard self._isMemoryCacheOnly == false else {
            self._lastSaveTime = Date()
            self.isNeedsSave = false
            return true
        }
        
        if let url = self.filePath(forKeys: false) {
            do {
                let saveItem = self.createSavableStruct()
                
                let encoder = JSONEncoder()
                let data = try encoder.encode(saveItem)
                    
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
                dlog?.info("save [\(self.name)] size:\(data.count) filename:\(url.lastPathComponents(count: 3))")
                self._lastSaveTime = Date()
                self.isNeedsSave = false
                return true
            } catch {
                dlog?.raisePreconditionFailure("save [\(self.name)] failed with error:\(error.localizedDescription)")
            }
        }
        
        return false
    }
    
    func load()->Bool {
        if let url = self.filePath(forKeys: false), FileManager.default.fileExists(atPath: url.path) {
            if let data = FileManager.default.contents(atPath: url.path) {
                do {
                    let decoder = JSONDecoder()
                    let saved : SavableStruct = try decoder.decode(SavableStruct.self, from: data)
                    if self.name == saved.name {
                        self._lock.lock {
                            // NO NEED self.name = saved.name
                            self._items = self.savableItemsToItems(saved.items)
                            self._latestKeys = saved.latestKeys
                            
                            // Check for maxSize chage:
                            if self.maxSize != saved.maxSize {
                                self.maxSize = saved.maxSize
                                dlog?.info("load() [\(self.name)] maxSize value has changed: \(self.maxSize)")
                            }
                            
                            // Check for _flushToSize chage:
                            if self._flushToSize != saved.flushToSize {
                                self._flushToSize = saved.flushToSize
                                dlog?.info("load() [\(self.name)] flushToSize value has changed: \(self._flushToSize?.description ?? "<nil>" ) flushToSize)")
                            }
                            
                            // Check for isLog chage:
                            if self.isLog != saved.isLog {
                                self.isLog = saved.isLog
                                dlog?.info("load() [\(self.name)] isLog value has changed: \(self.isLog)")
                            }
                            
                            
                            self._oldestItemsDates = saved.oldestItemsDates
                            self._isSavesDates = saved.isSavesDates
                            self._isFlushItemsOlderThan = saved.isFlushItemsOlderThan
                            
                            // Time has passed when we were saved - we can clear the cache now
                            self.flushToDatesIfNeeded()
                        }
                        return true
                    } else {
                        dlog?.note("(load) [\(self.name)] failed casting dictionary filename:\(url.lastPathComponents(count: 3))")
                    }
                } catch {
                    dlog?.warning("load [\(self.name)] failed with error:\(error.localizedDescription)")
                }
            } else {
                dlog?.warning("load [\(self.name)] no data at \(url.lastPathComponents(count: 3))")
            }
        } else {
            dlog?.warning("load [\(self.name)] no file at \(self.filePath(forKeys: false)?.path ?? "<nil>" )")
        }
        
        return false
    }
    
    func clearForMemoryWarning() {
        dlog?.info("clearForMemoryWarning 3")
        _ = saveKeys()
        self.clearMemory()
    }
}



/// Subclass of Cache<Key : Hashable, Value : Hashable> which attempts to save the cache frequently, but with a timed filter that prevents too many saves per given time
class AutoSavedCache <Key : CodableHashable, Value : CodableHashable> : Cache<Key, Value>  {
    private var _timeout : TimeInterval = 0.3
    
    /// Timeout of save event being called after changes are being made. default is 0.3
    public var autoSaveTimeout : TimeInterval {
        get {
            return _timeout
        }
        set {
            if newValue != _timeout {
                _timeout = max(newValue, 0.01)
            }
        }
    }
    
    override fileprivate func needsSaveWasSetEvent() {
        super.needsSaveWasSetEvent()
        
        TimedEventFilter.shared.filterEvent(key: "\(self.name)_AutoSavedCacheEvent", threshold: max(self.autoSaveTimeout, 0.03)) {
            self.flushToDatesIfNeeded()
            
            dlog?.info("AutoSavedCache [\(self.name)] saveIfNeeded called")
            _ = self.saveIfNeeded()
        }
    }
}

class DBCache <Key : CodableHashable, Value : CodableHashable> : AutoSavedCache <Key, Value> {
    
}
