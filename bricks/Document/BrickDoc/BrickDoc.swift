//
//  BrickDocument.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDoc")

extension NSDocument.SaveOperationType : CustomStringConvertible {
    public var description: String {
        switch self {
        case .saveOperation:                return "save"
        case .saveAsOperation:              return "saveAs"
        case .saveToOperation:              return "saveTo"
        case .autosaveInPlaceOperation:     return "autosaveInPlace"
        case .autosaveElsewhereOperation:   return "autosaveElsewhere"
        case .autosaveAsOperation:          return "autosaveAs"
        default:
            return "Unknown"
        }
    }
    
    var isAutosave : Bool {
        return [.autosaveAsOperation, .autosaveElsewhereOperation, .autosaveInPlaceOperation].contains(self)
    }
}
//extension UTType {
//    static var brickDocument = UTType(exportedAs: "com.idorabin.bricks.document")
//}

class BrickDoc: NSDocument, BUIDable  {
    
    static let DATA_TYPE_NAME = AppConstants.BRICK_FILE_UTI
    static let DATA_FILE_EXTENSION = AppConstants.BRICK_FILE_EXTENSION
    
    static var readableContentTypes: [String] { [DATA_TYPE_NAME] }
    
    override var basicDesc : String {
        return super.basicDesc + " [\(self.displayName.descOrNil)]"
    }
    
    enum DocActivityState {
        case idle
        case userActive
        case operationActive(String, CGFloat)
        case loading(CGFloat)
        case saving(CGFloat)
        
        var isSaving : Bool {
            switch self {
            case .saving: return true
            default: return false
            }
        }
        var isLoading : Bool {
            switch self {
            case .loading: return true
            default: return false
            }
        }
    }
    
    enum DocSaveState {
        case emptyAndUnsaved
        case unsaved // needs saving
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
    private (set) var brick : Brick
    let docCommandInvoker = QueuedInvoker(name: "BrickDocInvoker")
    var commandLog : FileLog? = nil
    private var _lastClosePrep : Date? = nil
    
    /// Default file extension regardless of file type uti or save operation
    /// - Returns: string for the extension of the filename
    static func `extension`()->String? {
        return self.fileNameExtension(forType: "com.idorabin.bricks", saveOperation: .saveAsOperation)
    }
    
    var docActivityState : DocActivityState = .idle {
        didSet {
            self.notifyDidChange(activityState: docActivityState)
        }
    }
    
    private var _docSaveState : DocSaveState = .unsaved
    var docSaveState : DocSaveState {
        var result = _docSaveState
        if self.isDraft && self.isDocumentEdited == false {
            result = .emptyAndUnsaved
        } else if brick.isNeedsSaving || (self.isDraft && brick.info.filePath == nil) {
            result = .unsaved
        } else {
            result = .regular
        }
        if result != _docSaveState {
            _docSaveState = result
            // RECURSIVE for the observers
            self.notifyDidChange(saveState: result)
        }
        return result
    }
    
    func setNeedsSaving(sender:Any, context: String, propsAndVals: [String : String], executionMehod:CommandExecutionMethod? = .execute) {
        brick.setNeedsSaving(sender: sender, context: context, propsAndVals: propsAndVals)
        
        DispatchQueue.mainIfNeeded {[self] in
            switch executionMehod {
            case .undo: updateChangeCount(NSDocument.ChangeType.changeUndone)
            case .redo: updateChangeCount(NSDocument.ChangeType.changeRedone)
            case .execute: updateChangeCount(NSDocument.ChangeType.changeDone)
            default:
                break
            }
        }
        
        if self.isDraft == false || self.hasUnautosavedChanges {
            TimedEventFilter.shared.filterEvent(key: "BrickDoc.setNeedsSaving", threshold: 0.1) {
                dlog?.info("BrickDoc.autosaving / scheduleAuosaving")
                
                if self.docActivityState.isSaving == false {
                    self.autosave(withImplicitCancellability: true) { error in
                        if let error = error {
                            dlog?.warning("Failed autosaving \(error.localizedDescription)")
                            self.scheduleAutosaving()
                        }
                    }
                } else {
                    // Set needs saving, but target the future (persumably after save to file is over):
                    DispatchQueue.main.asyncAfter(delayFromNow: 0.3) {
                        self.scheduleAutosaving()
                    }
                }
            }
        }
        
        self.notifyDidChange(saveState: self.docSaveState)
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
    
    private func setup() {
        setupCommandLog()
        docCommandInvoker.associatedOwner = self
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
    
    var isClosing : Bool {
        var result = false
        
        if result == false, let tme = _lastClosePrep?.timeIntervalSinceNow {
            result = tme < 15.0
        }
        return result
    }
    
    // MARK: Lifecycle
    override init() {
        brick = Brick()
        super.init()
        self.brick.stats.sessionCount = 1
        setup()
        
        // Add your subclass-specific initialization here.
        dlog?.info("Init <\(type(of: self)) \(String(memoryAddressOf: self))>")
    }
    
    override func awakeAfter(using coder: NSCoder) -> Any? {
        super.awakeAfter(using:coder)
        setup()
        
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
        
        // Clear weak (JIC) / strong referencesr
        docCommandInvoker.associatedOwner = nil // not needed, but good practice if changes to strong ref
    }
    
    // MARK: NSDocument overrides
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
            return brick.info.lastClosedDate == nil && brick.stats.savesByCommandCount == 0
        }
        set {
            dlog?.todo("isDraft cannot be set directly (make changes / save doc) to affect this property.")
        }
    }

