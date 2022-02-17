//
//  BrickDocument.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDoc")

struct BrickDocUID : BUID {
    var uid : UUID!
    var type : String { return TUID.Types.doc.rawValue }
}

struct LayerUID : BUID {
    var uid : UUID!
    var type : String { return TUID.Types.layer.rawValue }
}

class BrickDoc: NSDocument, BUIDable  {

    override var basicDesc : String {
        return super.basicDesc + " [\(self.displayName.descOrNil)]"
    }
    
    enum DocActivityState {
        case idle
        case userActive
        case operationActive(String, CGFloat)
        case loading(CGFloat)
        case saving(CGFloat)
    }
    
    enum DocSaveState {
        case emptyAndUnsaved
        case unsaved
        case regular
        var iconImageName : ImageString {
            switch self {
            case .emptyAndUnsaved: return AppImages.docNewEmptyDocumentIcon
            case .unsaved: return AppImages.docNewDocumentIcon
            case .regular: return AppImages.docRegularDocumentIcon
            }
        }
        
        var iconImage : NSImage {
            return iconImageName.image
        }
    }
    
    // MARK: static properties

    // MARK: properties
    var observers = ObserversArray<BrickDocObserver>()
    let brick : Brick
    let commandInvoker = QueuedInvoker(name: "BrickDocInvoker")
    var commandLog : FileLog? = nil
    private var _lastClosePrep : Date? = nil
    
    /// Default file extension regardless of file type uti or save operation
    /// - Returns: string for the extension of the filename
    static func `extension`()->String? {
        return self.fileNameExtension(forType: "com.idorabin.bricks", saveOperation: .saveAsOperation)
    }
    
    var docActivityState : DocActivityState = .idle {
        didSet {
            
        }
    }
    
    var docSaveState : DocSaveState {
        if self.isDraft && self.isDocumentEdited == false {
            return .emptyAndUnsaved
        } else if self.isDraft && brick.info.filePath == nil {
            return .unsaved
        } else {
            return .regular
        }
    }
    
    // MARK: Identifiable
    var id : BrickDocUID {
        return brick.info.id
    }
    
    // MARK: Private
    private func archiveOldCommandLogsIfNeeded(url:URL, fileIDName:String) {
        
    }
    
    private func setupCommandLog() {
        DispatchQueue.main.performOncePerInstance(self) {[self] in
            var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            url = url?.appendingPathComponent("DocLogs") // .appendingPathComponent(Bundle.main.bundleName?.capitalized ?? "Bricks")
            
            if !FileManager.default.fileExists(atPath: url!.path) {
                do {
                    try FileManager.default.createDirectory(at: url!, withIntermediateDirectories: true, attributes: [:])
                } catch let error {
                    dlog?.warning("Failed creating DocLogs folder. error: \(error.localizedDescription)")
                }
            }
            
            var fileIDName = brick.id.uid.uuidString
            if self.isDraft || self.docSaveState == .emptyAndUnsaved {
                fileIDName = self.displayName
            }
            fileIDName = fileIDName.trimmingCharacters(in: CharacterSet(charactersIn: "▹⚠️◃\n")).replacingOccurrences(of: .punctuationCharacters, with: "_")
            
            if let url = url?.appendingPathComponent("cmd_log_\(fileIDName).log") {
                let path = url.path
                self.archiveOldCommandLogsIfNeeded(url: url, fileIDName: fileIDName)
                commandLog = FileLog(path: path, encoding: .utf8)
                if let cmdLog = commandLog {
                    cmdLog.whenLoaded({ resultUpdated in
                        cmdLog.appendLines([
                            AppStr.LOG_START.localized(),
                            "App \(AppStr.SESSION_NUMBER_SHORT.localized()): \(AppSettings.shared.stats.launchCount) \(AppStr.SESSION_STARTED.localized()): \(AppSettings.shared.stats.lastLaunchDate)",
                            "Doc \(AppStr.SESSION_NUMBER_SHORT.localized()): \(brick.stats.sessionCount) \(AppStr.SESSION_STARTED.localized()): \((brick.info.lastOpenedDate ?? brick.info.creationDate).description )"
                        ])
                        cmdLog.saveIfNeeded()
                    })
                }
                
            } else {
                dlog?.note("setupCommandLog Failed creating commandLog")
            }
        }
    }
    
