//
//  DocVC.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocVC")

class DocVC : NSSplitViewController {
    let DEBUG_DRAWING = IS_DEBUG && true
    
    fileprivate var cache = Cache<NSToolbarItem.Identifier,NSToolbarItem>(name: "itemsCach", maxSize: 200, flushToSize: 100)
    
    var mnSplitView: MNSplitview {
        return super.splitView as! MNSplitview
    }
    
    // MARK: Private
    private func setup() {
        self.mnSplitView.hostingSplitVC = self
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        dlog?.info("viewDidLoad")
        
        DispatchQueue.main.async {
            self.title = self.document?.displayName ?? AppStr.UNTITLED.localized()
            dlog?.info("viewDidLoad - for docVC: [\(self.title.descOrNil)]")
        }
    }
    
    deinit {
        dlog?.info("deinit for docVC: [\(self.title.descOrNil)]")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    // MARK: Public
    var document : BrickDoc? {
        guard self.isViewLoaded else {
            dlog?.note("cannot access .document property before self.view is loaded!")
            return nil
        }
        
        return BrickDocController.shared.document(for: self.view.window!) as? BrickDoc
    }
}


// MARK: DocumentVC - Actions
extension DocVC /* Actions */ {
    
    static var current :DocVC? {
        for window in BricksApplication.shared.orderedWindows {
            if let vc = window.contentViewController as? DocVC {
                return vc
            }
        }
        return nil
    }
    
    var isLeadingSidebarCollapsed : Bool {
        return (splitView as? MNSplitview)?.isLeadingSidebarCollapsed ?? false
    }
    
    var isTrailingSidebarCollapsed : Bool {
        return (splitView as? MNSplitview)?.isTrailingSidebarCollapsed ?? false
    }
    
    var toolbar : DocToolbar? {
        return self.view.window?.toolbar as? DocToolbar
    }
    
    var mainMenu : MainMenu? {
        return BrickDocController.shared.menu
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return true
    }
    
    @IBAction @objc func toggleSidebarAction(_ sender : Any) {
        // dlog?.info("toggleSidebarAction sender:\(sender)")
        
        var isLeadingSidebar = true
        
        var sendr = sender
        if let btn = sender as? NSButton {
            if let lft = self.leadingToggleSidebarItem,
                lft.view == btn || btn.tag <= self.mnSplitView.leadingDividerIndex {
                // Found leading
                sendr = lft
                isLeadingSidebar = true
            } else if let rgt = self.trailingToggleSidebarItem,
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
            switch item.identifier?.rawValue ?? "" {
            case "toggleLeadingSidebarMenuItemID":  isLeadingSidebar = true
            case "toggleTrailingSidebarMenuItemID": isLeadingSidebar = false
            default:
                dlog?.note("toggleSidebarAction was called from menu with unhandled identifier: \(item.identifier?.rawValue ?? "<nil>")")
            }
            
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
        DispatchQueue.main.async {
            self.updateSidebarMenuItems()
            self.updateSidebarToolbarItems()
        }
    }
    
}

// MARK: NSSplitViewDelegate
extension DocVC /* NSSplitViewDelegate */ {
    
    private func validateToolbarDelegation() {
        // Sadly, the vc CHANGES the DELEGATE SOMETIMES
        if mnSplitView.delegate !== self {
            mnSplitView.delegate = self
        }
    }
    
    private func calcSidebarbTNSstate() {
        self.updateSidebarToolbarItems()
        self.updateSidebarMenuItems()
        self.validateToolbarDelegation()
    }
    
    override func splitViewDidResizeSubviews(_ notification: Notification) {
        // Sadly, the vc CHANGES the DELEGATE SOMETIMES//
        self.validateToolbarDelegation()
    }
    
    override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        calcSidebarbTNSstate()
        DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
            self.calcSidebarbTNSstate()
        }
        return true
    }
}

extension DocVC : MNSplitviewDelegate {
    
    func splitviewSidebarsChanged(_ splitview: MNSplitview, isLeadingCollapsed: Bool, isTrailingCollapsed: Bool) {
        calcSidebarbTNSstate()
        self.updateSidebarMenuItems()
    }
}
