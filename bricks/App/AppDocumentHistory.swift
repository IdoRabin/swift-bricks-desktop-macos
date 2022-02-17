//
//  AppDeocumentHistory.swift
//  Bricks
//
//  Created by Ido Rabin on 06/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("AppDocumentHistory")

protocol AppDocumentHistoryObserver {
    func appDeocumentHistoryDidChange()
}

// TODO: Maybe write a generic NSDocumentHistory class <DocumentType:NSDocument, DocumentIDType:Hashable, BasicInfo:???>

fileprivate typealias AppDocHistory = [BrickDocUID:BrickBasicInfo]
class AppDocumentHistory : WhenLoadedable {
    static let FILENAME = AppConstants.DOCUMENT_HISTORY_FILENAME
    
    public var orbservers = ObserversArray<AppDocumentHistoryObserver>()
    var loadingHelper: LoadingHelper = LoadingHelper()
    
    // MARK: Singleton
    public static let shared = AppDocumentHistory()

    // Private properties
    private let _historyLock = NSRecursiveLock()
    private var _history : AppDocHistory = [:]
    
    // Public properties
    public var history : [BrickBasicInfo] {
        get {
            var result : [BrickBasicInfo] = []
            _historyLock.lock {
                result = self._history.valuesSortedByDate()
            }
            return result
        }
    }
    
    var isEmpty : Bool  {
        return self.history.isEmpty
    }
    
    var hasRecents : Bool  {
        return !self.history.isEmpty
    }
    
    // MARK: Lifecycle
    private init() {
        loadingHelper.startLoadingIfNeeded({
            true
        }, onGlobalQueue: true, userInfo: nil) { userInfo in
            self.load()
            return .success(.noChanges)
        }
    }

    // MARK: Private functions
    var historyFilePath : URL? {
        get {
            var directory = FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
            // directory = directory?.appendingPathComponent(Bundle.main.bundleName?.capitalized ?? "Bricks")
            
            let filename = Self.FILENAME
            if let dir = directory?.appendingPathComponent(filename) {
                if FileManager.default.fileExists(atPath: directory!.absoluteString) {
                    return dir.appendingPathComponent(filename).appendingPathExtension("json")
                } else {
                    do {
                        try FileManager.default.createDirectory(at: directory!, withIntermediateDirectories: true, attributes: nil)
                        return dir.appendingPathComponent(filename).appendingPathExtension("json")
                    } catch let error {
                        let appErr = AppError(error: error)
                        DLog.docHistory.warning("filePath failed \(appErr)")
                    }
                    
                }
            }
            return nil
        }
    }
    
    private func loadFromFiles() {
        var result : AppDocHistory = [:]
        for recentURL in NSDocumentController.shared.recentDocumentURLs {
            if FileManager.default.fileExists(atPath: recentURL.path) {
                var sze = 0
                do {
                    let data = try Data(contentsOf: recentURL)
                    sze = data.count
                    
                    let tempBrick = try JSONDecoder().decode(Brick.self, from: data)
                    var info = tempBrick.info
                    if info.displayName == nil {
                        info.displayName = recentURL.lastPathComponent
                    }
                    info.filePath = recentURL
                    result[tempBrick.info.id] = info
                } catch let error {
                    let appErr = AppError(error: error)
                    DLog.docHistory.warning("loadFromFiles for file: \(recentURL.path) failed \(appErr). data size: \(sze)")
                }
            }
            else
            {
                DLog.docHistory.warning("Recent file does not exist: \(recentURL.path)")
            }
        }
        
        DispatchQueue.mainIfNeeded {
            self._historyLock.lock {
                self._history = result
            }
            self.save()
            
            DLog.docHistory.info("loaded w/ \(self.history.count). was loaded from recent urls")
            
            self.orbservers.enumerateOnMainThread(block: { (observer) in
                observer.appDeocumentHistoryDidChange()
            })
        }
    }
    
