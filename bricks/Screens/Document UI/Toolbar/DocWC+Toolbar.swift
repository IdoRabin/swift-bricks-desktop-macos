//
//  DocWC+Toolbar.swift
//  Bricks
//
//  Created by Ido on 19/12/2021.
//

import AppKit
fileprivate let dlog : DSLogger? = nil // DLog.forClass("DocWC+Toolbar")

// MARK: NSToolbarDelegate
extension DocWC : NSToolbarDelegate {
    
    
    var mainMenu : MainMenu? {
        return BrickDocController.shared.menu
    }
    
    var windowIfLoaded : NSWindow? {
        return self.isWindowLoaded ? self.window : nil
    }
    
    var leadingToggleSidebarItem : MNToggleToolbarItem? {
        return self.windowIfLoaded?.toolbar?.items.first(where: { item in
            item.itemIdentifier == ToolbarItemType.leadingSidebarToggle.asNSToolbarItemID
        }) as? MNToggleToolbarItem
    }
    
    var trailingToggleSidebarItem : MNToggleToolbarItem? {
        return self.windowIfLoaded?.toolbar?.items.first(where: { item in
            item.itemIdentifier == ToolbarItemType.trailingSidebarToggle.asNSToolbarItemID
        }) as? MNToggleToolbarItem
    }
    
