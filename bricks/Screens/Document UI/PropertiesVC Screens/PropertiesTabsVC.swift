//
//  PropertiesTabsVC.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//
import AppKit

class PropertiesTabsVC : MNTabViewController {
    
    // MARK: Enums
    private enum Tabs : Int, Codable, MNTabViewControllerEnumable {
        case one
        case two
        
        var imageName: String {
            switch self {
            case .one:
                return "circle"
            case .two:
                return "square"
            }
        }
        
        var alternateImageName: String {
            return imageName.appending(".fill")
        }
        
        var displayName: String {
            return "xxx"
        }
        
        static var all : [Tabs] = [.one, .two]
        
    }
    
    // MARK: REQUIRED overrides from MNTabViewController
    override var tabsType : MNTabViewControllerEnumable.Type {
        return Tabs.self
    }
    
    // MARK: Computed vars
    var doc : BrickDoc? {
        return docWC?.document as? BrickDoc
    }
    var docWC : DocWC? {
        return (self.view.window?.windowController as? DocWC)
    }
}

