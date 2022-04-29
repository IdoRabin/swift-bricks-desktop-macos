//
//  BrickDocObserver.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import Foundation

protocol BrickDocObserver : AnyObject {
    
    // ALL calls are OPTIONAL!
    func brickDocumentError(_ brick:BrickDoc, error:AppError?)
    func brickDocumentWillClose(_ brick:BrickDoc)
    func brickDocumentDidClose(_ brickUID:BrickDocUID)
    
    func brickDocumentWillOpen(_ brick:BrickDoc) // // brickDocumentWillLoad
    func brickDocumentDidOpen(_ brick:BrickDoc) // // brickDocumentDidLoad
    
    func brickDocumentWillSave(_ brick:BrickDoc)
    func brickDocumentDidSave(_ brick:BrickDoc, result:AppResult)
    
    // TODO: Consider union of those calls into one call?. Consider how to say which one has changed?
    func brickDocumentDidChange(_ brick:BrickDoc, activityState:BrickDoc.DocActivityState)
    func brickDocumentDidChange(_ brick:BrickDoc, saveState:BrickDoc.DocSaveState)
}

extension BrickDocObserver /* Default / Optional implementation */ {
    func brickDocumentError(_ brick:BrickDoc, error:AppError?) {
        // does nothing
    }
    func brickDocumentWillClose(_ brick:BrickDoc) {
        // does nothing
    }
    func brickDocumentDidClose(_ brickUID:BrickDocUID) {
        // does nothing
    }
    
    func brickDocumentWillOpen(_ brick:BrickDoc) { // brickDocumentWillLoad
        // does nothing
    }
    
    func brickDocumentDidOpen(_ brick:BrickDoc) { // // brickDocumentDidLoad
        // does nothing
    }
    
    func brickDocumentWillSave(_ brick:BrickDoc) {
        // does nothing
    }
    func brickDocumentDidSave(_ brick:BrickDoc, result:AppResult) {
        // does nothing
    }
    
    func brickDocumentDidChange(_ brick:BrickDoc, activityState:BrickDoc.DocActivityState) {
        // does nothing
    }
    func brickDocumentDidChange(_ brick:BrickDoc, saveState:BrickDoc.DocSaveState) {
        // does nothing
    }
}
