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
    
    override func windowDidLoad() {
        super.windowDidLoad()
        waitFor("document", interval: 0.05, timeout: 0.2, testOnMainThread: {
            self.document != nil
        }, completion: { waitResult in
            DispatchQueue.mainIfNeeded {
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
        case leadingSidebarX = "leadingSidebarXID"
        case leadingSidebarCenterSpacer = "leadingSidebarCenterSpacerID"
        case leadingSidebarStop = "leadingSidebarStopID"
        case leadingSidebarPlay = "leadingSidebarPlayID"
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
        
        static var all : [ToolbarItemType] = [
            // Leading
            .leadingSidebarToggle,
            .leadingSidebarX, .leadingSidebarCenterSpacer, .leadingSidebarY,
            .leadingSidebarSeperator,
            
            // Center
            .centerPaneLeadingDocName, .centerPaneLeadingSpacer, .centerPaneCenteredMainPanel, .centerPaneTrailingSpacer,
            .centerPaneTrailingZ,
            
            // Trailing
            .trailingSidebarSeperator,
            .trailingSidebarX, .trailingSidebarCenterSpacer, .trailingSidebarY,
            .trailingSidebarToggle
        ]
        
        var asNSToolbarItemID : NSToolbarItem.Identifier {
            return NSToolbarItem.Identifier(rawValue: self.rawValue)
        }
    }
    
    private func createToolbarItemWrapping(id:NSToolbarItem.Identifier, view:NSView)->NSToolbarItem {
        let result = NSToolbarItem(itemIdentifier: id)
        result.view = view
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
    
    // MARK: Delegate implementation
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        dlog?.info("toolbar:itemForItemIdentifier \(itemIdentifier.rawValue)")
        var result : NSToolbarItem? = nil
        let itemType = ToolbarItemType(rawValue: itemIdentifier.rawValue)!
        switch itemType {
        case .leadingSidebarToggle:
            result = self.createToggleSidebarToolbarItemg(id: itemIdentifier, isLeading: true)
            
        case .leadingSidebarX:
            break
        case .leadingSidebarCenterSpacer:
            break
        case .leadingSidebarY:
            break
        case .leadingSidebarSeperator:
            let splitView = (self.contentViewController! as? NSSplitViewController)!.splitView
            result = NSTrackingSeparatorToolbarItem(identifier: itemIdentifier, splitView: splitView, dividerIndex: 0)
            
        case .centerPaneLeadingDocName:
            break
        case .centerPaneLeadingSpacer:
            break
        case .centerPaneCenteredMainPanel:
            break
        case .centerPaneTrailingSpacer:
            break
        case .centerPaneTrailingZ:
            break
        case .trailingSidebarSeperator:
            let splitView = (self.contentViewController! as? NSSplitViewController)!.splitView
            result = NSTrackingSeparatorToolbarItem(identifier: itemIdentifier, splitView: splitView, dividerIndex: 1)
            
        case .trailingSidebarX:
            break
        case .trailingSidebarCenterSpacer:
            break
        case .trailingSidebarY:
            break
        case .trailingSidebarToggle:
            result = self.createToggleSidebarToolbarItemg(id: itemIdentifier, isLeading: false)
        }

        return result
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        dlog?.info("toolbarAllowedItemIdentifiers")
        return [] // ToolbarItemType.all.asNSToolbarItemIDs
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
        dlog?.info("toolbarSelectableItemIdentifiers")
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
