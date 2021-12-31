//
//  MNSplitView.swift
//
//  Created by Ido on 28/01/2021.
//
//
import AppKit

fileprivate let dlog : DSLogger? = nil // DLog.forClass("MNSplitview")

protocol MNSplitviewDelegate : NSSplitViewDelegate {
    func splitviewSidebarsChanged(_ splitview:MNSplitview, isLeadingCollapsed:Bool, isTrailingCollapsed:Bool)
}

class MNSplitview : NSSplitView {
    
    // MARK: Properties
    private var _isAnimating : [Int:Bool] = [:]
    private var _isAnyAnimating = false
    private var _isMousePressed : Bool = false
    private var _fwdDelegate : NSSplitViewDelegate? = nil
    private var _leadingMinWidthToSnap : CGFloat? = nil
    private var _trailingMinWidthToSnap : CGFloat? = nil
    
    private var lastPositivePosition : [Int:CGFloat] = [:]
    private var lastPosition : [Int:CGFloat] = [:]
    private var lastIsLeadingPanelCollapsed:Bool = false
    private var lastIsTrailingPanelCollapsed:Bool = false
    
    weak var hostingSplitVC : NSSplitViewController? = nil
    
    override var delegate: NSSplitViewDelegate? {
        get {
            return _fwdDelegate
        }
        set {
            if (newValue === self) {
                super.delegate = newValue
            } else {
                self._fwdDelegate = newValue
                super.delegate = self
            }
        }
    }
    
    // MARK: Private util func
    private func updateLastCollapsed() {
        var wasChanged = false
        let isLeadingC = self.isLeadingPanelCollapsed
        if self.lastIsLeadingPanelCollapsed != isLeadingC {
            self.lastIsLeadingPanelCollapsed = isLeadingC
            wasChanged = true
        }
        
        let isTrailingC = self.isTrailingPanelCollapsed
        if self.lastIsTrailingPanelCollapsed != isTrailingC {
            self.lastIsTrailingPanelCollapsed = isTrailingC
            wasChanged = true
        }
        
        // if MNSplitviewDelegate
        if wasChanged, let mnDelegate = self.delegate as? MNSplitviewDelegate ?? self._fwdDelegate as? MNSplitviewDelegate {
            mnDelegate.splitviewSidebarsChanged(self, isLeadingCollapsed: isLeadingC, isTrailingCollapsed: isTrailingC)
        }
        
    }
    
    // MARK: Private func
    private func setup() {
        waitFor("arrangedSubviews to be added", interval: 0.04, timeout: 0.1, testOnMainThread: {
            self.arrangedSubviews.count > 0
        }, completion: { waitResult in
            DispatchQueue.main.performOncePerInstance(self) { [self] in
                dlog?.info("setup: leading dic idx: \(self.leadingDividerIndex) trailing div idx \(self.trailingDividerIndex)")
                self._leadingMinWidthToSnap = self.minPossiblePositionOfDivider(at: leadingDividerIndex)
                self._trailingMinWidthToSnap = self.minPossiblePositionOfDivider(at: self.trailingDividerIndex)
                self.saveWidths()
                DispatchQueue.main.asyncAfter(delayFromNow: 0.02) {
                    self.calcSnappingSizes()
                }
            }
        }, counter: 1)
    }
    
    private func saveWidthsForPanel(at index:Int) {
        guard self._isAnyAnimating == false else {
            return
        }
        var view : NSView? = nil
        if index >= 0 && index <= self.arrangedSubviews.count  {
            view = self.arrangedSubviews[index]
            if let view = view {
                let w : CGFloat = view.frame.width
                self.lastPosition[index] = w
                
                var saveSide = true
                if index == leadingDividerIndex && self.isLeadingPanelCollapsed {
                    saveSide = false
                } else if index == trailingDividerIndex + 1 && self.isTrailingPanelCollapsed {
                    saveSide = false
                }
                
                if saveSide {
                    dlog?.success("saving w at \(index) = \(w)")
                    self.lastPosition[index] = w
                } else {
                    dlog?.fail("saving w at \(index) [COLLAPSED]")
                }
            }
        }
    }
    
