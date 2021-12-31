//
//  ProjectTabsVC.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//

import AppKit
fileprivate let dlog : DSLogger? = DLog.forClass("ProjctTabsVC")

class ProjectTabsVC : MNTabViewController {
    
    // MARK: Constants
    let DEBUG_DRAWING = IS_DEBUG && true
    let DEBUG_DRAW_ORIG_TABS = IS_DEBUG && false
    
    // MARK: Enums
    enum Tabs : Int, Codable, MNTabViewControllerEnumable {
        case project = 0
        case progress = 1
        case tasks = 2
        
        static var all : [Tabs] = [.project, .progress, .tasks]
        
        var imageName : String {
            switch self {
            case .project:  return "folder"
            case .progress: return "ruler"
            case .tasks:    return "checkmark.square"
            }
        }
        
        var displayName: String {
            switch self {
            case .project:  return AppStr.PROJECT.localized()
            case .progress: return AppStr.PROGRESS.localized()
            case .tasks:    return AppStr.TASKS.localized()
            }
        }
        
        var alternateImageName : String {
            return imageName.appending(".fill")
        }
    }
    
    // MARK: Properties
    weak var stackView : NSStackView? = nil
    override var tabsType: MNTabViewControllerEnumable.Type {
        return Tabs.self
    }
    
    // MARK: Computed vars
    var doc : BrickDoc? {
        return docWC?.document as? BrickDoc
    }
    var docWC : DocWC? {
        return (self.view.window?.windowController as? DocWC)
    }
    
    // MARK: private Properties
    // MARK: Private funcs    
    // MARK: Public funcs
}
