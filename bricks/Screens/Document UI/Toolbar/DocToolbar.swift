//
//  DocToolbar.swift
//
//  Created by Ido on 17/11/2021.
//

import Foundation
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocToolbar")

// NSToolbarSidebarTrackingSeparatorItemIdentifier
// NSToolbarToggleSidebarItem
// NSToolbarDelegate

class DocToolbar : NSToolbar {
    
    enum ItemType : String /* IB Identifier */ {
        case infoPanel = "MainPanelToolbaritemID"
        case docPanel = "DocNameToolbarItemID"
        
        case leadingProjectMNToggleItem = "projectToolbarItemID"
        case leadingSidebarSpacer = "projectToolbarItemSpacerID"
        
        case trailingPropertiesMNToggleItem = "propertiesToolbarItemID"
        case trailingSidebarSpacer = "propertiesToolbarItemSpacerID"
        
        case generateItem = "generateToolbarItemID"
        case addItem = "addToolbarItemID"
    }
    
    // MARK: Properties
    private let DEBUG_DRAWING = IS_DEBUG && true
    private static let DEFAULT_BAR_HEIGHT : CGFloat = 35.0
    private static let DEFAULT_ITEMS_HEIGHT : CGFloat = 28.0
    private static let VERTICAL_SIDEBARS_SEPERATOR_W : CGFloat = 2.0
    private weak var vc : DocVC? = nil
    private weak var wc : DocWC? = nil
    private weak var underToolbarLView : NSView? = nil
    private weak var underToolbarRView : NSView? = nil
    var leadingSidebarMNToggleBtn : MNToggleToolbarItem? = nil
    var trailingSidebarMNToggleBtn : MNToggleToolbarItem? = nil
    var leadingSpacer : NSToolbarItem? = nil
    var trailingSpacer : NSToolbarItem? = nil
    var itemsInLeadingPanel : [NSToolbarItem] = []
    var itemsInTrailingPanel : [NSToolbarItem] = []
    private var _isAnimatingSpacers = false
    
    static var TOOLBAR_HEIGHT : CGFloat {
        if let window = DocVC.current?.view.window {
            switch window.toolbarStyle {
            case .unified: return DEFAULT_BAR_HEIGHT + 7.0 // 42.0
            case .unifiedCompact: return DEFAULT_BAR_HEIGHT
            default:
                return DEFAULT_BAR_HEIGHT
            }
        }
        return DEFAULT_BAR_HEIGHT
    }
    
    static var ITEMS_HEIGHT : CGFloat {
        if let window = DocVC.current?.view.window {
            switch window.toolbarStyle {
            case .unified: return DEFAULT_ITEMS_HEIGHT + 4.0 // 32.0
            case .unifiedCompact: return DEFAULT_ITEMS_HEIGHT
            default:
                return DEFAULT_ITEMS_HEIGHT
            }
        }
        return DEFAULT_ITEMS_HEIGHT
    }
    
    // MARK: Private
    private func fittingSizeForItem(_ item:NSToolbarItem)->CGSize {
        var xsize : CGSize = CGSize(width: Self.ITEMS_HEIGHT, height: Self.ITEMS_HEIGHT)
        if let complex = (item.view as? MNToolbarComplexView) {
            xsize.width = max(complex.intrinsicContentSize.width, complex.fittingSize.width)
            xsize.height = Self.ITEMS_HEIGHT
        }
        return xsize
    }
    
    private func addItem(type itemType:ItemType, atIndex index:Int)->NSToolbarItem? {
//        let id =  NSToolbarItem.Identifier(rawValue: itemType.rawValue)
//        let preCount = self.items.count
//        if index <=  preCount {
//            dlog?.info("Adding item: \(itemType) at index:\(index)")
//            self.insertItem(withItemIdentifier: id, at: index)
//            if self.items.count > preCount {
//                let item = self.items[index]
//                item.tag = index
//                let xsize = self.fittingSizeForItem(item)
//                // item.minSize = xsize.adding(widthAdd: -2)
//                // item.maxSize = xsize.adding(widthAdd: 2)
//                item.isBordered = false
//                item.view?.translatesAutoresizingMaskIntoConstraints = false
//                dlog?.info("    addItem: \(itemType) at index: [\(index)] size: \(xsize)")
//                return item
//            } else {
//                dlog?.note("Failed adding item with id: [\(id.rawValue)] into index:\(index) cur count:\(self.items.count) count before:\(preCount)")
//            }
//        } else {
//            dlog?.note("addItem Index \(index) is invalid")
//        }
        return nil
    }
    
