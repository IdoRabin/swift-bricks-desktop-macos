//
//  BrickDocObserver.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import Foundation

protocol BrickDocObserver : AnyObject {
    
    func brickDocumentError(_ brick:BrickDoc, error:AppError?)
    func brickDocumentWillClose(_ brick:BrickDoc)
    func brickDocumentDidClose(_ brickUID:BrickDocUID)
    
    func brickDocumentWillOpen(_ brick:BrickDoc)
    func brickDocumentDidOpen(_ brick:BrickDoc)
    
    func brickDocumentDidChange(_ brick:BrickDoc, activityState:BrickDoc.DocActivityState)
    func brickDocumentDidChange(_ brick:BrickDoc, saveState:BrickDoc.DocSaveState)
}
