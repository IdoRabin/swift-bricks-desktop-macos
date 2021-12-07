//
//  BrickDocumentController.swift
//  Bricks
//
//  Created by Ido Rabin on 08/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Cocoa

class BrickDocumentController: NSDocumentController {
    
    private var _recentDocURL:URL? = nil
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func clearRecentDocuments(_ sender: Any?) {
        super.clearRecentDocuments(sender)
        AppDocumentHistory.shared.clear()
    }
    
    override func noteNewRecentDocument(_ document: NSDocument) {
        _recentDocURL = nil
        super.noteNewRecentDocument(document)
        DispatchQueue.main.async {
            if let url = self._recentDocURL, let brickDocument = document as? BrickDocument {
                brickDocument.brick.info.displayName = document.displayName
                brickDocument.brick.info.filePath = url
                AppDocumentHistory.shared.updateBrickInfo(brickDocument.brick.info)
            }
            
            self._recentDocURL = nil
        }
    }
    
    override func noteNewRecentDocumentURL(_ url: URL) {
        super.noteNewRecentDocumentURL(url)
        _recentDocURL = url
    }
}
