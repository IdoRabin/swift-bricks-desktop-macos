//
//  MNSegmentedTabs.swift
//  XPlan
//
//  Created by Ido on 28/10/2021.
//

import Foundation
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("MNSegmentedTabs")

protocol MNSegmentedTabObserver {
    
    /// Notiofication that the tab index has changes.
    func mnSegmentedTabs(_ self: MNSegmentedTabs, selctedTabDidChange:Int)
}

class MNSegmentedTabs : NSView {
    struct TabInfo {
        let image: NSImage
        let selectedImage: NSImage
        let tooltip : String
    }
    
    enum Behavior {
        case segmentedControl
        case toolbar
    }
    
    var behavior : Behavior = .segmentedControl {
        didSet {
            if oldValue != behavior {
                self.selectedIndex = -1
            }
        }
    }
    
    let DEBUG_DRAWING = IS_DEBUG && false
    
    weak var stackView : NSStackView? = nil
    static let minTabWidth : CGFloat = 30.0
    static let bestHeight : CGFloat = 30.0
    
    private var _minTabWidth : CGFloat = 30.0
    @IBInspectable var minTabWidth : CGFloat {
        get {
            return self._minTabWidth
        }
        set {
            self._minTabWidth = newValue
        }
    }
    
    let observers = ObserversArray<MNSegmentedTabObserver>()
    private var _selectedImages : [NSImage] = []
    private var _images : [NSImage] = []
    private var _isEnabled: [Int:Bool] = [:] // defaults to true when no item
    
    var tabCount : Int {
        return stackView?.arrangedSubviews.count ?? 0
    }
    
    private var _selectedIndex : Int = -1
    var selectedIndex : Int {
        get {
            return _selectedIndex
        }
        set {
            if newValue != _selectedIndex {
                _selectedIndex = newValue
                
                // Notify observers of selected index change
                self.observers.enumerateOnMainThread { observer in
                    observer.mnSegmentedTabs(self, selctedTabDidChange: newValue)
                }
                
                self.updateTabs(selectedIndex: newValue)
            }
        }
    }
    
    var seperatorSide : SeparatorSide? {
        didSet {
            self.clearSeperators()
            if let sep = self.seperatorSide {
                let _ /*sepView*/ = self.addSeparatorView(side: sep)
            }
        }
    }
    
    
    var arrangedSubviews : [NSView] {
        return stackView?.arrangedSubviews ?? []
    }
    
    private var _spacing : CGFloat = 0.0
    @IBInspectable var spacing : CGFloat {
        get {
            return _spacing
        }
        set {
            stackView?.spacing = newValue
            _spacing = newValue
        }
    }
    
    private var _alignment : NSLayoutConstraint.Attribute = .leading
    @IBInspectable var alignment : NSLayoutConstraint.Attribute {
        get {
            return _alignment
        }
        set {
            stackView?.alignment = newValue
            self._alignment = newValue
        }
    }
    
    private var _distribution : NSStackView.Distribution = .fill
    @IBInspectable var distribution : NSStackView.Distribution {
        get {
            return _distribution
        }
        set {
            stackView?.distribution = newValue
            _distribution = newValue
        }
    }
    
    private var _edgeInsets : NSEdgeInsets = NSEdgeInsetsZero
    @IBInspectable var edgeInsets : NSEdgeInsets {
        get {
            return _edgeInsets
        }
        set {
            stackView?.edgeInsets = newValue
            _edgeInsets = newValue
        }
    }
    
    private var _orientation : NSUserInterfaceLayoutOrientation = .horizontal
    @IBInspectable var orientation : NSUserInterfaceLayoutOrientation {
        get {
            return _orientation
        }
        set {
            _orientation = newValue
            stackView?.orientation = newValue
        }
    }
    
    override var fittingSize: NSSize {
        return CGSize(width: Int(ceil(self.calcedTotalWidth())), height: Int(ceil(self.bounds.height)))
    }
    
