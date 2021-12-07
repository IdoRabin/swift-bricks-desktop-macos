//
//  BrickDocumentObserver.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import Foundation

protocol BrickDocumentObserver : AnyObject {
    
    func brickDocumentError(_ brick:BrickDocument, error:AppError?)
    func brickDocumentWillClose(_ brick:BrickDocument)
    func brickDocumentDidClose(_ brick:BrickDocument)
    
    func brickDocumentWillOpen(_ brick:BrickDocument)
    func brickDocumentDidOpen(_ brick:BrickDocument)
}
