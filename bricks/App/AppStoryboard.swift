//
//  AppStoryboard.swift
//  Bricks
//
//  Created by Ido Rabin on 03/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Cocoa
fileprivate let dlog : DSLogger? = DLog.forClass("AppStoryboard")

enum AppStoryboard : String {
    
    case document = "Doc"
    case newproject = "NewProject"
    case onboarding = "Onboarding"
    case misc = "misc" // about, preferences
    
    var storyBoard : NSStoryboard {
        get {
            return Self.storyboard(named: self.rawValue)
        }
    }
    
    static func storyboard(named name:String)->NSStoryboard {
        return NSStoryboard.init(name: NSStoryboard.Name(name), bundle: nil)
    }
    
    func instantiateViewController(id:String)->NSViewController? {
        guard Thread.current.isMainThread else {
            dlog?.warning("instantiateViewController should only be called on main thread!")
            return nil
        }
        
        if let viewController = self.storyBoard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(id)) as? NSViewController {
            return viewController
        }
        
        return nil
    }
    
    func instantiateWindowController(id:String)->NSWindowController? {
        guard Thread.current.isMainThread else {
            dlog?.warning("instantiateWindowController should only be called on main thread!")
            return nil
        }
        
        if let windowController = self.storyBoard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(id)) as? NSWindowController {
            return windowController
        }
        
        return nil
    }
    
    func instantiateWCAndPresent(from presentingWC:NSWindow?, id:String, asMain:Bool, asKey:Bool, setup:((NSWindowController)->Void)? = nil) {
        guard Thread.current.isMainThread else {
            dlog?.warning("instantiateWCAndPresent should only be called on main thread!")
            return
        }

        let presWC = presentingWC ?? BricksApplication.shared.orderedWindows.first
        if let wc = self.instantiateWindowController(id: id) {

            // Setup
            setup?(wc)

            wc.window?.orderFront(self)
            wc.window?.delegate = BrickDocController.shared

            if asKey {
                wc.window?.makeKey()
            }
            
            if asMain {
                if wc.window?.canBecomeMain ?? false {
                    wc.window?.makeMain()
                } else {
                    dlog?.note("Window for \(id) cannot become main ")
                    // Attempts to make the window the main window are abandoned if the value of this property is false. The value of the property is true if the window is visible, is not an NSPanel object, and has a title bar or a resize mechanism. Otherwise, the value is false.
                }
            }

            wc.showWindow(presWC)

        } else {
            dlog?.note("\(self) failed finding WC with the id: \"\(id)\"")
        }
    }
    
    func instantiateVCAndPresent(from presentingWC:NSWindow?, id:String, asMain:Bool, asKey:Bool, setup:((NSWindowController)->Void)? = nil) {
        guard Thread.current.isMainThread else {
            dlog?.warning("instantiateWCAndPresent should only be called on main thread!")
            return
        }

        let presWC = presentingWC ?? BricksApplication.shared.orderedWindows.first
        if let vc = self.instantiateViewController(id: id) {

            let wc = NSWindowController()
            wc.contentViewController = vc
            
            // Setup
            setup?(wc)

            wc.window?.orderFront(self)
            // wc.window?.delegate = BrickDocController.shared

            if asKey {
                wc.window?.makeKey()
            }
            if asMain {
                if wc.window?.canBecomeMain ?? false {
                    wc.window?.makeMain()
                } else {
                    dlog?.note("Window for \(id) cannot become main ")
                    // Attempts to make the window the main window are abandoned if the value of this property is false. The value of the property is true if the window is visible, is not an NSPanel object, and has a title bar or a resize mechanism. Otherwise, the value is false.
                }
            }

            wc.showWindow(presWC)

        } else {
            dlog?.note("\(self) failed finding WC with the id: \"\(id)\"")
        }
    }
}