    private func calcSnappingSizes() {
        // First ever save with snapping sizes
        if let w = self._leadingMinWidthToSnap, w <= 10, self.arrangedSubviews.count > 1 {
            self._leadingMinWidthToSnap = self.minPossiblePositionOfDivider(at: self.leadingDividerIndex + 1)
            self._trailingMinWidthToSnap = abs(self.minPossiblePositionOfDivider(at:self.trailingDividerIndex))
            dlog?.info("calcSnappingSizes widths leading:\(self._leadingMinWidthToSnap.descOrNil) trailing:\(self._trailingMinWidthToSnap.descOrNil)")
        }
    }
    
    private func saveWidths() {
        
        dlog?.info("saveWidths [\(leadingDividerIndex)..\(trailingDividerIndex)]")
        for index in 0..<arrangedSubviews.count {
            self.saveWidthsForPanel(at: index)
        }
    }
    
    // MARK: Lifecycle
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    var isAnimating : Bool {
        return _isAnyAnimating
    }
    
    fileprivate func togglePanelUsingSplitVC(vc:NSSplitViewController, dividerIndex: Int, wantedPosition: CGFloat, animated: Bool, duration: TimeInterval, completion: (() -> Void)?) {
        
        let isLeading = (dividerIndex == 0)
        var delay : TimeInterval = .zero
        if let splitItem = isLeading ? vc.splitViewItems.first : vc.splitViewItems.last {
            if animated {
                splitItem.animator().isCollapsed = !splitItem.isCollapsed
                delay = 0.25
            } else {
                splitItem.isCollapsed = !splitItem.isCollapsed
            }
            self.updateLastCollapsed()
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: delay, block: {
            completion?()
        })
    }
    
    fileprivate func togglePanelUsingDivPosition( dividerIndex: Int, wantedPosition: CGFloat, animated: Bool, duration: TimeInterval, completion: (() -> Void)?) {
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.allowsImplicitAnimation = true
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                context.duration = duration
                
                self.setPosition(wantedPosition, ofDividerAt: dividerIndex)
                self.updateLastCollapsed()
            }, completionHandler: { () -> Void in
                completion?()
            })
        } else {
            self.setPosition(wantedPosition, ofDividerAt: dividerIndex)
            self.updateLastCollapsed()
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    private func togglePanel(at index :Int, animated:Bool = true, completion: (()->Void)? = nil) {
        dlog?.todo("togglePanel at:\(index) animated:\(animated)")
        
        func finllize() {
            self._isAnimating[index] = false
            self._isAnyAnimating = false
        }
        
        let dividerIndex = max(index - 1, 0)
        let duration : TimeInterval = 0.25
        let isLeading = dividerIndex == 0
        let isCollapsed = isLeading ? self.isLeadingPanelCollapsed : self.isTrailingPanelCollapsed
        var wantedPosition : CGFloat = 0.0
        
        switch (isLeading, isCollapsed) {
        // leading
        case (true, false) : wantedPosition = 0 // shoud collapse
        case (true, true)  : wantedPosition = self.lastPositivePosition[0] ??  self.lastPosition[index] ?? self._leadingMinWidthToSnap ?? 140  // should uncollapse
        
        // trailing
        case (false, false): wantedPosition = self.bounds.width // should collapse
        case (false, true) : wantedPosition = self.bounds.width - (self.lastPositivePosition[index] ?? self.lastPosition[index] ?? self._trailingMinWidthToSnap ?? 0.0)   // should uncollapse
        }
        
        if let vc = self.hostingSplitVC {
            // Much smoother animation using the VC
            self.togglePanelUsingSplitVC(vc: vc, dividerIndex: dividerIndex, wantedPosition: wantedPosition, animated: animated, duration: duration) {
                completion?()
                finllize()
            }
        } else {
            // Chunky animation as fallback..
            self.togglePanelUsingDivPosition(dividerIndex: dividerIndex, wantedPosition: wantedPosition, animated: animated, duration: duration) {
                completion?()
                finllize()
            }
        }
        
        if animated {
            self._isAnimating[index] = true
            self._isAnyAnimating = true
        }
    }
 
    // MARK: Public
    func toggleTrailingPanel(animated:Bool = true, completion: (()->Void)? = nil) {
        self.togglePanel(at: self.trailingDividerIndex + 1, animated: animated, completion: completion)
    }
    
    func toggleLeadingPanel(animated:Bool = true, completion: (()->Void)? = nil) {
        self.togglePanel(at: self.leadingDividerIndex, animated: animated, completion: completion)
    }
    
    func expandLeadingPanel(animated:Bool = true, completion: (()->Void)? = nil) {
        guard self.isLeadingPanelCollapsed else {
            return
        }
        
        dlog?.info("expandLeadingPanel animated:\(animated)")
        self.toggleLeadingPanel(animated: animated, completion: completion)
    }
    
    func expandTrailingPanel(animated:Bool = true, completion: (()->Void)? = nil) {
        guard self.isTrailingPanelCollapsed else {
            return
        }
        
        dlog?.info("expandTrailingPanel animated:\(animated)")
        self.toggleTrailingPanel(animated: animated, completion: completion)
    }
    
    func collapseLeadingPanel(animated:Bool = true, completion: (()->Void)? = nil) {
        guard !self.isLeadingPanelCollapsed else {
            return
        }
        
        dlog?.info("collapseLeadingPanel animated:\(animated)")
        self.toggleLeadingPanel(animated: animated, completion: completion)
    }
    
    func collapseTrailingPanel(animated:Bool = true, completion: (()->Void)? = nil) {
        guard !self.isTrailingPanelCollapsed else {
            return
        }
        
        dlog?.info("collapseTrailingPanel animated:\(animated)")
        self.toggleTrailingPanel(animated: animated, completion: completion)
    }
}

