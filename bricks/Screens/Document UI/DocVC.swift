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
    private var _latestSplitViewStateHash : Int = -1
    
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
            self.docWC?.updateToolbarDocNameView()
            self.docWC?.updateToolbarMainPanelView()
            
            
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
                self.mainMenu?.updateWindowsDynamicMenuItems()
            }
        }
    }
    
    var docWC : DocWC? {
        guard self.isViewLoaded else {
            return nil
        }
        return self.view.window?.windowController as? DocWC
    }
    
    var docNameOrNil : String {
        return self.docWC?.docNameOrNil ?? "<nil>"
    }
    
    var toolbar : NSToolbar? {
        return self.view.window?.toolbar
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

// MARK: NSSplitViewDelegate
extension DocVC /* NSSplitViewDelegate */ {
    
    private func validateToolbarDelegation() {
        // Sadly, the vc CHANGES the DELEGATE SOMETIMES
        if mnSplitView.delegate !== self {
            mnSplitView.delegate = self
        }
    }
    
    private func calcSidebarbTNSstate() {
        let newHashValue = mnSplitView.stringDesc.hashValue
        if _latestSplitViewStateHash != newHashValue {
            _latestSplitViewStateHash = newHashValue
            // dlog?.info("plitView.StringDesc: \( self.mnSplitView.stringDesc)")
            self.updateSidebarToolbarItems()
            self.updateSidebarMenuItems()
            self.validateToolbarDelegation()
        }
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
