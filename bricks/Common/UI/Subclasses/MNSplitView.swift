//
//  MNSplitView.swift
//
//  Created by Ido on 28/01/2021.
//
//
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("MNSplitview")

class MNSplitview : NSSplitView {
    
    // MARK: Properties
    private var _fwdDelegate : NSSplitViewDelegate? = nil
    
    override var delegate: NSSplitViewDelegate? {
        get {
            return _fwdDelegate
        }
        set {
            if (newValue === self) {
                super.delegate = newValue
            } else {
                self._fwdDelegate = newValue
                self.delegate = self
            }
        }
    }
    
    // MARK: Private util func
    
    // MARK: Private func
    private func setup() {
        if self.subviews.count > 0 {
            DispatchQueue.main.performOncePerInstance(self) {
                dlog?.info("setup: leading dic idx: \(self.leadingDividerIndex) trailing div idx \(self.trailingDividerIndex)")
                // self.saveWidths()
            }
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
    
    //override var acceptsFirstResponder: Bool {
    //    return true
    //}
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
    }
    
}
    
//    private var lastConstraintConstant : [Int:CGFloat] = [:]
//    private var lastPositivePosition : [Int:CGFloat] = [:]
//    private var lastPosition : [Int:CGFloat] = [:]

//    private var _isAnimating : [Int:Bool] = [:]
//    private var _isAnyAnimating = false
//    private var _isMousePressed : Bool = false
//    
//    @IBOutlet var leftMaxWidthConstraint : NSLayoutConstraint? = nil
//    @IBOutlet var rightMaxWidthConstraint : NSLayoutConstraint? = nil
//    var leftMinWidthToSnap : CGFloat? = nil
//    var rightMinWidthToSnap : CGFloat? = nil
//
//    private func findIntrinsincWidth(forView:NSView?)->CGFloat? {
//        guard let view = forView else {
//            return nil
//        }
//        var maxW : CGFloat = 9999.0
//        for subv in view.subviews {
//            let w = subv.frame.width * 0.5
//            maxW = min(maxW, w)
//        }
//        return max(view.intrinsicContentSize.width, maxW)
//    }
//    
//    deinit {
//        leftMaxWidthConstraint = nil
//        rightMaxWidthConstraint = nil
//    }
//
//    func isPanelCollapsed(at index:Int)->Bool {
//        if index == self.minDivierIndex, let constraint = self.leftMaxWidthConstraint, constraint.constant == 0 {
//            return true
//        }
//        if index == self.maxDivierIndex, let constraint = self.rightMaxWidthConstraint, constraint.constant == 0 {
//            return true
//        }
//        
////        let view = self.subviews[index]
////        if view.frame.width < 10 {
////            dlog?.info("\(index) is collapsed by merit of width")
////            return true
////        }
//        
//        return (self.lastPosition[index] ?? 0.0 == 0.0) && (self.lastPositivePosition[index] ?? 0 > 0)
//    }

//    
//    // MARK: Private
//    private func saveWidthsForPanel(at index:Int) {
//        guard self._isAnyAnimating == false else {
//            return
//        }
//        var view : NSView? = nil
//        if index >= self.minDivierIndex && index <= self.maxDivierIndex  {
//            view = self.subviews[index]
//            if let view = view {
//                let w : CGFloat = view.frame.width
//                self.lastPosition[index] = w
//                var min : CGFloat = 0.0
//                if index == 0, let minL = self.leftMinWidthToSnap {
//                    min = minL
//                } else if index == maxDivierIndex, let minR = self.rightMinWidthToSnap {
//                    min = minR
//                }
//                if w > min {
//                    dlog?.success("saving w at \(index) = \(w)")
//                    self.lastPositivePosition[index] = w
//                } else {
//                    dlog?.fail("saving w at \(index)")
//                }
//            }
//        }
//    }
//    
//    func saveWidths() {
//        // dlog?.info("saveWidths [\(minDivierIndex)..\(maxDivierIndex)]")
//        for index in minDivierIndex...maxDivierIndex {
//            self.saveWidthsForPanel(at: index)
//        }
//    }
//    
//    private func togglePanel(at index :Int, animated:Bool = true, completion: (()->Void)? = nil) {
//        let isCollapse = !self.isPanelCollapsed(at: index)
//        
//        var constraint : NSLayoutConstraint? = nil
//        if index == self.minDivierIndex {
//            constraint = self.leftMaxWidthConstraint
//            
//        } else if index == self.maxDivierIndex {
//            constraint = self.rightMaxWidthConstraint
//        }
//
//        dlog?.info("Will toggle panel at \(index) will \(isCollapse ? "collapse" : "expand")")
//        if let constraint = constraint {
//            if constraint.constant > 0 {
//                // Save positive constraint value
//                lastConstraintConstant[index] = constraint.constant
//            }
//            
//            self._isAnimating[index] = true
//            self._isAnyAnimating = true
//            NSView.animate(duration: 0.4, delay: 0.0) { (context) in
//                context.allowsImplicitAnimation = true
//                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//                let constant = self.lastConstraintConstant[index] ?? 0.0
//                constraint.animator().constant = isCollapse ? 0.0 : constant
//                let view = self.subviews[index]
//                if index == 0 {
//                    view.animator.frame = view.frame.changed(width: self.lastPositivePosition[index] ?? constant)
//                } else {
//                    view.animator.frame = view.frame.changed(x: 0, width: self.lastPositivePosition[index] ?? constant)
//                }
//            } completionHandler: {
//                self._isAnimating[index] = false
//                self._isAnyAnimating = false
//            }
//        }
//    }
//    
//    // MARK: Public
//    func toggleRightPanel(animated:Bool = true, completion: (()->Void)? = nil) {
//        self.togglePanel(at: self.maxDivierIndex, animated: animated, completion: completion)
//    }
//    
//    func toggleLeftPanel(animated:Bool = true, completion: (()->Void)? = nil) {
//        self.togglePanel(at: self.minDivierIndex, animated: animated, completion: completion)
//    }
//    
//    func expandLeftPanel(animated:Bool = true, completion: (()->Void)? = nil) {
//        guard self.isLeftPanelCollapsed else {
//            return
//        }
//        
//        dlog?.info("expandLeftPanel animated:\(animated)")
//        self.toggleLeftPanel(animated: animated, completion: completion)
//    }
//    
//    func expandRightPanel(animated:Bool = true, completion: (()->Void)? = nil) {
//        guard self.isRightPanelCollapsed else {
//            return
//        }
//        
//        dlog?.info("expandRightPanel animated:\(animated)")
//        self.toggleRightPanel(animated: animated, completion: completion)
//    }
//    
//    func collapseLeftPanel(animated:Bool = true, completion: (()->Void)? = nil) {
//        guard !self.isLeftPanelCollapsed else {
//            return
//        }
//        
//        dlog?.info("collapseLeftPanel animated:\(animated)")
//        self.toggleLeftPanel(animated: animated, completion: completion)
//    }
//    
//    func collapseRightPanel(animated:Bool = true, completion: (()->Void)? = nil) {
//        guard !self.isRightPanelCollapsed else {
//            return
//        }
//        
//        dlog?.info("collapseRightPanel animated:\(animated)")
//        self.toggleRightPanel(animated: animated, completion: completion)
//    }
//
//}

//extension MNSplitview : NSSplitViewDelegate {
//    
//    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
//        return false
//    }
//    
//    func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
//        return false
//    }
//    
//    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
//        return false
//    }
//    
//    @discardableResult
//    private func calcSnappingIfNeeded()->Bool {
//        var result = false
//        
//        if result == false, let lsnap = self.leftMinWidthToSnap, let lview = self.arrangedSubviews.first {
//            if lview.bounds.width < lsnap {
//                collapseLeftPanel(animated: true, completion: nil)
//                result = true
//            }
//        }
//        
//        if result == false, let rsnap = self.rightMinWidthToSnap, let rview = self.arrangedSubviews.last {
//            if rview.bounds.width < rsnap {
//                collapseRightPanel(animated: true, completion: nil)
//                result = true
//            }
//        }
//        
//        return result
//    }
//    
//    private func calcSizing(_ notification: Notification) {
//        let isPressed = NSEvent.pressedMouseButtons > 0
//        if self._isMousePressed == false && isPressed {
//            self._isMousePressed = true
//            // started drag!
//            dlog?.info("save last sze befoe drag \(isPressed)")
//            if let index = notification.userInfo?["NSSplitViewDividerIndex"] as? Int {
//                let isCollapsed = self.isPanelCollapsed(at: index)
//                dlog?.info("drag panel index \(index) collapsed: \(isCollapsed)")
//                if isCollapsed, let constraint = (index == 0) ? self.leftMaxWidthConstraint : self.rightMaxWidthConstraint {
//                    constraint.constant = lastConstraintConstant[index] ?? 0.0
//                } else {
//                    self.saveWidthsForPanel(at: index)
//                }
//            } else {
//                self.saveWidths()
//            }
//        }
//    }
//    
//    func splitViewWillResizeSubviews(_ notification: Notification) {
//        calcSizing(notification)
//    }
//    
//    func splitViewDidResizeSubviews(_ notification: Notification) {
//        calcSizing(notification)
//    }
//    
//    override func mouseDown(with event: NSEvent) {
//        super.mouseDown(with: event)
//        let isPressed = NSEvent.pressedMouseButtons > 0
//        if self._isMousePressed == true && !isPressed {
//            self._isMousePressed = false
//            // Ended drag!
//            dlog?.info("calcing if should snap")
//            if !self.calcSnappingIfNeeded() {
//                self.saveWidths()
//            }
//            
//        }
//    }
//}