    private func setup(frameRect: NSRect) {
        let stack = NSStackView(frame: frameRect.size.zeroOriginRect().center.rectAroundCenter(width: 4, height: self.bounds.height - 4))
        stack.orientation = self._orientation
        stack.spacing = self._spacing
        stack.alignment = self._alignment
        stack.distribution = self._distribution
        stack.edgeInsets = self._edgeInsets
        stack.autoresizingMask = [.width, .height]
        self.addSubview(stack)
        stack.needsLayout = true
        self.needsLayout = true
        self.stackView = stack
        
        if DEBUG_DRAWING {
            stack.wantsLayer = true
            stack.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.2).cgColor
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup(frameRect: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(frameRect: self.frame)
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        
        self.needsLayout = true
        self.updateTabs(selectedIndex: self.selectedIndex)
        
        DispatchQueue.main.performOncePerSession {
            if let side = self.seperatorSide {
                self.addSeparatorView(side: side)
            }
            if DEBUG_DRAWING {
                self.debugAddBkg()
            }
        }
        
    }
    
    private func updateStackView() {
        guard self.superview != nil else {
            dlog?.note("updateStackView not hosted yet!")
            return
        }
        let totalW = self.calcedTotalWidth()
        let rct = self.bounds.changed(x: (self.bounds.width - totalW) * 0.5 ,width: totalW)
        stackView?.frame = rct
        stackView?.needsLayout = true
    }
    
    private func updateTabs(selectedIndex selIndex:Int) {
        let key = "\(type(of: self)).updateTabs.\(String(memoryAddressOf: self))"
        TimedEventFilter.shared.filterEvent(key: key, threshold: 0.2, accumulating: "\(self.tabCount)") { accum in
            dlog?.info("updateTabs \(accum?.descriptionsJoined) selected: \(selIndex) ")
        }
        
        DispatchQueue.mainIfNeeded {
            self.updateStackView()
            
            (self.arrangedSubviews as? [NSImageView])?.forEachIndex({ index, view in
                let isSelectedd = index == selIndex
                let img = isSelectedd ? self._selectedImages[index] : self._images[index]
                view.image = img
            })
        }
    }
    
    func calcedTotalWidth()->CGFloat {
        let cnt = self.arrangedSubviews.count
        let spacingsCnt = max(0, cnt - 1)
        let result : CGFloat = (CGFloat(cnt) * self.minTabWidth) + (CGFloat(spacingsCnt) * self.spacing)
        return result
    }
    
    func debugAddBkg() {
        let view = MNColoredView(frame: self.bounds.insetBy(dx: 2, dy: 2))
        view.autoresizingMask = [.width, .maxYMargin]
        view.backgroundColor = NSColor.yellow.withAlphaComponent(0.1)
        view.borderColor = NSColor.orange.withAlphaComponent(0.6)
        view.borderWidth = 1.0
        self.addSubview(view, positioned: .below, relativeTo: self.subviews.first)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let view = self.stackView ?? self
        let w = max(view.bounds.width, self.calcedTotalWidth())
        
        if let loc = event.locationInView(view) {
            var index = Int(floor(loc.x / (w / CGFloat(self.arrangedSubviews.count))))
            index = min(max(index, 0), self.tabCount - 1)
            
            // call setter
            if self._isEnabled[index] ?? true {
                switch self.behavior {
                case .segmentedControl:
                    self.selectedIndex = index
                case .toolbar:
                    self.updateTabs(selectedIndex: index)
                }
            }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        let view = self.stackView ?? self
        let w = max(view.bounds.width, self.calcedTotalWidth())
        
        if let loc = event.locationInView(view) {
            var index = Int(floor(loc.x / (w / CGFloat(self.arrangedSubviews.count))))
            index = min(max(index, 0), self.tabCount - 1)
            
            // call setter
            switch self.behavior {
            case .segmentedControl:
                break
            case .toolbar:
                if self._isEnabled[index] ?? true {
                    self.selectedIndex = index
                    self.selectedIndex = -1
                }
            }
        }
    }
    
    func setTooltip(_ newToolTip:String?, forTabAt index:Int) {
        guard index > -1 && index < self.tabCount else {
            return
        }
        let view = self.arrangedSubviews[index]
        view.toolTip = newToolTip
    }
    
    func setTabEnabled(_ enabled: Bool, at index:Int) {
        guard index > -1 && index < self.tabCount else {
            return
        }
        let img = self.arrangedSubviews[index]
        img.alphaValue = enabled ? 1.0 : 0.35
        self._isEnabled[index] = enabled
    }
    
    @discardableResult
    func addTab(isSelected:Bool, image:NSImage, selectedImage:NSImage?, tooltip:String?)->NSImageView {
        let imageView = NSImageView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.minTabWidth, height: self.bounds.height)))
        // controlAccentColor
        self._selectedImages.append(selectedImage ?? image.tinted(NSColor.controlAccentColor)!)
        self._images.append(image)
        imageView.image = image
        imageView.toolTip = tooltip ?? ""
        
