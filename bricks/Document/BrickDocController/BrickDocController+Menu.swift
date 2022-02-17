//
//  BrickDocController+Menu.swift
//  Bricks
//
//  Created by Ido on 04/01/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDocController+Menu")

extension BrickDocController /* main menu */ {
    
    // MARK: Public Menu-related funcs
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let menu = self.menu else {
            return false
        }
        
        if let result = menu.updateMenuItem(menuItem, doc: self.curDoc, docWC: self.curDocWC, context: "validateMenuItem") {
            return result
        } else if let menuItem = menuItem as? MNMenuItem, let cmd = menuItem.associatedCommand, let result = self.isAllowed(commandType: cmd, context: "validateMenuItem(noDoc))") {
            return result
        } else if menuItem.title.count > 0 && menuItem.action != nil, let result = self.isAllowedNativeAction(menuItem.action, context: "validateMenuItem(noDoc)") {
            return result
        }

        return super.validateMenuItem(menuItem)
        
    }
    
    func invalidateMenu(context:String) {
        TimedEventFilter.shared.filterEvent(key: "invalidateMenu", threshold: 0.06, accumulating: context) { contexts in
            self.menu?.updateMenuItems(nil, context: context) // all items
        }
    }
}
