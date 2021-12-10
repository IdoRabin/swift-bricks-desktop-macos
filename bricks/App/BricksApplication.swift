//
//  BricksApplication.swift
//  Bricks
//
//  Created by Ido on 09/12/2021.
//

import Foundation
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("BricksApplication")

@objc class BricksApplication : NSApplication {
    var appDelegate = AppDelegate()
    
    override init() {
        dlog?.info("init")
        super.init()
        self.delegate = appDelegate
        DispatchQueue.main.async {
            self.mainMenu = MainMenu.fromNib()
        }
    }
    
    required init?(coder: NSCoder) {
        dlog?.info("init(coder:)")
        // self.delegate = appDelegate
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
    }
}