    private func whenWindow(_ completion : @escaping (_ window:DocWindow?)->Void){
        waitFor("window", interval: 0.02, timeout: 0.3, testOnMainThread: {
            self.wc?.window != nil && self.vc?.isViewLoaded == true
        }, completion: { waitResult in
            dlog?.successOrFail(condition: waitResult.isSuccess, items: "whenWindow")
            completion(self.wc?.window as? DocWindow)
        }, counter: 1)
    }
    
    fileprivate func setupDebugDrawing() {
        if DEBUG_DRAWING {
            waitFor("", interval: 0.03, timeout: 0.1, testOnMainThread: {
                self.items.count > 0
            }, completion: { waitResult in
                DispatchQueue.mainIfNeeded {
                    for item in self.items {
                        item.view?.wantsLayer = true
                        item.view?.layer?.border(color: .cyan, width: 1)
                    }
                }
            }, counter: 1)
        }
    }
    
    /// Called from external sources to setup the toolbar,  window should set some properties and settings before.
    func setup(windowController:DocWC) {
        self.wc = windowController
        self.vc = windowController.contentViewController as? DocVC
        self.wc?.docToolbar.delegate = self
        
        DispatchQueue.main.performOncePerInstance(self) {
            whenWindow { window in
                if let window = window {
                    window.toolbarStyle = .unifiedCompact
                    window.titleVisibility = .hidden // Will not show the document name and sheets / dropdowns associated
                    window.titlebarAppearsTransparent = true
                    // self.createUnderToolbarWindowViewsIfNeeded()
                    dlog?.info("items == \(self.wc?.docToolbar.items.count ?? 0)")
                    
                    self.setupDebugDrawing()
                }
            }
            
            // Leading sidebar:
//            let projectToggle = self.addItem(type: .leadingProjectMNToggleItem, atIndex: self.items.count) as? MNToggleToolbarItem
//            self.leadingSidebarMNToggleBtn = projectToggle
//
//            // Leading spacer - for "projects" sidebar / panel
//            self.addLeadingSpacer()
//            self._isAnimatingSpacers = true
//
//            // Middle items:
//            let docPanel = self.addItem(type: .docPanel, atIndex: self.items.count)
//            docPanel?.view?.superview?.needsLayout = true
//            self.insertItem(withItemIdentifier: .flexibleSpace, at: self.items.count)
//            let infoPanel = self.addItem(type: .infoPanel, atIndex: self.items.count)
//            self.insertItem(withItemIdentifier: .flexibleSpace, at: self.items.count)
//            infoPanel?.view?.superview?.needsLayout = true
//            infoPanel?.view?.wantsLayer = true
//
//            // Trailing sidebar:
//            // Trailing spacer - for "properties" sidebar / panel
//            self.addTrailingSpacer()
//
//            let propsToggle = self.addItem(type: .trailingPropertiesMNToggleItem, atIndex: self.items.count) as? MNToggleToolbarItem
//            self.trailingSidebarMNToggleBtn = propsToggle
//
//            // Final steps
//            self.setupSidebarButtonSizes()
//            self.setupDebugDrawing()
//            self.setupCaptureWcVc(windowController: windowController) {
//                // Captured WC and VC
//                self.finalizeSetup()
//            }
        }
    }
    
    override init(identifier: NSToolbar.Identifier) {
        super.init(identifier: identifier)
    }
    
}

