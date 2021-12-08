//
//  SplashWC.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("SplashWC")

class SplashWC : NSWindowController {
    
    override var windowFrameAutosaveName: NSWindow.FrameAutosaveName {
        get {
            return "\(type(of: self))"
        }
        set {
            // does nothing
        }
    }
    
    override func windowWillLoad() {
        super.windowWillLoad()
        // window?.collectionBehavior = [.ignoresCycle]// , .ignoresCycle, .canJoinAllSpaces]
        AppDocumentHistory.shared.revalidateAll()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        if let window = self.window {
            window.isExcludedFromWindowsMenu = true
            window.isMovableByWindowBackground = true
            window.contentView?.cornerAsCircle()
            window.contentView?.layer?.corner(radius: 12)
            (window.contentViewController as? SplashVC)?.windowController = self
        } else {
            dlog?.note("window is nil, expected value.")
        }
        
        self.window?.delegate = AppDelegate.shared.documentController
        
        DispatchQueue.main.asyncAfter(delayFromNow: 0.12) {[self] in
            self.showWindow(self)
        }
    }
    
    deinit{
        dlog?.info("deinit")
    }
    
}