    // Data for save operation:
    override func data(ofType typeName: String) throws -> Data {
        // Asked by NSDocument saving system
        dlog?.info("preparing data(ofType:\(typeName))")
        var result : Data? = nil
        var error : AppError? = nil
        
        switch typeName {
        case Self.DATA_TYPE_NAME:
            result = self.brick.serializeToJsonData(prettyPrint: IS_DEBUG)
        default:
            error = AppError(AppErrorCode.doc_save_failed, detail:"Data(ofType:\(typeName))->Data. did not handle this type.")
        }
        
        if result == nil {
            error = AppError(AppErrorCode.doc_save_failed, detail:"Data(ofType:\(typeName))->Data. MUST return a valid data value.")
        }
        
        // throw error
        if let error = error {
            throw error
        }
        return result!
    }
    
    private func handleAfterLoadedEvents(loadStartTime:Date) {
        
        // Stats changed after loaded:
        let loadDuration : TimeInterval = abs(loadStartTime.timeIntervalSinceNow)
        brick.stats.loadsTimings.add(amount: 1, value: loadDuration)
        brick.stats.loadsCount += 1
        brick.info.lastOpenedDate = Date()
        if (brick.info.lastSavedDate == nil)  { brick.info.lastSavedDate = Date() }
        
        // Clear "needs saving" is needed
        waitFor("does doc need saving?", interval: 0.04, timeout: 0.16, testOnMainThread: {
            self.brick.isNeedsSaving == true
        }, completion: { waitResult in
            DispatchQueue.mainIfNeeded {
                if self.brick.isNeedsSaving == true {
                    dlog?.warning("Brick was loaded and immediately needs saving?!?!")
                } else {
                    self.notifyDidChange(saveState: self.docSaveState)
                }
            }
        }, logType: .onlyOnSuccess)
        
        // function read(from data: Data... will notify WillLoad/DidLoad/WillOpen/DidOpen
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        dlog?.info("preparing for load: data(ofType:\(typeName))")
        var error : AppError? = nil
        DLog.indentStart(logger: dlog)
        let startTime = Date()
        
        switch typeName {
        case Self.DATA_TYPE_NAME:
            self.notifyWillOpen() // WillLoad
            self.docActivityState = .loading(0.0)
            
            if let loadedBrick : Brick = Brick.deserializeFromJsonData(data: data) {

                dlog?.info("loaded saved brick dated: \(loadedBrick.info.lastSavedDate.descOrNil) save #: \(loadedBrick.stats.savesCount) load #: \(loadedBrick.stats.loadsCount)")
                self.brick = loadedBrick
                self.handleAfterLoadedEvents(loadStartTime:startTime)
                
            } else {
                error = AppError(AppErrorCode.doc_load_failed, detail:"failed deserializing brick as json")
            }
        default:
            error = AppError(AppErrorCode.doc_load_failed, detail:"read(from data:ofType:\(typeName)) did not handle this type.")
        }
        
        // NotifyDidLoad
        self.notifyDidOpen(result: AppResult.fromError(error, orSuccess: self))
        DLog.indentEnd(logger: dlog)
        self.docActivityState = .idle
        
        if let error = error {
            dlog?.warning("Failed loading doc with error: \(error.desc)")
            throw error
        } else {
            dlog?.success("Loaded \(self.basicDesc) id: \(self.id) layers: \(self.brick.layers.count)")
        }
    }
    
    override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (Error?) -> Void) {
        dlog?.info("Save START \(saveOperation.description)")
        DLog.indentStart(logger: dlog)
        
        self.notifyWillSave()
        
        // Stats change saved:
        self.brick.stats.savesCount += 1
        self.brick.info.lastSavedDate = Date()
        self.docActivityState = .saving(0.0)
        
        super.save(to: url, ofType: typeName, for: saveOperation) { error in
            if let error = error {
                let err = AppError(AppErrorCode.doc_save_failed, detail: "Save failed", underlyingError: error)
                self.notifyDidSave(result: .failure(err))
            } else {
                self.notifyDidSave(result: .success(self))
                if saveOperation.isAutosave == false {
                    self.brick.stats.savesByCommandCount += 1
                }
            }
            self.docActivityState = .saving(1.0)
            completionHandler(error)
            DLog.indentEnd(logger: dlog)
            dlog?.successOrFail(condition: error == nil, items: "Save END error: \(error.descOrNil)")
            
            DispatchQueue.main.asyncAfter(delayFromNow: 0.15, block: {
                self.docActivityState = .idle
            })
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
    
    func notifyWillOpen() { // NotifyWillLoad
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentWillOpen(self)
        }
    }

    func notifyDidOpen(result:AppResult) { // NotifyDidLoad
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentDidOpen(self)
        }
    }
    
    func notifyWillSave() {
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentWillSave(self)
        }
    }
    
    func notifyDidSave(result:AppResult) {
        observers.enumerateOnMainThread { observer in
            observer.brickDocumentDidSave(self, result: result)
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

