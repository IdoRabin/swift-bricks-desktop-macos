//
//  DocVC+Toolbar.swift
//  Bricks
//
//  Created by Ido on 13/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocVC+Toolbar")

// NSToolbarSidebarTrackingSeparatorItemIdentifier
// NSToolbarToggleSidebarItem

// MARK: DocVC - Toolbar / NSToolbarDelegate
extension DocVC : NSToolbarDelegate {
    func updateSidebarToolbarItems() {
        
    }
    
    func updateSidebarMenuItems() {
        
    }
    
    var leadingToggleSidebarItem : NSToolbarItem? {
        return nil
    }
    
    var trailingToggleSidebarItem : NSToolbarItem? {
        return nil
    }
}



/*
extension DocVC : NSToolbarDelegate {
    
    // MARK: Properties
    var leadingToggleSidebarItem : NSToolbarItem? {
        guard let toolbar = self.toolbar else {
            return nil
        }
        let item = toolbar.items.first { item in
            item.itemIdentifier == NSToolbarItem.Identifier.toggleSidebar
        }
        return item
    }
    
    var trailingToggleSidebarItem : NSToolbarItem? {
        guard let toolbar = toolbar else {
            return nil
        }
        let item = toolbar.items.last { item in
            item.itemIdentifier == NSToolbarItem.Identifier.toggleSidebar
        }
        return item
    }
    
    // MARK: Private
    enum DToolbarItems : String {
        // Leading
        case leadingSidebarToggle = "leadingSidebarToggleID"
        case leadingSidebarX = "leadingSidebarXID"
        case leadingSidebarCenterSpacer = "leadingSidebarCenterSpacerID"
        case leadingSidebarY = "leadingSidebarYID"
        case leadingSidebarSeperator = "leadingSidebarSeperatorID"
        
        // Spacer
        case centerPaneLeadingDocName = "DocNameToolbarItemID"
        case centerPaneLeadingSpacer = "centerPaneLeadingSpacerID"
        case centerPaneCenteredMainPanel = "MainPanelToolbaritemID"
        case centerPaneTrailingSpacer = "centerPaneTrailingSpacerID"
        case centerPaneTrailingZ = "centerPaneTrailingZID"
        
        // Trailing
        case trailingSidebarSeperator = "trailingSidebarSeperatorID"
        case trailingSidebarX = "trailingSidebarXID"
        case trailingSidebarCenterSpacer = "trailingSidebarCenterSpacerID"
        case trailingSidebarY = "trailingSidebarYID"
        case trailingSidebarToggle = "trailingSidebarToggleID"
        
        static var all : [DToolbarItems] = [.leadingSidebarToggle, .leadingSidebarX, .leadingSidebarCenterSpacer, .leadingSidebarY, .leadingSidebarSeperator, .centerPaneLeadingDocName, .centerPaneLeadingSpacer, .centerPaneCenteredMainPanel, .centerPaneTrailingSpacer, .centerPaneTrailingZ, .trailingSidebarSeperator, .trailingSidebarX, .trailingSidebarCenterSpacer, .trailingSidebarY, .trailingSidebarToggle
        ]
        
        var asNSToolbarItemId : NSToolbarItem.Identifier {
            return NSToolbarItem.Identifier(rawValue: self.rawValue)
        }
        var isSpacer : Bool {
            return self.rawValue.lowercased().contains("spcaer")
        }
    }
    
    private func createToolbarFlexibleSpacingItem(minWidth:CGFloat = 30.0, maxWidth:CGFloat = 1000.0)->NSToolbarItem {
        let result = NSToolbarItem(itemIdentifier: .flexibleSpace)
        let view = NSView(frame: CGRect(origin: .zero, size: CGSize(width: minWidth, height: 30)))
        if DEBUG_DRAWING {
            view.wantsLayer = true
            view.layer?.debugBorder(color: .cyan, width: 1)
        }
        view.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true // min size
        view.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true // max size
        result.view = view
        
        return result
    }
    
    private func createToolbarSingleSpacingItem(width:CGFloat = 30.0)->NSToolbarItem {
        let result = NSToolbarItem(itemIdentifier: .space)
        let view = NSView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: 30)))
        if DEBUG_DRAWING {
            view.wantsLayer = true
            view.layer?.debugBorder(color: .cyan, width: 1)
        }
        view.widthAnchor.constraint(equalToConstant: width).isActive = true // min size
        result.view = view
        return result
    }
    
    private func createToolbarItem(command:DocCommand.Type)->NSToolbarItem {
        let result = MNToolbarItem()
        result.associatedCommand = command
        return result
    }
    
    private func createToolbarToggleItem(command:DocCommand.Type?, identifier:NSToolbarItem.Identifier, setup:(MNToggleToolbarItem)->Void)->NSToolbarItem {
        let item = MNToggleToolbarItem(itemIdentifier: identifier)
        item.tag = self.toolbar?.items.count ?? 0
        setup(item)
        return item
    }
    
    private func createToolbarToggleSidebarItem(isLeading:Bool)->NSToolbarItem {
        
        let result = self.createToolbarToggleItem(command: nil, identifier: .toggleSidebar, setup: { toggleItem in
            toggleItem.fwdAction = #selector(toggleSidebarAction(_:))
            toggleItem.fwdTarget = self
            toggleItem.onImage =  AppImages.bool(isLeading, true: AppImages.sideMenuLeftCollapsed, false: AppImages.sideMenuRightCollapsed).image.tinted(.secondaryLabelColor)
            toggleItem.offImage = AppImages.bool(isLeading, true: AppImages.sideMenuLeftUncollapsed, false: AppImages.sideMenuRightUncollapsed).image.tinted(.secondaryLabelColor)

            toggleItem.onTooltip = AppStr.bool(isLeading, true: .SHOW_PROJECTS_SIDEBAR, false: .SHOW_UTILITY_SIDEBAR).localized()
            toggleItem.offTooltip = AppStr.bool(isLeading, true: .HIDE_PROJECTS_SIDEBAR, false: .HIDE_UTILITY_SIDEBAR).localized()
            toggleItem.imagesScale = 0.55
            toggleItem.onTint = nil
            
            // set menuFormRepresentation for the toolbar item
            if let menuItem = self.mainMenu?.items.filter(idFragments: [[isLeading ? "leading" : "trailing" ,"toggle", "sidebar", "menuitem"]], caseSensitive: false, recursive: true).first {
                dlog?.todo("Create menuFormRepresentation that is similar to the main menu item of:\(menuItem)")
                // toggleItem.menuFormRepresentation = menuItem
            } else {
                dlog?.note("Failed to find menu item for toggle sidebar item: \(toggleItem.onTooltip.descOrNil)")
            }
        })

        return result
    }
    
    private func toolbarItem(type:DToolbarItems, visibleOnly:Bool = false)->NSToolbarItem? {
        guard let items = visibleOnly ?  self.toolbar?.items:  self.toolbar?.visibleItems else {
            return nil
        }
        let tbid = type.asNSToolbarItemId
        var result : NSToolbarItem? = items.first { item in
            item.itemIdentifier == tbid
        }
        if result == nil {
            switch type {
            case .leadingSidebarToggle:  result = leadingToggleSidebarItem
            case .trailingSidebarToggle: result = trailingToggleSidebarItem
                
            default:
                // dlog?.note("failed finding toolbar item for type:\(type)")
                break
            }
        }
        return result
    }
    

    // MARK: Public
    func updateSidebarMenuItems() {
        guard let menu = self.mainMenu else {
            return
        }
        let ids = ["toggleLeadingSidebarMenuItemID", "toggleTrailingSidebarMenuItemID"]
        let menuItems = menu.items.filter(ids: ids, recursive: true)
        menu.updateMenuItems(menuItems, inVC: self)
    }
    
    func updateSidebarToolbarItems() {
        self.updateToolbarItems(array: [.leadingSidebarToggle, .trailingSidebarToggle])
    }
    
    private func updateToolbarItem(type:DToolbarItems) {
        guard let item = self.toolbarItem(type: type) else {
            return
        }
        
        switch type {
        case .leadingSidebarX:
            break
        case .leadingSidebarCenterSpacer:
            break
        case .leadingSidebarY:
            break
        case .leadingSidebarSeperator:
            break
        case .centerPaneLeadingDocName:
            if self.isViewLoaded {
                (item as? DocNameToolbarItem)?.updateWithDoc(self.document)
            }
        case .centerPaneLeadingSpacer:
            break
        case .centerPaneCenteredMainPanel:
            break
        case .centerPaneTrailingSpacer:
            break
        case .centerPaneTrailingZ:
            break
        case .trailingSidebarSeperator:
            break
        case .trailingSidebarX:
            break
        case .trailingSidebarCenterSpacer:
            break
        case .trailingSidebarY:
            break
        case .trailingSidebarToggle:
            
            (self.trailingToggleSidebarItem as? MNToggleToolbarItem)?.isToggledOn = mnSplitView.isTrailingPanelCollapsed
        case .leadingSidebarToggle:
            (self.leadingToggleSidebarItem as? MNToggleToolbarItem)?.isToggledOn = mnSplitView.isLeadingPanelCollapsed
        }
    }
    
    func updateToolbarItems(array:[DToolbarItems]) {
        for type in array {
            self.updateToolbarItem(type: type)
        }
    }
    
    func updateToolbarItems() {
        self.updateToolbarItems(array: DToolbarItems.all)
    }
    
    // MARK: NSToolbarDelegate
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        var result : NSToolbarItem? = nil
        
        if let tbid = DToolbarItems(rawValue: itemIdentifier.rawValue) {
            
            // Leading items:
            switch tbid {
            case .leadingSidebarToggle:
                result = self.createToolbarToggleSidebarItem(isLeading: true)
                
            case .leadingSidebarX:
                
                result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                result?.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)
                result?.title = "X"
                
            case .leadingSidebarCenterSpacer:
                
                result = createToolbarFlexibleSpacingItem()
                
            case .leadingSidebarY:
                result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                result?.image = NSImage(systemSymbolName: "square.fill", accessibilityDescription: nil)
                result?.title = "Y"
                
            case .leadingSidebarSeperator:
                
                //  You must implement this for custom separator identifiers, to connect the separator with a split view divider
                dlog?.info("   leadingSidebarSeperator splitView \(splitView.basicDesc) count:\(splitView.arrangedSubviews.count) dividerIndex: 0")
                result = NSTrackingSeparatorToolbarItem(identifier: .sidebarTrackingSeparator, splitView: splitView, dividerIndex: 0)
                break
                
            // Center items:
            case .centerPaneLeadingDocName:
                 result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                
            case .centerPaneLeadingSpacer:
                result = createToolbarFlexibleSpacingItem()
                
            case .centerPaneCenteredMainPanel:
                
                result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                toolbar.centeredItemIdentifier = tbid.asNSToolbarItemId
                
            case .centerPaneTrailingSpacer:
                result = createToolbarFlexibleSpacingItem()
                
            case .centerPaneTrailingZ:
                result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                result?.image = NSImage(systemSymbolName: "arrow.right", accessibilityDescription: nil)
                result?.title = "PaneTZ"
                
            // Trailing items:
            case .trailingSidebarSeperator:
                //  You must implement this for custom separator identifiers, to connect the separator with a split view divider
                dlog?.info("   trailingSidebarSeperator splitView \(splitView.basicDesc) count:\(splitView.arrangedSubviews.count) dividerIndex: 1")
                 result = NSTrackingSeparatorToolbarItem(identifier: .sidebarTrackingSeparator, splitView: splitView, dividerIndex: 1)
                break
                
            case .trailingSidebarX:
                result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                result?.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)
                result?.title = "TrailX"
                
            case .trailingSidebarCenterSpacer:
                // You must implement this for custom separator identifiers, to connect the separator with a split view divider
                result = createToolbarFlexibleSpacingItem()
                
            case .trailingSidebarY:
                result = NSToolbarItem(itemIdentifier: tbid.asNSToolbarItemId)
                result?.image = NSImage(systemSymbolName: "triangle.fill", accessibilityDescription: nil)
                result?.title = "TrailY"
            
            case .trailingSidebarToggle:
                result = self.createToolbarToggleSidebarItem(isLeading: false)
            }
            
            // Set tag
            let tagNr = DToolbarItems.all.firstIndex(of: tbid) ?? 0
            result?.tag = tagNr
            
        } else {
            dlog?.note("Unknown toolbar item id: \(itemIdentifier.rawValue)")
        }
        
        // dlog?.successOrFail(condition: result != nil,items:"itemForItemIdentifier \(itemIdentifier.rawValue) \(result?.itemIdentifier.rawValue ?? "<nil>")")
        if IS_DEBUG && result != nil {
            DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
                if self.DEBUG_DRAWING {
                    result?.view?.wantsLayer = true
                    result?.view?.layer?.debugBorder(color: .cyan, width: 1)
                }
            }
        }
        return result
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return DToolbarItems.all.compactMap { item in
            item.asNSToolbarItemId
        }
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return DToolbarItems.all.compactMap { item in
            item.asNSToolbarItemId
        }
    }
    
}
*/