// Forwad delegated events:
extension MNSplitview : NSSplitViewDelegate {
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        let result = self._fwdDelegate?.splitView?(splitView, canCollapseSubview: subview) ?? true
        return result
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        let result = self._fwdDelegate?.splitView?(splitView, constrainMinCoordinate: proposedMinimumPosition, ofSubviewAt:dividerIndex) ?? proposedMinimumPosition
        return result
    }
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        let result = self._fwdDelegate?.splitView?(splitView, constrainMaxCoordinate: proposedMaximumPosition, ofSubviewAt:dividerIndex) ?? proposedMaximumPosition
        return result
    }
    
    func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        let result = self._fwdDelegate?.splitView?(splitView, constrainSplitPosition: proposedPosition, ofSubviewAt:dividerIndex) ?? proposedPosition
        return result
    }
    
    func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
        self._fwdDelegate?.splitView?(splitView, resizeSubviewsWithOldSize: oldSize)
        saveWidths()
    }
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        let result = self._fwdDelegate?.splitView?(splitView, shouldAdjustSizeOfSubview: view) ?? true
        return result
    }
    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        let result = self._fwdDelegate?.splitView?(splitView, shouldHideDividerAt: dividerIndex) ?? true
        return result
    }
    
    func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        let result = self._fwdDelegate?.splitView?(splitView, effectiveRect: proposedEffectiveRect, forDrawnRect:drawnRect, ofDividerAt:dividerIndex) ?? proposedEffectiveRect
        return result
    }
    
    func splitView(_ splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex: Int) -> NSRect {
        let result = self._fwdDelegate?.splitView?(splitView, additionalEffectiveRectOfDividerAt: dividerIndex) ?? NSRect.zero
        return result
    }
    
    func splitViewWillResizeSubviews(_ notification: Notification) {
        self._fwdDelegate?.splitViewWillResizeSubviews?(notification)
    }
    
    func splitViewDidResizeSubviews(_ notification: Notification) {
        self._fwdDelegate?.splitViewDidResizeSubviews?(notification)
        TimedEventFilter.shared.filterEvent(key: "splitViewDidResizeSubviews", threshold: 0.1) {
            self.updateLastCollapsed()
        }
        saveWidths()
    }
    
}