    private func load(completion:AppResultBlock? = nil) {
        guard let filepath = self.historyFilePath else {
            dlog?.warning("load failed when historyFilePath failed")
            return
        }
        
        if !FileManager.default.fileExists(atPath: filepath.path) {
            completion?(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Bricks settings file was not found!")))
        } else {
            self._historyLock.lock {
                var wasLoaded = false
                do {
                    let recents = NSDocumentController.shared.recentDocumentURLs
                    let data = try Data(contentsOf: filepath)
                    self._history = try JSONDecoder().decode(AppDocHistory.self, from: data)
                    var wasChanged = false
                    if self._history.count > 0 {
                        wasLoaded = true
                        for (uuid, _) in self._history {
                            if let item = self._history[uuid] {
                                if let path = item.filePath {
                                    if !recents.contains(path) || !FileManager.default.fileExists(atPath: path.path) {
                                        self._history[uuid] = nil
                                        wasChanged = true
                                    }
                                } else {
                                    self._history[uuid] = nil
                                    wasChanged = true
                                }
                            }
                        }
                        
                        // Find duplicate uids with same path:
                        var foundDuplicates : [URL:[BrickBasicInfo]] = [:]
                        for (_ , info) in self._history {
                            if let path = info.filePath {
                                var paths = foundDuplicates[path] ?? []
                                paths.append(info)
                                foundDuplicates[path] = paths
                            }
                        }
                        
                        for (url, duplicates) in foundDuplicates {
                            if duplicates.count > 1 {
                                // We have more than one file per path
                                let sorted = duplicates.sorted(by: { (infoA, infoB) -> Bool in
                                    if let a = infoA.lastModifiedDate, let b = infoB.lastModifiedDate {
                                        return a > b
                                    }
                                    
                                    return infoA.creationDate > infoB.creationDate
                                })
                                DLog.docHistory.info("\(sorted.count) duplicates for \(url) will keep:\(sorted.first?.id.description ?? "<no items>" )")
                                for item in sorted {
                                    if item != sorted.first {
                                        // Remove this uuid from _history, since the actual (assuming latest) file refers to another uuid
                                        _history[item.id] = nil
                                        wasChanged = true
                                    }
                                }
                            }
                        }
                        
                        if wasChanged {
                            self.save()
                        }
                        
                        DLog.docHistory.success("load. was loaded from json history")
                        self.orbservers.enumerateOnMainThread(block: { (observer) in
                            observer.appDeocumentHistoryDidChange()
                        })
                    }
                } catch let error {
                    let appErr = AppError(error: error)
                    DLog.docHistory.warning("load failed. error: \(appErr)")
                }
                
                if !wasLoaded {
                    DispatchQueue.notMainIfNeeded {
                        self.loadFromFiles()
                    }
                }
            }
        }
    }
    
    private func save() {
        guard let filepath = self.historyFilePath else {
            dlog?.warning("Save failed when historyFilePath failed")
            return
        }
        
        // Save
        self._historyLock.lock {
            do {
                let data = try JSONEncoder().encode(self._history)
                try data.write(to: filepath, options: Data.WritingOptions.atomicWrite)
            } catch let error {
                let appErr = AppError(error: error)
                DLog.docHistory.warning("save failed \(appErr)")
            }
        }
    }
    
    // MARK: Public functions
    
    /// Clear all document history
    public func clear() {
        self._historyLock.lock {
            self._history.removeAll()
        }
        self.orbservers.enumerateOnMainThread(block: { (observer) in
            observer.appDeocumentHistoryDidChange()
        })
    }
    
    
    /// Update the history to repsent a document was opened / updated
    /// - Parameter info: document info to insert / update in the history
    public func updateBrickInfo(_ info:BrickBasicInfo) {
        self._historyLock.lock {
            self._history[info.id] = info
        }
        self.save()
        self.orbservers.enumerateOnMainThread(block: { (observer) in
            observer.appDeocumentHistoryDidChange()
        })
    }
    
    @discardableResult
    public func revalidateAll()->Bool {
        let recentURLs = NSDocumentController.shared.recentDocumentURLs
        var wasChanged = false
        self._historyLock.lock {
            let toRemove = history.filter({ (item) -> Bool in
                if let filePath = item.filePath {
                    if !recentURLs.contains(filePath) {
                        // Failed test, to remove
                        return true
                    }
                } else {
                    // Failed test, to remove
                    return true
                }
                
                return false
            })
            
            for itemToRemove in toRemove {
                if IS_DEBUG, let path = itemToRemove.filePath {
                    dlog?.note("revalidateAll failed to find \(itemToRemove.displayName.descOrNil) uid:\(itemToRemove.id) in: \(path.lastPathComponents(count: 3))")
                }
                
                self._history[itemToRemove.id] = nil
                wasChanged = true
            }
        }
        
        if wasChanged {
            orbservers.enumerateOnMainThread { (observer) in
                observer.appDeocumentHistoryDidChange()
            }
        }
        if wasChanged {
            dlog?.note("revalidateAll made changes to the saved history.")
        }
        return wasChanged // if was changed, than validation has failed and changes were made..
    }
}
