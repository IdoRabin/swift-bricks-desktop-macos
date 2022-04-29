//
//  MNTabViewController.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//

import AppKit

// fileprivate let dlog : DSLogger? = DLog.forClass("MNTabViewController")

// Better create a private Enum called "Tabs" in the subclass : Int
//
protocol MNTabViewControllerEnumable {
    var imageName : String { get }
    var alternateImageName : String { get }
    var image : NSImage? { get }
    var alternateImage : NSImage? { get }
    var displayName : String { get }
    static var all : [Self]  { get }
    
    // RawRepresentable<Int>
    var rawValue : Int { get }
    init?(rawValue:Int)
}

extension MNTabViewControllerEnumable {
    var image : NSImage? {
        return NSImage(systemSymbolName: self.imageName, accessibilityDescription: self.displayName) ?? NSImage(named: self.imageName)
    }
    
    var alternateImage : NSImage? {
        return (NSImage(systemSymbolName: self.alternateImageName, accessibilityDescription: self.displayName) ?? NSImage(named: self.alternateImageName))?.tinted(NSColor.controlAccentColor)
    }
}

// This is supposed to be an "abstract" parent to be subclassed. Will raise exceptions in places requiring overrides.
class MNTabViewController : NSTabViewController {
    // MARK: Constants
    private let DEBUG_DRAWING = IS_DEBUG && false
    private let DEBUG_DRAW_ORIG_TABS = IS_DEBUG && false
    
    lazy var dlog : DSLogger? = {
        return DLog.forClass("\(type(of: self))")
    }()
    
    // MARK: Properties
    weak var segmentedTabs : MNSegmentedTabs? = nil
    
    private var toolbarHeight : CGFloat {
        // Override point
        return 38.0
    }
    
    // MARK: REQUIRED OVERRIDES
    var tabsType : MNTabViewControllerEnumable.Type {
        dlog?.raisePreconditionFailure("tabsType requires implementation in MNTabViewController subclass \(type(of: self))")
        preconditionFailure()
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
                    let hgt = max(max(segmented.frame.height, MNSegmentedTabs.bestHeight), 26)
                    let allIconsWidth = CGFloat(segmented.segmentCount) * (hgt/* width of each icon, assumed to be similar to the height */ + 2/* spacing*/)
                    
                    let toolbarHeight = self.toolbarHeight
                    let frm = self.view.bounds.changed(y:self.view.bounds.height - hgt - 1,
                                                       width: allIconsWidth + 20,
                                                       height: hgt)
                    let mnSegmentedTabs = MNSegmentedTabs(frame: frm)
                    mnSegmentedTabs.observers.add(observer: self)
                    mnSegmentedTabs.orientation = .horizontal
                    mnSegmentedTabs.alignment = .centerY
                    mnSegmentedTabs.distribution = .equalCentering
                    mnSegmentedTabs.focusRingType = .none
                    mnSegmentedTabs.edgeInsets = NSEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
                    // -- mnSegmentedTabs.autoresizingMask = [.minYMargin, .height]
                    mnSegmentedTabs.translatesAutoresizingMaskIntoConstraints = false
                    self.view.addSeparatorView(side: .top, addDelta: 0)
                    self.view.addSeparatorView(side: .top, addDelta: toolbarHeight - 4, clearingPrevious: false)
                    if self.DEBUG_DRAWING {
                        mnSegmentedTabs.border(color: .red.withAlphaComponent(0.2), width: 1)
                    }
                    
                    self.view.addSubview(mnSegmentedTabs)
                    self.segmentedTabs = mnSegmentedTabs
                    // mnSegmentedTabs.removeConstraints(mnSegmentedTabs.constraintsAffectingLayout(for: .horizontal))
                    mnSegmentedTabs.heightAnchor.constraint(equalToConstant: hgt).isActive = true
                    mnSegmentedTabs.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                    mnSegmentedTabs.widthAnchor.constraint(equalToConstant: allIconsWidth).isActive = true
                    mnSegmentedTabs.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                    
                    // Create a button for each tab:
                    if segmented.segmentCount != self.tabsType.all.count {
                        self.dlog?.raisePreconditionFailure("\(type(of: self)).\(self.tabsType).all MUST have the same amount of elements \(self.tabsType.all.count) as the segmented control \(segmented.segmentCount) (the NSTabViewController tabs count..) required by MNTabViewController.")
                        preconditionFailure()
                    }
                        
                    for index in 0..<segmented.segmentCount {
                        let tab = self.tabsType.init(rawValue: index)!
                        mnSegmentedTabs.addTab(isSelected: (segmented.selectedSegment == index),
                                               image: tab.image!,
                                               selectedImage: tab.alternateImage!,
                                               tooltip: tab.displayName)
                    }
                    
                    // Set selected index
                    let selectedIndex = self.selectedTabViewItemIndex
                    let oppositeIndex = (selectedIndex == 0) ? 1 : 0
                    self.segmentedTabs?.selectedIndex = oppositeIndex
                    DispatchQueue.main.async {
                        self.segmentedTabs?.selectedIndex = selectedIndex
                        mnSegmentedTabs.needsLayout = true
                        mnSegmentedTabs.needsDisplay = true
                    }
                }
            }, logType: .allAfterFirstTest)
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
    
}

extension MNTabViewController : MNSegmentedTabObserver {
    func mnSegmentedTabs(_ self: MNSegmentedTabs, selctedTabDidChange index: Int) {
        // Selected tab changed
        dlog?.info("main tab changed: \(index)")
        
        self.selectedIndex = index
        tabView.selectTabViewItem(at: index)
    }
}
