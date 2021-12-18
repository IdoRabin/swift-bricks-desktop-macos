//
//  DocWC.swift
//  Bricks
//
//  Created by Ido on 16/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocWC")

extension NSObject {
    var basicDesc : String {
        return "<\(type(of: self)) \(String(memoryAddressOf: self))>"
    }
}

class DocWC : NSWindowController {
    let DEBUG_DRAWING = IS_DEBUG && true
    let TOOLBAR_MIN_SPACER_WIDTH : CGFloat = 1.0
    let TOOLBAR_ITEMS_HEIGHT : CGFloat = 32
    
    override init(window: NSWindow?) {
        super.init(window: window)
        dlog?.info("init \(basicDesc) window:\(window?.basicDesc ?? "<nil>" )")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        dlog?.info("init w/ coder \(basicDesc) window:\(window?.basicDesc ?? "<nil>" )")
    }
    
    deinit {
        dlog?.info("deinit \(basicDesc)")
    }
    
    func finalizeToolbar() {
        self.window?.toolbar?.items.forEachIndex({ index, item in
            item.tag = index
            if DEBUG_DRAWING, let view = item.view {
                view.wantsLayer = true
                view.layer?.debugBorder(color: .cyan.withAlphaComponent(0.5), width: 1)
            }
        })
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        waitFor("document", interval: 0.05, timeout: 0.2, testOnMainThread: {
            self.document != nil
        }, completion: { waitResult in
            DispatchQueue.mainIfNeeded {
                self.finalizeToolbar()
                
                switch waitResult {
                case .success:
                    dlog?.success("windowDidLoad document:\(self.document.descOrNil) toolbar: \(self.window?.toolbar?.basicDesc ?? "<nil>" ) window: \(self.window?.basicDesc ?? "<nil>" )")
                case .timeout:
                    dlog?.fail("windowDidLoad has no document after loading (waitFor(\"document\") timed out)")
                }
            }
        }, counter: 1)
    }
}

// MARK: NSToolbarDelegate
extension DocWC : NSToolbarDelegate {
    
    // MARK: Private
    enum ToolbarItemType : String {
        // Leading
        case leadingSidebarToggle = "leadingSidebarToggleID"
        case leadingSidebarSettings = "leadingSidebarSettingsID"
        case leadingSidebarCenterSpacer = "leadingSidebarCenterSpacerID"
        case leadingSidebarStop = "leadingSidebarStopID"
        case leadingSidebarPlay = "leadingSidebarPlayID"
        case leadingSidebarSeperator = "leadingSidebarSeperatorID"
        
        // Spacer
        case centerPaneLeadingDocName = "DocNameToolbarItemID"
        case centerPaneLeadingSpacer = "centerPaneLeadingSpacerID"
        case centerPaneCenteredMainPanel = "MainPanelToolbaritemID"
        case centerPaneTrailingSpacer = "centerPaneTrailingSpacerID"
        case centerPaneTrailingPlusAdd = "centerPaneTrailingZID"
        
        // Trailing
        case trailingSidebarSeperator = "trailingSidebarSeperatorID"
        case trailingSidebarX = "trailingSidebarXID"
        case trailingSidebarCenterSpacer = "trailingSidebarCenterSpacerID"
        case trailingSidebarY = "trailingSidebarYID"
        case trailingSidebarToggle = "trailingSidebarToggleID"
        
        static var all : [ToolbarItemType] = [
            // Leading
            .leadingSidebarToggle,
            .leadingSidebarSettings, .leadingSidebarCenterSpacer, .leadingSidebarStop, .leadingSidebarPlay,
            .leadingSidebarSeperator,
            
            // Center
            .centerPaneLeadingDocName, .centerPaneLeadingSpacer, .centerPaneCenteredMainPanel, .centerPaneTrailingSpacer,
            .centerPaneTrailingPlusAdd,
            
            // Trailing
            .trailingSidebarSeperator,
            .trailingSidebarX, .trailingSidebarCenterSpacer, .trailingSidebarY,
            .trailingSidebarToggle
        ]
        
        var asNSToolbarItemID : NSToolbarItem.Identifier {
            return NSToolbarItem.Identifier(rawValue: self.rawValue)
        }
    }
    
    private func createToolbarItemWrappingNib(id:NSToolbarItem.Identifier, nibClass:NSView.Type)->NSToolbarItem {
        let view = nibClass.fromNib()!
        return self.createToolbarItemWrapping(id: id, view: view)
    }
    private func createToolbarItemWrapping(id:NSToolbarItem.Identifier, view:NSView)->NSToolbarItem {
        let result = NSToolbarItem(itemIdentifier: id)
        result.view = view
        return result
    }
    
