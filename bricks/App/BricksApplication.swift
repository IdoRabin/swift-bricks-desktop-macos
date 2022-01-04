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
            if self.mainMenu == nil {
                self.mainMenu = MainMenu.fromNib()
            }
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
    
    func updateWindowsMenuItems() {
        // Update the windows menu item - because we load the menu from nib manually,
        // it does not update with the initial doc windows autotmatically.
        // For the rest of the app operation this seems to be automatically handled
        for doc in BrickDocController.shared.documents {
            if let window = (doc.windowControllers.first as? DocWC)?.windowIfLoaded {
                self.addWindowsItem(window, title: doc.displayName, filename: false)
            }
        }
        
        BrickDocController.shared.menu?.updateWindowsMenuItems()
    }
    
    func didLoadViewControllersAfterInit() {
        self.updateWindowsMenuItems()
    }
    
}
