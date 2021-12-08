//
//  BrickDocument.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import AppKit


fileprivate let dlog : DSLogger? = DLog.forClass("BrickDocument")

struct BrickDocUUID : BUID {
    var uid : UUID!
    var type : String { return TUID.Types.doc.rawValue }
}

class BrickDocument: NSDocument, Identifiable  {

    // MARK: properties
    var observers = ObserversArray<BrickDocumentObserver>()
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
    
    
    /// default file extension regardless of file type uti or save operation
    /// - Returns: string for the extension of the filename
    static func `extension`()->String? {
        return self.fileNameExtension(forType: "com.idorabin.bricks", saveOperation: .saveAsOperation)
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }

}