    // MARK: Private
    fileprivate enum ToolbarItemType : String {
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
    
    fileprivate func toolbarItem(type : ToolbarItemType)->NSToolbarItem? {
        return toolbarItem(id: type.asNSToolbarItemID)
    }
    
    private func toolbarItem(id:NSToolbarItem.Identifier)->NSToolbarItem? {
        guard self.isWindowLoaded else {
            return nil
        }
        return self.windowIfLoaded?.toolbar?.items.first(where: { item in
            item.itemIdentifier == id
        })
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
    
    private func createToggleSidebarToolbarItem(id:NSToolbarItem.Identifier, isLeading:Bool)->MNToggleToolbarItem {
        let result = MNToggleToolbarItem(itemIdentifier: id)
        if (IS_RTL_LAYOUT ? !isLeading : isLeading) {
            result.onImage = AppImages.sideMenuLeftCollapsed.image
            result.offImage = AppImages.sideMenuLeftUncollapsed.image
        } else {
            result.onImage = AppImages.sideMenuRightCollapsed.image
            result.offImage = AppImages.sideMenuRightUncollapsed.image
        }
        result.imagesScale = 0.43
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
    
    private func createToolbarItem(forCommand:AppCommand.Type)->NSToolbarItem? {
        dlog?.todo("implement createToolbarItem(forCommand:AppCommand.Type)->NSToolbarItem?")
        return nil
    }
    
    // MARK: Delegate implementation
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let id = itemIdentifier
        dlog?.info("toolbar:itemForItemIdentifier \(id)")
        var result : NSToolbarItem? = nil
        let itemType = ToolbarItemType(rawValue: id.rawValue)!
        switch itemType {
        case .leadingSidebarToggle:
            result = self.createToggleSidebarToolbarItem(id: id, isLeading: true)
            result?.target = self.contentViewController
            result?.action = #selector(DocVC.toggleSidebarAction(_:))
            result?.visibilityPriority = .high
            
            // ====== LEADING ===========
        case .leadingSidebarSettings:
            // folder.badge.gearshape
            // doc.badge.gearshape.fill
            // gearshape.fill
            // gearshape
            let symbolN = "wrench.fill"
            result = createToolbarItem(id: id, systemSymbolName: symbolN, accessDesc: AppStr.SETTINGS.localized())
            result?.image = result?.image?.scaledToFit(boundingSizes: 18)?.tinted(.secondaryLabelColor)
            result?.visibilityPriority = .low
            
        case .leadingSidebarCenterSpacer:
            result = createToolbarFlexibleSpace()
            result?.visibilityPriority = .low
            
        case .leadingSidebarStop:
            result = createToolbarItem(id: id, systemSymbolName: "stop.fill", accessDesc: AppStr.STOP_GENERATION_TOOLTIP.localized())
            result?.image = result?.image?.scaledToFit(boundingSizes: 18)?.tinted(.secondaryLabelColor)
            result?.visibilityPriority = .high
            
        case .leadingSidebarPlay:
            result = createToolbarItem(id: id, systemSymbolName: "play.fill", accessDesc: AppStr.GENERATE_TOOLTIP.localized())
            result?.image = result?.image?.scaledToFit(boundingSizes: 18)?.tinted(.secondaryLabelColor)
            result?.visibilityPriority = .high
            
        case .leadingSidebarSeperator:
            let splitView = (self.contentViewController! as? NSSplitViewController)!.splitView
            result = NSTrackingSeparatorToolbarItem(identifier: itemIdentifier, splitView: splitView, dividerIndex: 0)
            
            // ====== CENTER ===========
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
            
            // ====== TRAILING ===========
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
            result = self.createToggleSidebarToolbarItem(id: itemIdentifier, isLeading: false)
            result?.target = self.contentViewController
            result?.action = #selector(DocVC.toggleSidebarAction(_:))
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
    
    // MARK: Public update toolbar calls
    func updateSidebarToolbarItems(isLeadingPanelCollapsed: Bool, isTrailingPanelCollapsed:Bool) {
        self.leadingToggleSidebarItem?.isToggledOn = isLeadingPanelCollapsed
        self.trailingToggleSidebarItem?.isToggledOn = isTrailingPanelCollapsed
    }
    
    func updateToolbarDocNameView() {
        guard let item = self.toolbarItem(type: .centerPaneLeadingDocName), let docNameView = item.view as? DocNameToolbarView else {
            return
        }
        docNameView.updateWithDoc(self.document as? BrickDoc)
    }
     
    func updateToolbarMainPanelView() {
        guard let item = self.toolbarItem(type: .centerPaneCenteredMainPanel), let mainPanelView = item.view as? MainPanelToolbarView else {
            return
        }
        
        // Update sizes if needed
        if let screenW = self.window?.screen?.frame.width, _lastMainPanelScreenW != screenW {
            // Disable prev:
            let conts = mainPanelView.constraintsAffectingLayout(for: .horizontal)
            mainPanelView.removeConstraints(conts)
            
            // Activate new:
            let minWPx = clamp(value: TOOLBAR_MAIN_PANEL_VIEW_MIN_WIDTH_fraction * screenW, lowerlimit: TOOLBAR_MAIN_PANEL_VIEW_MIN_WIDTH_Pixel, upperlimit: screenW - 100)
            let maxWPx = clamp(value: TOOLBAR_MAIN_PANEL_VIEW_MAX_WIDTH_fraction * screenW, lowerlimit: minWPx + 100, upperlimit: screenW - 100)
            
            mainPanelView.widthAnchor.constraint(greaterThanOrEqualToConstant: minWPx).isActive = true
            mainPanelView.widthAnchor.constraint(lessThanOrEqualToConstant: maxWPx).isActive = true
            
        }
//        let TOOLBAR_MAIN_PANEL_VIEW_MIN_WIDTH_fraction : CGFloat = 0.2
//        let TOOLBAR_MAIN_PANEL_VIEW_PREFERRED_WIDTH_fraction : CGFloat = 0.35
//        let TOOLBAR_MAIN_PANEL_VIEW_MAX_WIDTH_fraction : CGFloat = 0.5
        
        mainPanelView.updateWithDoc(self.document as? BrickDoc)
    }
}

// Helper util
fileprivate extension Array where Element == DocWC.ToolbarItemType {
    var asNSToolbarItemIDs : [NSToolbarItem.Identifier] {
        return self.compactMap { itemType in
            itemType.asNSToolbarItemID
        }
    }
}
