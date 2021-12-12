//
//  DocumentVC.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocumentVC")

class DocumentVC : NSSplitViewController {
    private let DEBUG_DRAWING = IS_DEBUG && true
    
    fileprivate var cache = Cache<NSToolbarItem.Identifier,NSToolbarItem>(name: "itemsCach", maxSize: 200, flushToSize: 100)
    
    var mnSplitView: MNSplitview {
        return super.splitView as! MNSplitview
    }
    
    // MARK: Private
    private func setup() {
        self.setupToolbarIfPossible()
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        dlog?.info("viewDidLoad for docVC: [\(self.title.descOrNil)]")
    }
    
    deinit {
        dlog?.info("deinit for docVC: [\(self.title.descOrNil)]")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.setupToolbarIfPossible()
        self.updateToolbarItems()
    }
}


// MARK: DocumentVC - Actions
extension DocumentVC /* Actions */ {
    
    var toolbar : NSToolbar? {
        return self.view.window?.toolbar
    }
    
    var mainMenu : MainMenu? {
        return BrickDocController.shared.menu
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return true
    }
    
    private var leadingToggleSidebarItem : NSToolbarItem? {
        guard let toolbar = self.toolbar else {
            return nil
        }
        let item = toolbar.items.first { item in
            item.itemIdentifier == NSToolbarItem.Identifier.toggleSidebar
        }
        return item
    }
    
    private var trailingToggleSidebarItem : NSToolbarItem? {
        guard let toolbar = toolbar else {
            return nil
        }
        let item = toolbar.items.last { item in
            item.itemIdentifier == NSToolbarItem.Identifier.toggleSidebar
        }
        return item
    }
    
    @IBAction @objc func toggleSidebarAction(_ sender : Any) {
        super.toggleSidebar(sender)
        
        DispatchQueue.main.async {
            var sendr = sender
            if let btn = sender as? NSButton {
                if let lft = self.leadingToggleSidebarItem,
                    lft.view == btn || btn.tag <= self.mnSplitView.leadingDividerIndex {
                    // Found leading
                    sendr = lft
                } else if let rgt = self.trailingToggleSidebarItem,
                          rgt.view == btn || btn.tag >= self.mnSplitView.trailingDividerIndex {
                    // Found trailing
                    sendr = rgt
                }
            }
            
            switch sendr {
            case let _ as MNToggleToolbarItem:
                // let isCollapsed = (item.tag < 2) ? mnSplitView.isLeadingPanelCollapsed : mnSplitView.isTrailingPanelCollapsed
                // item.isToggledOn = !isCollapsed
                // dlog?.info("toggleSidebarAction toolbar item: \(item.itemIdentifier.rawValue) isCollapsed:\(isCollapsed)")
                self.updateSidebarToolbarItems()
                
            case let item as NSToolbarItem:
                dlog?.info("toggleSidebarAction toolbar item: \(item.itemIdentifier.rawValue)")
            case let item as NSMenuItem:
                switch item {
                case self.leadingToggleSidebarItem?.menuFormRepresentation, self.trailingToggleSidebarItem?.menuFormRepresentation:
                    self.updateSidebarToolbarItems()
                default:
                    break
                }
            default:
                dlog?.note("toggleSidebarAction sender: \(sender)")
            }
        }

    }
    
}

// MARK: DocumentVC - Toolbar / NSToolbarDelegate
extension DocumentVC : NSToolbarDelegate {
    
    enum DToolbarItems : String {
        // Leading
        case leadingSidebarToggle = "leadingSidebarToggleID"
        case leadingSidebarX = "leadingSidebarXID"
        case leadingSidebarCenterSpacer = "leadingSidebarCenterSpacerID"
        case leadingSidebarY = "leadingSidebarYID"
        case leadingSidebarSeperator = "leadingSidebarSeperatorID"
        
        // Spacer
        case centerPaneLeadingX = "centerPaneLeadingXID"
        case centerPaneLeadingSpacer = "centerPaneLeadingSpacerID"
        case centerPaneCenteredY = "centerPaneCenteredYID"
        case centerPaneTrailingSpacer = "centerPaneTrailingSpacerID"
        case centerPaneTrailingZ = "centerPaneTrailingZID"
        
        // Trailing
        case trailingSidebarSeperator = "trailingSidebarSeperatorID"
        case trailingSidebarX = "trailingSidebarXID"
        case trailingSidebarCenterSpacer = "trailingSidebarCenterSpacerID"
        case trailingSidebarY = "trailingSidebarYID"
        case trailingSidebarToggle = "trailingSidebarToggleID"
        
        var asNSToolbarItemId : NSToolbarItem.Identifier {
            return NSToolbarItem.Identifier(rawValue: self.rawValue)
        }
    }
    
    // NSToolbarSidebarTrackingSeparatorItemIdentifier
    // NSToolbarToggleSidebarItem
    fileprivate func updateSidebarToolbarItems() {
        // dlog?.info("leadingToggleSidebarItem: \(self.leadingToggleSidebarItem.descOrNil)")
        // dlog?.info("trailingToggleSidebarItem: \(self.trailingToggleSidebarItem.descOrNil)")
        if let leading = self.leadingToggleSidebarItem as? MNToggleToolbarItem {
            let isCollapsed = mnSplitView.isLeadingPanelCollapsed
            dlog?.info("leading isCollapsed \(isCollapsed)")
            leading.isToggledOn = isCollapsed
        } else {
            dlog?.note("FAILED finding leadingToggleSidebarItem!")
        }

//        if let trailing = self.trailingToggleSidebarItem as? MNToggleToolbarItem {
//            let isCollapsed = mnSplitView.isTrailingPanelCollapsed
//            dlog?.info("trailing isCollapsed \(isCollapsed)")
//            trailing.isToggledOn = !isCollapsed
//        } else {
//            dlog?.note("FAILED finding trailingToggleSidebarItem!")
//        }
    }
    