    // MARK: Public
    func prepareToClose() {
        guard abs(_lastClosePrep?.timeIntervalSinceNow ?? 999.0) > 0.2 else {
            return
        }
        dlog?.info("[\(self.displayName.descOrNil)] prepareToClose")
        
        // Save all temp items
        if let cmdLog = commandLog {
            cmdLog.saveIfNeeded()
        }
        
        let now = Date.now
        self._lastClosePrep = now
        
    }
    
    // MARK: Lifecycle
    override init() {
        brick = Brick()
        super.init()
        self.brick.stats.sessionCount = 1
        setupCommandLog()
        
        // Add your subclass-specific initialization here.
        dlog?.info("init as draft")
    }
    
    override func awakeAfter(using coder: NSCoder) -> Any? {
        super.awakeAfter(using:coder)
        setupCommandLog()
        
        // Add your subclass-specific initialization here.
        dlog?.info("awake after decoded")
        return self
    }
    
    deinit {
        dlog?.info("deinit")
        
        // Save
        if abs(self.brick.info.lastClosedDate?.timeIntervalSinceNow ?? 999.0) > 0.2 {
            
            // Will close
            self.notifyWillClose()
            
            let now = Date.now
            self.brick.info.lastClosedDate = now
            
            // Save log
            if let cmdLog = commandLog {
                cmdLog.appendLines([
                    "Doc \(AppStr.SESSION_NUMBER_SHORT.localized()): \(brick.stats.sessionCount)",
                    "Doc \(AppStr.SAVED.localized()): \(brick.info.lastSavedDate.descOrNil) \(AppStr.SESSION_ENDED.localized()): \(brick.info.lastClosedDate.descOrNil)"
                ])
                cmdLog.saveIfNeeded()
                cmdLog.loadingHelper.callCompletionsAndClear()
            }
            
            
            // Did close
            self.notifyDidClose(uid: self.id)
        }
    }
    
    // MARK: overrides
    /// Get the file extension for a given file type uti
    /// - Parameters:
    ///   - typeName: A string containing a file type UTI
    ///   - saveOperation: save operation kind
    /// - Returns: string for the extension of the filename
    static func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
        switch (typeName, saveOperation) {
        default:
            return AppConstants.BRICK_FILE_EXTENSION
        }
    }
    
    /// Get the file extension for a given file type uti
    /// - Parameters:
    ///   - typeName: A string containing a file type UTI
    ///   - saveOperation: save operation kind
    /// - Returns: string for the extension of the filename
    override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
        return Self.fileNameExtension(forType: typeName, saveOperation: saveOperation)
    }
    
//    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
//        
//        return super.canClose(withDelegate: delegate, shouldClose: shouldCloseSelector, contextInfo: contextInfo)
//    }

    override class var autosavesInPlace: Bool {
        return true
    }
    
    override var fileModificationDate: Date? {
        get {
            return super.fileModificationDate ?? brick.info.lastModifiedDate
        }
        set {
            super.fileModificationDate = newValue
            brick.info.lastModifiedDate = newValue
            
            // Assuming was just now saved?
            dlog?.todo("Implement saved stats and basic info changes")
        }
    }
    
    override var isDraft: Bool {
        get {
            return brick.info.lastClosedDate == nil && brick.stats.savesCount == 0
        }
        set {
            dlog?.todo("isDraft cannot be set directly (make changes / save doc) to affect this property.")
        }
    }

}

 extension BrickDoc /* overrides */ {
     
     override func defaultDraftName() -> String {
         return AppStr.UNTITLED.localized()
     }
     
     override func makeWindowControllers() {
         // Returns the Storyboard that contains your Document window.
         if let windowController = AppStoryboard.document.instantiateWindowController(id: "DocWCID") {
             windowController.windowFrameAutosaveName = NSWindow.FrameAutosaveName("BrickDocWindow")
             self.addWindowController(windowController)
         } else {
             dlog?.note("Failed loading DocWCID from storyboard")
         }
     }
 }

extension BrickDoc /* notifyObservers */ {
    
    func notifyWillClose() {
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentWillClose(self)
        }
    }
    
    func notifyDidClose(uid:BrickDocUID) {
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentDidClose(uid)
        }
    }
    
    func notifyWillOpen() {
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentWillOpen(self)
        }
    }

    func notifyDidOpen() {
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentDidOpen(self)
        }
    }
    
    func notifyDidChange(activityState:BrickDoc.DocActivityState) {
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentDidChange(self, activityState: activityState)
        }
    }
    
    func notifyDidChange(saveState:BrickDoc.DocSaveState) {
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentDidChange(self, saveState: saveState)
        }
    }
}

