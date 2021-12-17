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
    
    override class var shared: BricksApplication {
        return super.shared as! BricksApplication
    }
    
    override init() {
        super.init()
        dlog?.info("init \(basicDesc)")
        self.delegate = AppDelegate.shared
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
        dlog?.info("deinit \(self.basicDesc)")
    }
    
}