        self.stackView?.addArrangedSubview(imageView)
        self.stackView?.frame = self.bounds.center.rectAroundCenter(width: self.calcedTotalWidth(), height: self.bounds.height)
        self.updateTabs(selectedIndex: self.selectedIndex)

        if DEBUG_DRAWING, let stackview = self.stackView {
            let index = self._images.count - 1
            let spaceIdx = max(index, 0)
            let xAdd : CGFloat = (self.minTabWidth * CGFloat(index)) + ((self.spacing + 1.0) * CGFloat(spaceIdx))
            let view = MNColoredView(frame: stackview.frame.changed(x: xAdd, width: self.minTabWidth))
            view.backgroundColor = NSColor.cyan.withAlphaComponent(0.12)
            view.borderColor = NSColor(srgbRed: 0.0, green: 0.6, blue: 1.0, alpha: 0.7)
            view.borderWidth = 1.0
            self.stackView?.addSubview(view)
        }
        
        return imageView
    }
    
    func addTabs(tabs:[MNSegmentedTabs.TabInfo]) {
        tabs.forEach { tabInfo in
            let tab = self.addTab(isSelected: false,
                                  image: tabInfo.image,
                                  selectedImage: tabInfo.selectedImage,
                                  tooltip: tabInfo.tooltip)
            tab.toolTip = tabInfo.tooltip
        }
    }
    
    func addTabs(count:Int, block:(Int)->TabInfo?) {
        guard count > 0 && count < 99 else {
            return
        }
        var tabs : [TabInfo] = []
        for i in 0..<count {
            if let tab = block(i) {
                tabs.append(tab)
            }
        }
        self.addTabs(tabs: tabs)
    }
}

extension MNSegmentedTabs.TabInfo {
    
    init(imageName: NSImage.Name,
         selecedImageName: NSImage.Name,
         selectedTintColor:NSColor?,
         scale:CGFloat,
         tooltip:String?) {
        
        // Set images
        image = NSImage(named: imageName)!.scaled(scale)!
        if let tint = selectedTintColor {
            selectedImage = NSImage(named: selecedImageName)!.tinted(tint)!
        } else {
            selectedImage = NSImage(named: selecedImageName)!
        }
        self.tooltip = tooltip ?? ""
    }
    
    init(systemSymbolName sysName: String,
         systemSelecedSymbolName sysSelName: String,
         selectedTintColor:NSColor?,
         scale:CGFloat,
         tooltip:String?) {
        
        // Set images
        image = NSImage(systemSymbolName: sysName, accessibilityDescription: nil)!.scaled(scale)!
        var selImage : NSImage = image
        
        if let tint = selectedTintColor {
            if let img = NSImage(systemSymbolName: sysSelName, accessibilityDescription:nil)?.tinted(tint) {
                selImage = img
            } else if let img = image.tinted(tint) {
                selImage = img
            }
        } else if let img = NSImage(systemSymbolName: sysSelName, accessibilityDescription: nil) {
            selImage = img
        }
        
        self.selectedImage = selImage.scaled(scale)!
        self.tooltip = tooltip ?? ""
    }
}
