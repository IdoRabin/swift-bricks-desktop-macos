//
//  DocVC+Actions.swift
//  Bricks
//
//  Created by Ido on 01/01/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocVC+Actions")

// MARK: DocumentVC - Actions
extension DocVC : NSUserInterfacePluralValidations /* Actions */ {
    
    var mainMenu : MainMenu? {
        return BrickDocController.shared.menu
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return BrickDocController.shared.validateUserInterfaceItem(doc: self.document, item: item)
    }
    
    func updateSidebarMenuItems() {
        if let menu = self.mainMenu, self.docWC == BrickDocController.shared.curDocWC {
            menu.updateMenuItems([menu.viewShowProjectSidebarMnuItem,
                                  menu.viewShowUtilitySidebarMnuItem],
                                 inVC: self)
        }
    }
    
    func updateSidebarToolbarItems() {
        self.docWC?.updateSidebarToolbarItems(isLeadingPanelCollapsed: self.mnSplitView.isLeadingPanelCollapsed,
                                              isTrailingPanelCollapsed:self.mnSplitView.isTrailingPanelCollapsed)
    }
    
    @IBAction @objc func toggleSidebarAction(_ sender : Any) {
        // dlog?.info("toggleSidebarAction sender:\(sender)")
        
        var isLeadingSidebar = true
        
        var sendr = sender
        if let btn = sender as? NSButton {
            if let lft = self.docWC?.leadingToggleSidebarItem,
               lft.view == btn || btn.tag <= self.mnSplitView.leadingDividerIndex {
                // Found leading
                sendr = lft
                isLeadingSidebar = true
            } else if let rgt = self.docWC?.trailingToggleSidebarItem,
                      rgt.view == btn || btn.tag >= self.mnSplitView.trailingDividerIndex {
                // Found trailing
                sendr = rgt
                isLeadingSidebar = false
            }
        }
        
        switch sendr {
        case let mnToggle as MNToggleToolbarItem:
            isLeadingSidebar = mnToggle.tag < 2
            
        case let item as NSToolbarItem:
            isLeadingSidebar = item.tag < 2
            
        case let item as NSMenuItem:
            // dlog?.info("toggleSidebarAction sender menu item id:\(item.identifier?.rawValue ?? "<nil>" )")
            isLeadingSidebar = (item.identifier?.rawValue ?? "").lowercased().contains("leading")
            
        default:
            dlog?.note("toggleSidebarAction sender: \(sender)")
        }
        
        // Toggle
        // DO NOT use! super.toggleSidebar(sender) -- super  toggleSidebar ...
        if isLeadingSidebar {
            self.mnSplitView.toggleLeadingPanel()
        } else {
            self.mnSplitView.toggleTrailingPanel()
        }
        
        
        DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
            self.updateSidebarMenuItems()
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: 0.35) {
            self.updateSidebarToolbarItems()
        }
    }
    
    func docController(didChangeCurVCFrom fromVC: DocVC?, toVC: DocVC?) {
        if toVC == self {
            // This vc's window became key and main -
        }
        else if fromVC == self {
            // This vc's window stopped being key and main -
        }
    }
}
