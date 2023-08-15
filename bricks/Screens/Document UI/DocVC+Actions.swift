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
    // MARK: static
    private static let UNKNOWN = "<Unknown>"
    
    // MARK: Computed vars
    var mainMenu : MainMenu? {
        return BrickDocController.shared.menu
    }
    
    func setToggleButtonEnabled(view:NSView?, enabled:Bool = true, completion: (()->Void)? = nil) {
        guard let btn = view as? NSButton else {
            completion?()
            return
        }
        
        btn.isEnabled = enabled
        NSView.animate(duration: 01, changes: { ctx in
            btn.alphaValue = enabled ? 1.0 : 0.4
        }, completionHandler: completion)
    }
    
    // MARK: IBActions:
    @IBAction @objc func toggleSidebarAction(_ sender : Any) {
        
        var found_id = Self.UNKNOWN
        var found_view : NSView? = nil
        
        if let item = sender as? NSToolbarItem, let anId = (sender as? NSToolbarItem)?.itemIdentifier.rawValue, anId.count > 0 {
            found_id = anId
            found_view = item.view
            dlog?.info("toggleSidebarAction NSToolbarItem: \(found_id)")
        } else if let aview = sender as? NSView, let anId = aview.identifier?.rawValue, anId.count > 0 {
            found_id = anId
            found_view = aview
            dlog?.info("toggleSidebarAction NSView: \(found_id)")
        }
        
        let isLeadingSidebar = found_id.lowercased().contains("leading")
        let isTrailingSidebar = found_id.lowercased().contains("trailing")
        
        if isLeadingSidebar || isTrailingSidebar {
            
            let animation_completion :(() -> Void) = { [self, found_view] in
                self.setToggleButtonEnabled(view: found_view, enabled: true) {
                    self.updateSidebarToolbarItems()
                }
            }
            
            // Start toggle button animation:
            setToggleButtonEnabled(view: found_view, enabled: false) {
                if isLeadingSidebar {
                    self.mnSplitView.toggleLeadingPanel(animated: true, completion: animation_completion)
                } else if isTrailingSidebar {
                    self.mnSplitView.toggleTrailingPanel(animated: true, completion: animation_completion)
                }
            }
        } else {
            dlog?.warning("toggleSidebarAction failed finding toggle button's side: \(sender)")
        }

        DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
            self.updateSidebarMenuItems()
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: 0.35) {
            self.updateSidebarToolbarItems()
        }
    }
    
    // MARK: Other Actions:
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return BrickDocController.shared.validateUserInterfaceItem(doc: self.document, item: item)
    }
    
    func updateSidebarMenuItems(depth:Int = 0) {
        // Prevent timed recursion
        guard depth <= 10 else {
            dlog?.warning("updateSidebarMenuItems: timed recursion too big")
            return
        }
        let block = {
            if let menu = self.mainMenu, self.docWC == BrickDocController.shared.curDocWC {
                if self.isAllowedSidebarUpdate(context:"updateSidebarMenuItems") {
                    dlog?.success("updateSidebarMenuItems (by panels depth: \(depth)")
                    menu.updateMenuItems([menu.viewShowProjectSidebarMnuItem,
                                          menu.viewShowUtilitySidebarMnuItem],
                                         context: "updateSidebarMenuItems")
                } else {
                    dlog?.warning("updateSidebarMenuItems: not allowed to update sidebar menu items (by panels, depth: \(depth))!")
                    DispatchQueue.main.asyncAfter(delayFromNow: 0.05) {
                        self.updateSidebarMenuItems(depth: depth + 1)
                    }
                }
            }
        }
        
        if depth > 0 {
            // depth > 0 is timed recursion from within the block
            block()
        } else {
            // Calls from external sources have a timed event filter
            TimedEventFilter.shared.filterEvent(key: "updateSidebarMenuItems", threshold: 0.15) {
                block()
            }
        }
        
    }
    
    func isAllowedSidebarUpdate(context ctx:String = "unknown" /* Self.UNKNOWN */)->Bool {
        /*
         
         Apparently - checking window state is not needed here:
         // Window checks:
         guard self.docWC?.isLoaded == true else {
             dlog?.note("isAllowedSidebarUpdate ctx: \(ctx) panels - window was not loaded yet!")
             return false
         }
         
         */
        
        // VC checks:
        guard self.isViewLoaded else {
            dlog?.note("isAllowedSidebarUpdate ctx: \(ctx) panels - VC was not loaded yet!")
            return false
        }
        
        return true
    }
    
    func updateSidebarToolbarItems(depth:Int = 0) {
        guard depth < 10 else {
            dlog?.warning("updateSidebarToolbarItems timed recursion too deep!")
            return
        }
        
        if self.isAllowedSidebarUpdate(context:"updateSidebarToolbarItems") {
            // We are in DocVC + Actions
            TimedEventFilter.shared.filterEvent(key: "updateSidebarToolbarItems", threshold: 0.05) {[weak self] in
                if let self = self {
                    self.docWC?.updateSidebarToolbarItems(
                        isLeadingPanelCollapsed: self.mnSplitView.isLeadingPanelCollapsed,
                        isTrailingPanelCollapsed:self.mnSplitView.isTrailingPanelCollapsed)
                }
            }
        } else if depth == 0 {
            waitFor("updateSidebarToolbarItems", interval: 0.07, timeout: 0.5, testOnMainThread: {
                self.isAllowedSidebarUpdate(context:"updateSidebarToolbarItems")
            }, completion: {[weak self] waitResult in
                if waitResult.isSuccess {
                    self?.updateSidebarToolbarItems(depth: depth + 1)
                }
            })
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
