//
//  AppStoryboard.swift
//  Bricks
//
//  Created by Ido Rabin on 03/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Cocoa

enum AppStoryboard : String {
    
    case main = "Main"
    case newproject = "NewProject"
    case splashscreen = "Splashscreen"
    case preferences = "Preferences"
    
    var storyBoard : NSStoryboard {
        get {
            return Self.storyboard(named: self.rawValue)
        }
    }
    
    static func storyboard(named name:String)->NSStoryboard {
        return NSStoryboard.init(name: NSStoryboard.Name(name), bundle: nil)
    }
    
    func instantiateViewController(id:String)->NSViewController? {
        if let viewController = self.storyBoard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(id)) as? NSViewController {
            return viewController
        }
        
        return nil
    }
    
    func instantiateWindowController(id:String)->NSWindowController? {
        if let windowController = self.storyBoard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(id)) as? NSWindowController {
            return windowController
        }
        
        return nil
    }
}
