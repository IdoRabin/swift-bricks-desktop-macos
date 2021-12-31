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
        
        
        // This is a hack that allows placing the splitView as a child of the root view of the VC, yet maintaining all NSSplitViewController functionality. We gain the ability to place the splitv in a smaller area than the whole VC.
        // This was done because safeAreaInsets, and additionalSafeAreaInsets did not acheive the wanted result... :(
        let splitview = self.splitView
        let newView = NSView(frame: self.view.frame)
        self.view = newView
        splitview.frame = newView.frame.adding(heightAdd: -(self.docWC?.TOOLBAR_HEIGHT ?? 38.0))
        newView.addSubview(splitview)
        
        // Setup
        setup()

        DispatchQueue.main.async {
            self.title = self.document?.displayName ?? AppStr.UNTITLED.localized()
            self.wc?.updateToolbarDocNameView()
            self.wc?.updateToolbarMainPanelView()
            
            
            dlog?.info("viewDidLoad [\(self.title.descOrNil)]")
            if abs(AppSettings.shared.stats.lastLaunchDate.timeIntervalSinceNow) < 4 {
                TimedEventFilter.shared.filterEvent(key: "DocVC.viewDidLoad", threshold: 0.2, accumulating: self.title.descOrNil) { titles in
                    dlog?.info("Last viewDidLoad loaded: \(titles?.descriptionsJoined ?? "<nil>" )")
                    if titles?.count ?? 0 > 1 {
                        BricksApplication.shared.arrangeInFront(self)
                        BricksApplication.shared.didLoadViewControllersAfterInit()
                        BrickDocController.shared.didLoadViewControllersAfterInit()
                    }
                }
            } else {
                self.mainMenu?.updateWindowsMenuItems()
            }
        }
    }
    
    var docWC : DocWC? {
        guard self.isViewLoaded else {
            return nil
        }
        return self.view.window?.windowController as? DocWC
    }
    
    deinit {
        dlog?.info("deinit for docVC: [\(self.title.descOrNil)]")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        // self.setupToolbarIfPossible()
    }
    
    // MARK: Public
    var document : BrickDoc? {
        guard self.isViewLoaded, let window = self.view.window else {
            dlog?.note("cannot access .document property before self.view is loaded!")
            return nil
        }
        
        return BrickDocController.shared.document(for: window) as? BrickDoc
    }
}


// MARK: DocumentVC - Actions
extension DocVC /* Actions */ {
    
    var docNameOrNil : String {
        return self.wc?.docNameOrNil ?? "<nil>"
    }
    
    var toolbar : NSToolbar? {
        return self.view.window?.toolbar
    }
    
    var wc : DocWC? {
        return self.view.window?.windowController as? DocWC
    }
    
    var mainMenu : MainMenu? {
        return BrickDocController.shared.menu
    }
        
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return true
    }
    
    func updateSidebarMenuItems() {
        if let menu = self.mainMenu {
            menu.updateMenuItems([menu.viewShowProjectSidebarMnuItem,
                                  menu.viewShowUtilitySidebarMnuItem],
                                 inVC: self)
        }
    }
    
    func updateSidebarToolbarItems() {
        self.wc?.updateSidebarToolbarItems(isLeadingPanelCollapsed: self.mnSplitView.isLeadingPanelCollapsed,
                                          isTrailingPanelCollapsed:self.mnSplitView.isTrailingPanelCollapsed)
    }
    
    @IBAction @objc func toggleSidebarAction(_ sender : Any) {
        // dlog?.info("toggleSidebarAction sender:\(sender)")
        
        var isLeadingSidebar = true
        
        var sendr = sender
        if let btn = sender as? NSButton {
            if let lft = self.wc?.leadingToggleSidebarItem,
                lft.view == btn || btn.tag <= self.mnSplitView.leadingDividerIndex {
                // Found leading
                sendr = lft
                isLeadingSidebar = true
            } else if let rgt = self.wc?.trailingToggleSidebarItem,
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
