//
//  ProjectTabsVC.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//

import AppKit
fileprivate let dlog : DSLogger? = DLog.forClass("ProjctTabsVC")

class ProjectTabsVC : NSTabViewController {
    
    // MARK: Constants
    let DEBUG_DRAWING = IS_DEBUG && true
    let DEBUG_DRAW_ORIG_TABS = IS_DEBUG && false
    
    // MARK: Enums
    enum Tabs : Int, Codable {
    case project = 0
    case progress = 1
    case tasks = 2
        var imageName : String {
            switch self {
            case .project:  return "folder"
            case .progress: return "ruler"
            case .tasks:    return "checkmark.square"
            }
        }
        
        var desc : String {
            switch self {
            case .project:  return AppStr.PROJECT.localized()
            case .progress: return AppStr.PROGRESS.localized()
            case .tasks:    return AppStr.TASKS.localized()
            }
        }
        
        var alternateImageName : String {
            return imageName.appending(".fill")
        }
        
        var image : NSImage? {
            return NSImage(systemSymbolName: self.imageName, accessibilityDescription: self.desc)
        }
        
        var alternateImage : NSImage? {
            let result = NSImage(systemSymbolName: self.alternateImageName, accessibilityDescription: self.desc)
            return result?.tinted(NSColor.controlAccentColor)
        }
    }
    
    // MARK: Properties
    weak var stackView : NSStackView? = nil
    weak var segmentedTabs : MNSegmentedTabs? = nil
    
    // MARK: Computed vars
    var doc : BrickDoc? {
        return docWC?.document as? BrickDoc
    }
    var docWC : DocWC? {
        return (self.view.window?.windowController as? DocWC)
    }
    
    // MARK: private Properties
    // MARK: Private funcs
    private func createSegmentedTabs() {
        if let segmented = tabView.segmentedControl {
            segmented.focusRingType = .none
            
            // Hide or draw the "native" tabView.segmentedControl:
            segmented.isHidden = DEBUG_DRAW_ORIG_TABS == false
            
            // See where the original segmented thing is hidden:
            if DEBUG_DRAW_ORIG_TABS {
                segmented.wantsLayer = true
                segmented.layer?.backgroundColor = NSColor.purple.withAlphaComponent(0.3).cgColor
            }
            
            waitFor("segmented window", testOnMainThread: {
                segmented.window != nil
            }, completion: { waitResult in
                DispatchQueue.mainIfNeeded {
                    // Create an MNSegmentedTabs view to replace the native segmented view:
                    let hgt = max(segmented.frame.height, MNSegmentedTabs.bestHeight)
                    let toolbarHeight = (self.docWC?.TOOLBAR_HEIGHT ?? 38.0) // Empirical
                    let frm = self.view.bounds.changed(y:self.view.bounds.height - hgt - toolbarHeight,
                                                       height: max(hgt, 26))
                    let mnSegmentedTabs = MNSegmentedTabs(frame: frm)
                    mnSegmentedTabs.observers.add(observer: self)
                    mnSegmentedTabs.orientation = .horizontal
                    mnSegmentedTabs.alignment = .centerY
                    mnSegmentedTabs.distribution = .equalCentering
                    mnSegmentedTabs.focusRingType = .none
                    mnSegmentedTabs.edgeInsets = NSEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
                    mnSegmentedTabs.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin]
                    mnSegmentedTabs.seperatorSide = .bottom
                    self.view.addSeparatorView(side: .top, addDelta: toolbarHeight)
                    //self.tabView.additionalSafeAreaInsets = NSEdgeInsets(top: toolbarHeight, left: 0, bottom: 0, right: 0)
                    
                    if self.DEBUG_DRAWING {
                        // mnSegmentedTabs.border(color: .red.withAlphaComponent(0.4), width: 1)
                    }
                    
                    self.view.addSubview(mnSegmentedTabs)
                    self.segmentedTabs = mnSegmentedTabs
                    
                    // Create a button for each tab:
                    for index in 0..<segmented.segmentCount {
                        let tab = Tabs(rawValue: index)!
                        mnSegmentedTabs.addTab(isSelected: (segmented.selectedSegment == index),
                                               image: tab.image!,
                                               selectedImage: tab.alternateImage!,
                                               tooltip: tab.desc)
                    }
                    
                    // Set selected index
                    self.segmentedTabs?.selectedIndex = self.selectedTabViewItemIndex
                }
            }, counter: 0)
        }
    }
    
    private func setup() {
        self.canPropagateSelectedChildViewControllerTitle = false
        self.tabView.tabViewBorderType = .none
        self.tabView.tabViewType = .noTabsNoBorder
        self.tabView.drawsBackground = false
        self.tabStyle = .segmentedControlOnTop
        self.tabView.focusRingType = .none
        for tabvi in tabViewItems {
            tabvi.label = ""
        }
        
        self.createSegmentedTabs()
        DispatchQueue.main.async {[self] in
            if let seg = segmentedTabs, seg.selectedIndex == -1 {
                segmentedTabs?.selectedIndex = self.selectedTabViewItemIndex
            }
        }

        // Add this VC to registration
        // XPDocWC.registerWeakVCInstance(vc: self, inView: self.view)
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: NSTabViewDelegate
    /* Implemented methods from NSTabViewDelegate. These require a call to super if overriden by a subclass. */
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
    }

    override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        super.tabView(tabView, shouldSelect: tabViewItem)
    }
    
    // MARK: Public funcs
}


extension ProjectTabsVC : MNSegmentedTabObserver {
    func mnSegmentedTabs(_ self: MNSegmentedTabs, selctedTabDidChange index: Int) {
        // Selected tab changed
        dlog?.info("MNSegmentedTabs selctedTabDidChange: \(index)")
        
        self.selectedIndex = index
        tabView.selectTabViewItem(at: index)
    }
}



extension NSTabView {
    var segmentedControl : NSSegmentedControl? {
        for view in self.superview?.subviews ?? [] {
            if let segmented = view as? NSSegmentedControl {
                return segmented
            }
        }
        return nil
    }
}
