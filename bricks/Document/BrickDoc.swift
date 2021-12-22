//
//  BrickDocument.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import AppKit


fileprivate let dlog : DSLogger? = DLog.forClass("BrickDoc")

struct BrickDocUUID : BUID {
    var uid : UUID!
    var type : String { return TUID.Types.doc.rawValue }
}

class BrickDoc: NSDocument, Identifiable  {

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
    
    // MARK: properties
    var observers = ObserversArray<BrickDocObserver>()
    let brick : Brick
    
    // MARK: Identifiable
    var id : BrickDocUUID {
        return brick.info.id
    }
    
    // MARK: Lifecycle
    override init() {
        brick = Brick()
        super.init()
        self.brick.stats.sessionCount = 1
        // Add your subclass-specific initialization here.
    }
    
    deinit {
        
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
    /// default file extension regardless of file type uti or save operation
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