    fileprivate func updateToolbarItems() {
        self.updateSidebarToolbarItems()
    }
    
    fileprivate func setupToolbarIfPossible() {
        guard self.isViewLoaded, let toolbar = self.view.window?.toolbar, toolbar.items.count == 0 else  {
            return
        }

        toolbar.delegate = self
        DispatchQueue.main.performOncePerInstance(self) {
            dlog?.info("setupToolbarIfPossible")

            let items : [DToolbarItems] = [
                // Leading
                .leadingSidebarToggle,
                //.leadingSidebarX,
                //.leadingSidebarCenterSpacer,
                //.leadingSidebarY,
                // .leadingSidebarSeperator,

                // Spacer
//                .centerPaneLeadingX,
//                .centerPaneLeadingSpacer,
//                .centerPaneCenteredY,
//                .centerPaneTrailingSpacer,
//                .centerPaneTrailingZ,
//
//                // Trailing
//                .trailingSidebarSeperator
//                .trailingSidebarX,
//                .trailingSidebarCenterSpacer,
//                .trailingSidebarY,
//                .trailingSidebarToggle,
            ]

            items.forEachIndex { index, ditem in
                dlog?.info("Adding item #\(index) ditem: \(ditem) ")
                let identifier = NSToolbarItem.Identifier(ditem.rawValue)
                let cnt = toolbar.items.count
                if cnt != index {
                    dlog?.note("Adding item failed at index: #\(index)")
                }
                toolbar.insertItem(withItemIdentifier: identifier, at: cnt)
            }
            
            // After all were added
            DispatchQueue.main.async {
                self.updateToolbarItems()
            }
        }
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        var result : NSToolbarItem? = nil
        
        if let tbid = DToolbarItems(rawValue: itemIdentifier.rawValue) {
            switch tbid {
            case .leadingSidebarToggle:
                let item = MNToggleToolbarItem(itemIdentifier: .toggleSidebar)
                item.fwdAction = #selector(toggleSidebarAction(_:))
                item.fwdTarget = self
                item.onImage = AppImages.sideMenuLeftCollapsed.image.tinted(.secondaryLabelColor)
                item.offImage = AppImages.sideMenuLeftUncollapsed.image.tinted(.secondaryLabelColor)
                item.imagesScale = 0.55
                
                // toggleLeadingSidebarMenuItemID
                item.menuFormRepresentation = mainMenu?.items(withIdFragments: ["toggle", "sidebar", "leading", "menuitem"], caseSensitive: false).first
                item.onTint = nil
                result = item
                
            case .leadingSidebarX:
                
                result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                result?.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)
                result?.title = "X"
                
            case .leadingSidebarCenterSpacer:
                
                result = NSToolbarItem(itemIdentifier: .flexibleSpace)
//                let view = NSView(frame: NSRect(origin: .zero, size: CGSize(width: 32, height: 32)))
//                view.autoresizingMask = [.width]
                result?.view = view
                
            case .leadingSidebarY:
                result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                result?.image = NSImage(systemSymbolName: "square.fill", accessibilityDescription: nil)
                result?.title = "Y"
                
            case .leadingSidebarSeperator:
                
                // You must implement this for custom separator identifiers, to connect the separator with a split view divider
//                result = NSTrackingSeparatorToolbarItem(identifier: .sidebarTrackingSeparator, splitView: splitView, dividerIndex: 0)
                break
            case .centerPaneLeadingX:
                // result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                // result?.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
                // result?.title = "PaneLX"
                break
            case .centerPaneLeadingSpacer:
                break
            case .centerPaneCenteredY:
                // result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                // result?.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
                // result?.title = "PaneCY"
                break
            case .centerPaneTrailingSpacer:
                break
            case .centerPaneTrailingZ:
                break
            case .trailingSidebarToggle:
                
                // item.view?.tag = toolbar.items.count // button tag
                // toggleTrailingSidebarMenuItemID
                // item.menuFormRepresentation = mainMenu?.items(withIdFragments: ["toggle", "sidebar", "trailing", "menuitem"], caseSensitive: false).first
                // self.updateSidebarToolbarItems()
                
                break
            case .trailingSidebarX:
                break
            case .trailingSidebarCenterSpacer:
                // You must implement this for custom separator identifiers, to connect the separator with a split view divider
                // return NSTrackingSeparatorToolbarItem(identifier: itemIdentifier, splitView: splitView, dividerIndex: 3)
                break
            case .trailingSidebarY:
                break
            case .trailingSidebarSeperator:
                break
            }
        } else {
            dlog?.note("Unknown toolbar item id: \(itemIdentifier.rawValue)")
        }
        
        dlog?.successOrFail(condition: result != nil,items:"itemForItemIdentifier \(itemIdentifier.rawValue) \(result?.itemIdentifier.rawValue ?? "<nil>")")
        if IS_DEBUG && result != nil {
            DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
                result?.view?.wantsLayer = true
                result?.view?.layer?.border(color: .cyan, width: 1)
            }
        }
        return result
    }
}