extension DocToolbar : NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        return super.toolbar(self, itemForItemIdentifier: itemIdentifier, willBeInsertedIntoToolbar: flag)
    }
}
   /*
    
    
    
    // MARK: Private

    
    private func setupCaptureWcVc(windowController:NSWindowController, completion:(()->Void)? = nil) {
        waitFor("setupCaptureWcVc windowController", interval: 0.05, timeout: 0.3, testOnMainThread: {
            (windowController.contentViewController?.isViewLoaded ?? false)
        }, completion: { waitResult in
            DispatchQueue.mainIfNeeded {
                dlog?.successOrFail(condition: waitResult.isSuccess, items: "setupCaptureWcVc")
                if waitResult.isSuccess, let aWC = windowController as? DocWC {
                    self.wc = aWC
                    self.vc = aWC.contentViewController as? DocVC
                }
                
                completion?()
            }
        }, counter: 1)
    }
    
    private func sumFittingSizesIn(_ array: [NSToolbarItem])->CGSize {
        var size : CGSize = CGSize.zero
        for item in array {
            let sze = self.fittingSizeForItem(item)
            size.height = max(sze.height, size.height)
            size.width += sze.width
        }
        let spaces = max(array.count - 1, 0)
        size.width += CGFloat(spaces) * 4.0 // spacing between toolbar items
        return size
    }
    
    // Sidebars vibrancy views:
    private func updateUnderToolbarWindowViews(isLeadingCollaped:Bool, isTrailingCollaped:Bool, animated:Bool) {
        guard let lview = underToolbarLView, let rview = underToolbarRView, let vc = vc else {
            return
        }
        
        // dlog?.info("animating sidebar vibrancy views")
//        let seperatorW : CGFloat = Self.VERTICAL_SIDEBARS_SEPERATOR_W
//        let addX : CGFloat = 1.0
//
//        // Calc new widths
//        let lWid = isLeadingCollaped ? seperatorW : vc.lastLeadingSidebarWidth + addX
//        let rWid = isTrailingCollaped ? seperatorW : vc.lastTrailingSidebarWidth
//
//        if !isLeadingCollaped  { lview.isHidden = false }
//        if !isTrailingCollaped { rview.isHidden = false }
//
//        let lframe : CGRect = lview.frame.changed(x: IS_RTL_LAYOUT ? vc.view.bounds.width - lWid - addX : 0.0, width: lWid)
//        let rframe = rview.frame.changed(x: IS_RTL_LAYOUT ? 0 : vc.view.bounds.width - rWid - addX , width: rWid)
//
//        if animated {
//            lview.animator().frame = lframe
//            lview.animator().alphaValue = isLeadingCollaped ? 0.0 : 1.0
//
//            rview.animator().frame = rframe
//            rview.animator().alphaValue = isTrailingCollaped ? 0.0 : 1.0
//        } else {
//            lview.frame = lframe
//            rview.frame = rframe
//        }
//
//        DispatchQueue.main.asyncAfter(delayFromNow: animated ? 0.2 : 0.01) {
//            lview.isHidden = isLeadingCollaped
//            rview.isHidden = isTrailingCollaped
//        }
    }
    
    
    
    // MARK: Public
    
    func item(id:String)->NSToolbarItem? {
        for item in self.items {
            if item.itemIdentifier.rawValue == id {
                return item
            }
        }
        return nil
    }
    
    func item(typed:ItemType)->NSToolbarItem? {
        return self.item(id: typed.rawValue)
    }
    
    // MARK: Lifecycle

    /// Setup is vslled from outside when window and all the relevant subviews were restored and prepared.
    private func finalizeSetup() {
        if let vc = vc {
            DispatchQueue.mainIfNeeded {
                self._isAnimatingSpacers = false
                self.updateSidebarsToolbarButtons(isLeadingCollapsed: vc.isLeadingSidebarCollapsed,
                                                  isTrailingCollapsed: vc.isTrailingSidebarCollapsed,
                                                  animated: false)
                
                self.updateUnderToolbarWindowViews(animated: false)
            }
        }
    }
    
    fileprivate func setupSidebarButtonSizes() {
        // After all were created:
        
        for item in [self.leadingSidebarMNToggleBtn, self.trailingSidebarMNToggleBtn] {
            if let item = item {
                let isLeading = (item == self.leadingSidebarMNToggleBtn)
                if let btn = item.view as? NSButton {
                    let xsize = self.fittingSizeForItem(item)
                    item.minSize = xsize.adding(widthAdd: -2)
                    item.maxSize = xsize.adding(widthAdd: +2)
                    btn.imagePosition = (isLeading ? .imageLeading : .imageTrailing) // JIC
                    btn.title = ""
                }
            }
        }
    }
    
    func updateDocPanel(doc:BrickDoc) {
//        guard let item = self.item(typed: .docPanel), let docView = item.view as? MNToolbarDocView else {
//            dlog?.note("Could not find docPanel or toolbarItem")
//            return
//        }
//
//        let docName = doc.info?.title ?? doc.lastComponentOfFileName
//        if docView.update(title: docName, subtitle: nil) {
//            // Update the hosting item's sizes
//            item.minSize = CGSize(width: docView.fittingSize.width + 10, height: Self.ITEMS_HEIGHT)
//            item.maxSize = CGSize(width: docView.fittingSize.width + 40, height: Self.ITEMS_HEIGHT)
//        }
    }
    
    func updateInfoPanel(title:String?, progress:CGFloat?) {
        // Tempp
//        guard let item = self.item(typed: .infoPanel), let infoView = item.view as? MainPanelToolbarItem else {
//            let itm = self.item(typed: .infoPanel)
//            dlog?.note("Could not find infoPanel \(itm.descOrNil) or MNToolbarInfoItem: \(itm?.view?.description ?? "<nil>")")
//            return
//        }
//
        // Update title if needed
        // Tempp
//        if infoView.update(title: title, subtitle: nil, progress: progress, leadingImage: nil, trailingImage: nil) {
//            // Update the hosting item's sizes
//            item.minSize = CGSize(width: infoView.fittingSize.width + 10, height: Self.ITEMS_HEIGHT)
//            item.maxSize = CGSize(width: infoView.fittingSize.width + 40, height: Self.ITEMS_HEIGHT)
//        }
    }
    
    private func addLeadingSpacer() {
        let projectSpacer = self.addItem(type: .leadingSidebarSpacer, atIndex: self.items.count)
        projectSpacer?.view?.wantsLayer = true
        projectSpacer?.isBordered = DEBUG_DRAWING
        self.leadingSpacer = projectSpacer
        
        // All the items hosted in the leading panel
        if let spacer = projectSpacer , let index = self.items.firstIndex(of: spacer) {
            self.itemsInLeadingPanel = Array(self.items.prefix(upTo: index))
        }
    }
    
    private func addTrailingSpacer() {
        var idx = self.items.count
        if let btn = self.trailingSidebarMNToggleBtn, let idxxx = self.items.firstIndex(of: btn) {
            idx = idxxx + 1
        }
        let propsSpacer = self.addItem(type: .trailingSidebarSpacer, atIndex: idx)
        propsSpacer?.view?.wantsLayer = true
        propsSpacer?.isBordered = IS_DEBUG
        self.trailingSpacer = propsSpacer
        
        // All the items hosted in the trailing panel
        if let spacer = propsSpacer , let index = self.items.firstIndex(of: spacer) {
            self.itemsInTrailingPanel = Array(self.items.suffix(from: index))
        }
    }
    
    // MARK: Sidebars updates
    
    private func uncollapsedSizeForSpacer(isLeading : Bool)->CGSize {
        var result = CGSize(width: 4.0, height: Self.ITEMS_HEIGHT)
        // tempp
//        if let panel : NSView = isLeading ? self.wc?.docVC?.splitViewItems.first?.viewController.view :  self.wc?.docVC?.splitViewItems.last?.viewController.view {
//            // Panel is not collapsed...
//
//            // the spacer is sized the exact same size as the panel
//            result.width = panel.frame.width
//
//            // Minus all the toolbarItems widths
//            result.width -= self.sumFittingSizesIn(isLeading ? self.itemsInLeadingPanel : self.itemsInTrailingPanel).width
//
//            // Minus window controls [*-+] close, minimize, fulscreen buttons
//            if let window = self.wc?.window {
//                var allWindBtnsW : CGFloat = IS_RTL_LAYOUT ? 9000.0 : 0.0
//                for btnType in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton, .toolbarButton, .documentIconButton] {
//                    if let btn = window.standardWindowButton(btnType) {
//                        if IS_RTL_LAYOUT {
//                            allWindBtnsW = min(allWindBtnsW, btn.frame.minX)
//                        } else {
//                            allWindBtnsW = max(allWindBtnsW, btn.frame.maxX)
//                        }
//                    }
//                }
//
//                // window.contentView?.frame.width ?? self.vc?.view.frame.width ?? NSScreen.main?.frame.width ?? 9000.0
//                if isLeading {
//                    result.width -= allWindBtnsW + 28 // empirical
//                } else {
//                    result.width -= 22 // empirical
//                }
//            }
//        }
        return result
    }
    
    func updateSidebarsToolbarButtons(isLeadingCollapsed:Bool, isTrailingCollapsed:Bool, animated:Bool) {
        // dlog?.info("updateSidebarsToolbarButtons is collaped: L:\(isLeadingCollaped) T:\(isTrailingCollaped) animated:\(animated)")
        guard self._isAnimatingSpacers == false else {
            DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
                self.updateSidebarsToolbarButtons(isLeadingCollapsed:isLeadingCollapsed, isTrailingCollapsed:isTrailingCollapsed, animated:animated)
            }
            return
        }
        self._isAnimatingSpacers = animated
        
        if let leadBtnitem = self.leadingSidebarMNToggleBtn, let trailBtnitem = self.trailingSidebarMNToggleBtn {
            leadBtnitem.isToggledOn = (isLeadingCollapsed == false)
            trailBtnitem.isToggledOn = (isTrailingCollapsed == false)
        }
        
        for item in [self.leadingSpacer, self.trailingSpacer] {
            var newSize = CGSize(width: 4.0, height: Self.ITEMS_HEIGHT)
            var prevSize = CGSize(width: 4.0, height: Self.ITEMS_HEIGHT)
            if let item = item {
                let isLeading = (item == self.leadingSpacer)
                let isCollapsed = (isLeading ? isLeadingCollapsed : isTrailingCollapsed)
                let uncollapsedSize = self.uncollapsedSizeForSpacer(isLeading: isLeading)
                var isChanged = false
                
                if isCollapsed == false {
                    newSize = uncollapsedSize
                    prevSize.width = 4.0
                    isChanged = abs(newSize.width - item.minSize.width) > 4.0
                } else {
                    // Panel is collapsed...
                    newSize.width = 4.0
                    prevSize.width = uncollapsedSize.width
                    isChanged = abs(newSize.width - item.minSize.width) > 4.0
                }

                // After all size changes are done:
                func finalize() {
                    if isCollapsed /* collapsing now from uncollapsed state */ {
                        // We want to hide this item ==> "remove"
                        if let index = self.items.firstIndex(of: item) {
                            self.removeItem(at: index)
                        }
                    }
                }
                
                // Prevent multiple similar changes
                if abs(item.minSize.width - newSize.width) > 2 || (animated && isChanged) {
                    if newSize.width < 0 {
                        newSize.width = 0.0
                    }
                    
                    // We are animating without using any MacOS Voodoo or semi-documented items such as sidebar item idntifier (works for only leading sidebar)
                    // UgBuW - ugly, byt working:
                    if !isCollapsed && self.visibleItems?.contains(item) == false {
                        var index = self.itemsInLeadingPanel.count
                        var type : ItemType = .leadingSidebarSpacer
                        if !isLeading {
                            type = .trailingSidebarSpacer
                            index = self.items.count - self.itemsInTrailingPanel.count
                        }
                        if let spcr = self.addItem(type: type, atIndex:index) {
                            if isLeading {
                                self.leadingSpacer = spcr
                            } else {
                                self.trailingSpacer = spcr
                            }
                        }
                    }
                    
                    let stepsTotalDuration : TimeInterval = 0.19
                    if animated {
                        // TODO: animate constraints instead?
                        let steps = 18
                        let stepDuration = (stepsTotalDuration * 0.97) / TimeInterval(steps)
                        
                        for step in 1...steps {
                            DispatchQueue.main.asyncAfter(delayFromNow: stepDuration * TimeInterval(step)) {
                                let szeW = round(lerp(min: prevSize.width, max: newSize.width, part: Float(step) / Float(steps)))
                                // dlog?.info("isLeading:\(isLeading) szeW:\(szeW) step:\(step)/\(steps) prevSize.W:\(prevSize.width) newSzw.W:\(newSize.width)")
                                item.minSize = prevSize.changed(width: szeW - 2.0)
                                item.maxSize = prevSize.changed(width: szeW + 2.0)
                            }
                        }

                        // After animation is done.
                        DispatchQueue.main.asyncAfter(delayFromNow: stepsTotalDuration + 0.01) {
                            self._isAnimatingSpacers = false
                            finalize()
                        }
                    } else {
                        item.minSize = newSize.changed(width: newSize.width - 2.0)
                        item.maxSize = newSize.changed(width: newSize.width + 2.0)
                        finalize()
                    }
                }
            }
        }
        
        // animate sidebar bkg vibrancy views:
        self.updateUnderToolbarWindowViews(isLeadingCollaped: isLeadingCollapsed, isTrailingCollaped: isTrailingCollapsed, animated: animated)
    }
    
    func updateUnderToolbarWindowViews(animated:Bool) {
        self.updateSidebarsToolbarButtons(isLeadingCollapsed: self.vc?.isLeadingSidebarCollapsed ?? false,
                                          isTrailingCollapsed: self.vc?.isTrailingSidebarCollapsed ?? false,
                                          animated: false)
    }
 
}
 */