    private func createToolbarItem(id:NSToolbarItem.Identifier, systemSymbolName:String, accessDesc:String?)->NSToolbarItem {
        let result = NSToolbarItem(itemIdentifier: id)
        result.image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: accessDesc)
        return result
    }
    
    private func createToggleSidebarToolbarItemg(id:NSToolbarItem.Identifier, isLeading:Bool)->MNToggleToolbarItem {
        let result = MNToggleToolbarItem(itemIdentifier: id)
        if (IS_RTL_LAYOUT ? !isLeading : isLeading) {
            result.onImage = AppImages.sideMenuLeftCollapsed.image
            result.offImage = AppImages.sideMenuLeftUncollapsed.image
        } else {
            result.onImage = AppImages.sideMenuRightCollapsed.image
            result.offImage = AppImages.sideMenuRightUncollapsed.image
        }
        result.imagesScale = 0.55
        result.onTint = NSColor.secondaryLabelColor
        result.offTint = NSColor.secondaryLabelColor
        return result
    }
    
    private func createToolbarSingleSpace()->NSToolbarItem {
        return NSToolbarItem(itemIdentifier: .space)
    }
    
    private func createToolbarFlexibleSpace()->NSToolbarItem {
        let result = NSToolbarItem(itemIdentifier: .flexibleSpace)
        let view = NSView(frame: NSRect(origin: .zero, size: CGSize(width: TOOLBAR_MIN_SPACER_WIDTH, height: TOOLBAR_ITEMS_HEIGHT)))
        view.widthAnchor.constraint(lessThanOrEqualToConstant: NSScreen.widest?.frame.width ?? 9000).isActive = true
        view.widthAnchor.constraint(greaterThanOrEqualToConstant: TOOLBAR_MIN_SPACER_WIDTH).isActive = true
        view.heightAnchor.constraint(equalToConstant: TOOLBAR_ITEMS_HEIGHT).isActive = true
        result.view = view
        
        return result
    }
    
    // MARK: Delegate implementation
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let id = itemIdentifier
        dlog?.info("toolbar:itemForItemIdentifier \(id)")
        var result : NSToolbarItem? = nil
        let itemType = ToolbarItemType(rawValue: id.rawValue)!
        switch itemType {
        case .leadingSidebarToggle:
            result = self.createToggleSidebarToolbarItemg(id: id, isLeading: true)
            result?.target = self.contentViewController
            result?.action = #selector(DocVC.toggleSidebarAction(_:))
            
        case .leadingSidebarSettings:
            result = createToolbarItem(id: id, systemSymbolName: "gearshape.fill", accessDesc: AppStr.SETTINGS.localized())
            
        case .leadingSidebarCenterSpacer:
            result = createToolbarFlexibleSpace()
            
        case .leadingSidebarStop:
            result = createToolbarItem(id: id, systemSymbolName: "stop.fill", accessDesc: AppStr.STOP_GENERATION_TOOLTIP.localized())
            
        case .leadingSidebarPlay:
            result = createToolbarItem(id: id, systemSymbolName: "play.fill", accessDesc: AppStr.GENERATE_TOOLTIP.localized())
            
        case .leadingSidebarSeperator:
            let splitView = (self.contentViewController! as? NSSplitViewController)!.splitView
            result = NSTrackingSeparatorToolbarItem(identifier: itemIdentifier, splitView: splitView, dividerIndex: 0)
            
        case .centerPaneLeadingDocName:
            result = createToolbarItemWrappingNib(id: id, nibClass: DocNameToolbarView.self)
            toolbar.centeredItemIdentifier = id
            if let view = result?.view {
                view.widthAnchor.constraint(greaterThanOrEqualToConstant: 120.0).isActive = true
                view.heightAnchor.constraint(equalToConstant: TOOLBAR_ITEMS_HEIGHT).isActive = true
            }
            
        case .centerPaneLeadingSpacer:
            result = createToolbarFlexibleSpace()
            
        case .centerPaneCenteredMainPanel:
            result = createToolbarItemWrappingNib(id: id, nibClass: MainPanelToolbarView.self)
            if let view = result?.view {
                view.widthAnchor.constraint(lessThanOrEqualToConstant: NSScreen.widest?.frame.width ?? 9000).isActive = true
                view.widthAnchor.constraint(greaterThanOrEqualToConstant: TOOLBAR_MIN_SPACER_WIDTH).isActive = true
                view.heightAnchor.constraint(equalToConstant: TOOLBAR_ITEMS_HEIGHT).isActive = true
            }
            
        case .centerPaneTrailingSpacer:
            result = createToolbarFlexibleSpace()
            
        case .centerPaneTrailingPlusAdd:
            result = createToolbarItem(id: id, systemSymbolName: "plus", accessDesc: AppStr.ADD_NEW.localized())
            break
            
        case .trailingSidebarSeperator:
            let splitView = (self.contentViewController! as? NSSplitViewController)!.splitView
            result = NSTrackingSeparatorToolbarItem(identifier: id, splitView: splitView, dividerIndex: 1)
            
        case .trailingSidebarX:
            result = createToolbarItem(id: id, systemSymbolName: "circle.fill", accessDesc: AppStr.ADD_NEW.localized())
            
        case .trailingSidebarCenterSpacer:
            result = createToolbarFlexibleSpace()
            
        case .trailingSidebarY:
            result = createToolbarItem(id: id, systemSymbolName: "circle.empty", accessDesc: AppStr.ADD_NEW.localized())

        case .trailingSidebarToggle:
            result = self.createToggleSidebarToolbarItemg(id: itemIdentifier, isLeading: false)
        }

        return result
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        dlog?.info("toolbarAllowedItemIdentifiers")
        return ToolbarItemType.all.asNSToolbarItemIDs
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        dlog?.info("toolbarDefaultItemIdentifiers")
        return ToolbarItemType.all.asNSToolbarItemIDs
    }
    
    func toolbarWillAddItem(_ notification: Notification) {
        dlog?.info("toolbarWillAddItem at:\(notification.userInfo?["newIndex"] ?? "<nil>") item:\(notification.userInfo?["item"] ?? "<nil>")")
    }
    
    func toolbarDidRemoveItem(_ notification: Notification) {
        dlog?.info("toolbarDidRemoveItem")
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        // dlog?.info("toolbarSelectableItemIdentifiers")
        return []
    }
}

// Helper util
extension Array where Element == DocWC.ToolbarItemType {
    var asNSToolbarItemIDs : [NSToolbarItem.Identifier] {
        return self.compactMap { itemType in
            itemType.asNSToolbarItemID
        }
    }
}
