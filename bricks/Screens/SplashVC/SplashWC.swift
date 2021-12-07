//
//  SplashWC.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("SplashWC")

class SplashWC : NSWindowController {
    
    override func windowWillLoad() {
        super.windowWillLoad()
        // window?.collectionBehavior = [.ignoresCycle]// , .ignoresCycle, .canJoinAllSpaces]
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.isExcludedFromWindowsMenu = true
        window?.delegate = self
        window?.isMovableByWindowBackground = true
        DispatchQueue.main.asyncAfter(delayFromNow: 1) {
            self.showWindow(self)
        }
    }
    
    deinit{
        dlog?.info("deinit")
    }
}
 
extension SplashWC : NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        DLog.splash.info("windowWillClose")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Re-validate
        DLog.splash.info("windowDidBecomeKey")
        AppDocumentHistory.shared.revalidateAll()
    }
}
