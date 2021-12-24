//
//  CircleProgressView.swift
//  Bricks
//
//  Created by Ido on 19/12/2021.
//

import AppKit
import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("CircleProgressView")

// @IBDesignable
final public class CircleProgressView: NSView {
    let DEBUG_DRAWING = false
    let DEBUG_DRAW_MASK_AS_LAYER = false
    let DEBUG_DEV_TIMED_TEST = false
    
    let HIDE_ANIM_DURATION : TimeInterval = 0.4
    let HIDE_ANIM_DELAY : TimeInterval = 0.2
    let UNHIDE_ANIM_DURATION : TimeInterval = 0.3
    let UNHIDE_ANIM_DELAY : TimeInterval = 0.1
    let MAX_WIDTH : CGFloat = 1200.0
    let MAX_HEIGHT : CGFloat = 1200.0
    
    enum ShowHideAnimationType {
        case none
        case shrinkToLeading
        case shrinkToCenter
        case shrinkToTrailing
    }
    
    enum ProgressType  : String, Equatable {
        case determinate        // Progress in a circle, animating a filling arc
        case determinateSpin    // Progress in a circle, animating a filling arc, while the whole object continuesly rotates
        case indeterminateSpin  // Progress arc fluctuates between min and max, while the whole object continuesly rotates - setting progress if ignored until ProgressType is changed to another type
        
        var isSpinable : Bool {
            return self != .determinate
        }
        
        var isDeterminate : Bool {
            return self != .indeterminateSpin
        }
    }
    
    // MARK: - Private Properties
    private let rootLayer = CALayer()
    private let ringsLayer = CALayer()
    private let backgroundLayer = CALayer()
    private var bkgRingLayer = CAShapeLayer()
    private var progressRingLayer = CAShapeLayer()
    private var progressRingLayerMask = CAShapeLayer()
    private var lastUsedRect : CGRect = .zero
    private var isAnimatingSpin = false
    private var isAnimatingShowHide = false
    private var wasHiddenByAnimation: ShowHideAnimationType = .none
    private var widthBeforeLastHideAnimation: CGFloat = 28
    
    // keypathes
    private let basicDisabledKeypathes : [String] = [] // ["position", "frame", "bounds", "zPosition", "anchorPointZ", "contentsScale", "anchorPoint"]
    
    // MARK: Inspectables properties
    @IBInspectable var backgroundColor  : NSColor = .clear { didSet { updateLayers() } }
    var bkgRingIsFull : Bool = false { didSet { if bkgRingIsFull != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingWidth : CGFloat = 2.0 { didSet { if bkgRingWidth != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingColor : NSColor = .tertiaryLabelColor.blended(withFraction: 0.2, of: .secondaryLabelColor)! { didSet { if bkgRingColor != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingInset : CGFloat =  1.5 { didSet { if bkgRingInset != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingOpacity : Float =  0.5 { didSet { if bkgRingOpacity != oldValue { updateLayers() } } }
    
    @IBInspectable var progressRingWidth : CGFloat = 2.0 { didSet { if progressRingWidth != oldValue { updateLayers() } } }
    @IBInspectable var progressRingColor : NSColor = .controlAccentColor { didSet { if progressRingColor != oldValue { updateLayers() } } }
    @IBInspectable var progressRingInset : CGFloat = 1.5 { didSet { if progressRingInset != oldValue { updateLayers() } } }
    @IBInspectable var centerOffset : CGPoint = .zero { didSet { if centerOffset != oldValue { updateLayers() } } }
    
    @IBOutlet weak var widthConstraint : NSLayoutConstraint? = nil
    @IBOutlet weak var heightConstraint : NSLayoutConstraint? = nil
    
    // MARK: Public properties
    var showHideAnimationType : ShowHideAnimationType = .shrinkToLeading
    
    // MARK: Evented properties
    var onBeforeHideAnimating: (()->Void)? = nil
    var onHideAnimating: ((NSAnimationContext?)->Void)? = nil
    var onBeforeUnhideAnimating: (()->Void)? = nil
    var onUnhideAnimating: ((NSAnimationContext?)->Void)? = nil
    
    var _spinningProgress = 0.0
    @IBInspectable var spinningProgress : CGFloat {
        get {
            return _spinningProgress
        }
        set {
            self.setNewProgress(newValue, animated: true)
        }
    }
        
    var progressType : ProgressType = .determinate {
        didSet {
            if progressType != oldValue {
                if !self.progressType.isDeterminate && self.wasHiddenByAnimation != .none {
                    self.unhideAnimation(duration: 0.3, delay: 0.1)
                }
                
                if progressType.isSpinable != oldValue.isSpinable {
                    dlog?.info(">> \(progressType.isSpinable ? "Starting" : "Stopping") spinning state")
                    self.setNewProgress(progressType.isDeterminate ? _spinningProgress : _progress, animated: true, forced:true)
                    updateSpinAnimations()
                    updateLayers()
                }
                
            }
        }
    }
    
    var _progress = 0.0
    var progress : CGFloat {
        get {
            return _progress
        }
        set {
            self.setNewProgress(newValue, animated: true)
        }
    }
    
    var _scale = 2.0
    
    public override var fittingSize: NSSize {
        return intrinsicContentSize
    }
    
    public override var intrinsicContentSize: NSSize {
        var sze = super.intrinsicContentSize
        sze.width = max(sze.width, lastUsedRect.width)
        sze.height = max(sze.width, lastUsedRect.height)
        // dlog?.info("intrinsicContentSize \(sze)")
        return sze
    }
    
    public override var isHidden: Bool {
        get {
            return super.isHidden
        }
        set {
            if super.isHidden != newValue {
                super.isHidden = newValue
                
                let isInUI = self.superview != nil && self.window != nil
                dlog?.info("isHidden set to: \(newValue) isInUI: \(isInUI)")
                if !self.isAnimatingShowHide && self.showHideAnimationType != .none {
                    if newValue {
                        // Hide
                        if isInUI {
                            self.hideAnimation(duration: HIDE_ANIM_DURATION, delay: HIDE_ANIM_DELAY, completion: nil)
                        } else {
                            self.resetToZero(animated: false, hides: true, completion: nil)
                        }
                    } else {
                        // Show
                        if isInUI {
                            self.unhideAnimation(duration: UNHIDE_ANIM_DURATION, delay: UNHIDE_ANIM_DELAY, completion: nil)
                        } else {
                            // No need to do anything
                        }
                    }
                }
            }
        }
    }
    // MARK: Hashable
    public override var hash: Int {
        var result : Int = self.frame.hashValue
        result = result ^ backgroundColor.hashValue ^ bkgRingWidth.hashValue ^ bkgRingColor.hashValue ^ bkgRingInset.hashValue ^ bkgRingOpacity.hashValue
        
        result = result ^ progressRingWidth.hashValue ^ progressRingColor.hashValue ^ progressRingInset.hashValue ^ centerOffset.hashValue
        
        result = result ^ _spinningProgress.hashValue ^ _progress.hashValue ^ _scale.hashValue
        
        return result
    }
    
    // MARK: - Lifecycle
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required public init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }
    
    public override var frame: NSRect { didSet { if frame != oldValue { layout() }  } }
    
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let screen = self.window?.screen {
            dlog?.info("viewDidMoveToWindow START")
            let val = clamp(value: self.window?.backingScaleFactor ?? screen.backingScaleFactor, lowerlimit: 0.01, upperlimit: 4.0)
            if self._scale != val {
                self._scale = val
            }
            self.setupIfNeeded()
            self.updateLayers()
            self.forceUpdateCurProgress()
            dlog?.info("viewDidMoveToWindow DONE")
        }
    }
    
    public override func layout() {
        super.layout()
        let rect = self.rectForLayers()
        let layers = [backgroundLayer, bkgRingLayer, progressRingLayer]
        var changes = 0
        layers.forEachIndex { index, layer in
            if layer.frame != rect {
                layer.frame = rect
                layer.frame = rect
                changes += 1
            }
        }
        if !isAnimatingShowHide && changes > 0 {
            self.updateLayers()
        }
    }
    
    func clearAllClosureProperties() {
        self.onBeforeHideAnimating = nil
        self.onHideAnimating = nil
        self.onBeforeUnhideAnimating = nil
        self.onUnhideAnimating = nil
    }
    
    deinit {
        clearAllClosureProperties()
    }
    // MARK: - private Updates
    private var lastBkgHash : Int = 0
    func updateBackgroundLayer(bounds rect: CGRect) {
        let newBkgHash = backgroundColor.hashValue ^ rect.hashValue ^ _scale.hashValue
        if lastBkgHash != newBkgHash {
            lastBkgHash = newBkgHash
            
            //dlog?.info("   updateBackgroundLayer")
            backgroundLayer.bounds = rect
            backgroundLayer.backgroundColor = self.backgroundColor.cgColor
            backgroundLayer.disableActions(for: basicDisabledKeypathes)
        }
    }
    
    private var lastBkgRingHash : Int = 0
    func updateBkgRingLayer(bounds rect: CGRect) {
        let newBkgRingHash = bkgRingInset.hashValue ^ bkgRingColor.hashValue ^ bkgRingWidth.hashValue ^ _scale.hashValue ^ bkgRingOpacity.hashValue ^ rect.hashValue
        
        if lastBkgRingHash != newBkgRingHash {
            lastBkgRingHash = newBkgRingHash
            //dlog?.info("   updateBkgRingLayer")
            
            // Bkg ring - full / empty circle
            let rct = rect.insetBy(dx: bkgRingInset, dy: bkgRingInset)
            bkgRingLayer.path = CGPath(ellipseIn: rct, transform: nil)
            bkgRingLayer.backgroundColor = .clear
            
            if bkgRingIsFull {
                bkgRingLayer.strokeColor = .clear
                bkgRingLayer.lineWidth = 0.0
                bkgRingLayer.fillColor = bkgRingColor.cgColor
            } else {
                bkgRingLayer.fillColor = .clear
                bkgRingLayer.strokeColor = bkgRingColor.cgColor
                bkgRingLayer.lineWidth = bkgRingWidth / _scale
            }
            
            bkgRingLayer.disableActions(for: basicDisabledKeypathes)
            bkgRingLayer.opacity = clamp(value: bkgRingOpacity, lowerlimit: 0.0, upperlimit: 1.0, outOfBounds: { val in
                dlog?.note("bkgRingOpacity out of bounds: \(val) should be between 0.0 and 1.0")
            })
        }
    }
    
    private var lastProgressRingHash : Int = 0
    func updateProgressRingLayer(bounds rect: CGRect) {
        let newProgressRingHash = progressRingInset.hashValue ^ progressRingWidth.hashValue ^ rect.hashValue ^ _scale.hashValue ^ bkgRingIsFull.hashValue
        
        if lastProgressRingHash != newProgressRingHash {
            lastProgressRingHash = newProgressRingHash
            
            //dlog?.info("   updateProgressRingLayer")
            
            // Bkg ring - full / empty circle
            let rct = rect.insetBy(dx: progressRingInset, dy: progressRingInset)
            progressRingLayer.path = CGPath(ellipseIn: rct, transform: nil)
            progressRingLayer.backgroundColor = .clear

            if bkgRingIsFull {
                progressRingLayer.strokeColor = .clear
                progressRingLayer.lineWidth = 0.0
                progressRingLayer.fillColor = progressRingColor.cgColor
            } else {
                progressRingLayer.fillColor = .clear
                progressRingLayer.strokeColor = progressRingColor.cgColor
                progressRingLayer.lineWidth = progressRingWidth / _scale
            }
            
            progressRingLayer.disableActions(for: basicDisabledKeypathes)
            progressRingLayer.opacity = 1.0
            progressRingLayer.bounds = rect
            progressRingLayer.actions = ["lineWidth": CABasicAnimation(), "path": CABasicAnimation()]
        }
    }
    
    private var lastProgressRingMaskHash : Int = 0
    func updateProgressRingLayerMask(bounds rect:CGRect) {
        let newProgressRingMaskHash = rect.hashValue ^ progressRingInset.hashValue ^ progressRingWidth.hashValue ^ _scale.hashValue
        if lastProgressRingMaskHash != newProgressRingMaskHash {
            lastProgressRingMaskHash = newProgressRingMaskHash
            
            //dlog?.info("   updateProgressRingLayerMask")
            let mask = self.progressRingLayerMask
            
            let rct = rect.insetBy(dx: progressRingInset, dy: progressRingInset).rounded()
            mask.fillColor = NSColor.clear.cgColor
            mask.strokeColor = NSColor.black.cgColor
            mask.lineWidth = (self.progressRingWidth) / _scale
            mask.lineCap = .round
            mask.lineJoin = .round
            mask.disableActions(for: basicDisabledKeypathes)
            mask.actions = ["lineWidth": CABasicAnimation(), "path": CABasicAnimation()]
            
            // Circle starts on bottom middle:
            let radius = (rct.boundedSquare().width * 0.5)
            let center = rct.center
            let ringPath = NSBezierPath()

            ringPath.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: -270, clockwise: true)

            mask.path = ringPath.cgPath
            //dlog?.info("      mask center \(mask.frame.center) bkgLayer center:\(backgroundLayer.frame.center)")
        }
    }
    
    private var lastTotalHash : Int = 0
    func updateLayers() {
        let newTotalHash = self.hash
        if lastTotalHash != newTotalHash {
            lastTotalHash = newTotalHash
            let rect = self.rectForLayers().boundsRect()
            
            if self.layer != rootLayer {
                self.layer = rootLayer
            }
            rootLayer.centrizeAnchor(animated: false, preventMoving: true)
            
            // dlog?.info("updateLayers bounds:\(rect) isHidden: \(self.isHidden) wasHidden: \(self.wasHiddenByAnimation)")
            updateBackgroundLayer(bounds: rect)
            updateBkgRingLayer(bounds: rect)
            updateProgressRingLayer(bounds: rect)
            updateProgressRingLayerMask(bounds:rect)
        }
    }
    
    private func forceUpdateCurProgress() {
        var prog : CGFloat = 0.0
        switch progressType {
        case .determinate:
            prog = _progress
        case .determinateSpin:
            prog = _spinningProgress
        case .indeterminateSpin:
            prog = 0.5
        }
        setNewProgress(prog, animated: false, forced: true)
    }
    
    private func rectForLayers()->CGRect {
        let rect = self.frame.boundsRect().boundedSquare().insetBy(dx: 0, dy: 0).offset(by: self.centerOffset).rounded()
        
        if !rect.isEmpty && !rect.isInfinite &&
            rect.width > 0 && rect.width < MAX_WIDTH &&
            rect.height > 0 && rect.height < MAX_HEIGHT {
            if rect != lastUsedRect {
                // dlog?.info("rectForLayers: \(rect) hgt:\(rootLayer.frame.height)")
                lastUsedRect = rect
            }
            return rect
        }
        if lastUsedRect.isEmpty == false {
            return lastUsedRect
        }
        return self.bounds
    }
    
    // MARK: - private setup
    private func setupBackgroundLayer() {
        backgroundLayer.disableActions(for: basicDisabledKeypathes)
        backgroundLayer.backgroundColor = self.backgroundColor.cgColor
    }
    
    private func setupBkgRingLayer() {
        bkgRingLayer.disableActions(for: basicDisabledKeypathes)
    }
    
    private func setupProgressRingLayer() {
        progressRingLayer.actions = ["lineWidth": CABasicAnimation(), "path": CABasicAnimation()]
    }
    
    private func setupProgressMaskLayer() {
        progressRingLayerMask.disableActions(for: basicDisabledKeypathes)
        progressRingLayerMask.actions = ["lineWidth": CABasicAnimation(), "path": CABasicAnimation()]
    }
    
    private func setupIfNeeded() {
        guard self.layer != rootLayer else {
            return
        }
        self.setup()
    }
        
    private func setup() {

        lastUsedRect = self.frame.boundsRect()
        self.layer = rootLayer
        self.wantsLayer = true
        rootLayer.centrizeAnchor()
        dlog?.info("setup bounds: \(self.bounds) rootLayer.anchor:\(rootLayer.anchorPoint) center:\(rootLayer.contentsCenter)")
        if let layer = self.layer {
            layer.masksToBounds = true
            if DEBUG_DRAWING {
                layer.backgroundColor = NSColor.blue.withAlphaComponent(0.1).cgColor
                layer.border(color: .blue.withAlphaComponent(0.5), width: 1)
            }
        }
        
        let rect = self.rectForLayers()
        
        ringsLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        ringsLayer.contentsCenter = lastUsedRect
        ringsLayer.frame = rect
        rootLayer.addSublayer(ringsLayer)
        
        let layers = [backgroundLayer, bkgRingLayer, progressRingLayer]
        layers.forEachIndex { index, layer in
            layer.autoresizingMask =  [.layerWidthSizable, .layerHeightSizable]
            layer.frame = rect
            layer.centrizeAnchor()
            ringsLayer.addSublayer(layer)
            if DEBUG_DRAWING && index == 0 {
                layer.border(color: .blue.withAlphaComponent(0.5), width: 0.5)
            }
        }
        ringsLayer.centrizeAnchor()
        
        if DEBUG_DRAW_MASK_AS_LAYER == false {
            progressRingLayer.mask = progressRingLayerMask
        } else {
            self.progressRingLayer.addSublayer(progressRingLayerMask)
        }
        
        setupBackgroundLayer()
        setupBkgRingLayer()
        setupProgressRingLayer()
        setupProgressMaskLayer()
        self.needsDisplay = true
        self.needsLayout = true
        self.superview?.needsLayout = true
        
        DispatchQueue.main.performOncePerSession {
            self.devTestIfNeeded()
        }
    }
    
    private func unhideAnimation(duration:TimeInterval, delay:TimeInterval, completion:(()->Void)? = nil) {
        if !isAnimatingShowHide {
            isAnimatingShowHide = true
            dlog?.info("unhideAnimation duration: \(duration) delay:\(delay)")

            rootLayer.centrizeAnchor(animated: false)
            ringsLayer.centrizeAnchor(animated: false)

            let supr = self.superview?.superview?.superview?.superview ?? self.superview?.superview?.superview ?? self.superview?.superview ?? self.superview
            
            onBeforeUnhideAnimating?()
            self.isHidden = false
            NSView.animate(duration: duration, delay: delay) { context in
                dlog?.info("unhideAnimation START")
                context.allowsImplicitAnimation = true
                self.ringsLayer.transform = CATransform3DIdentity
                self.widthConstraint?.constant = self.widthBeforeLastHideAnimation
                self.onUnhideAnimating?(context)
                
                if let supr = supr {
                    // Will probably not cause window resize
                    supr.layoutSubtreeIfNeeded()
                } else {
                    // May cause window resize
                    self.window?.layoutIfNeeded()
                }

            } completionHandler: {[weak self] in
                if let self = self {
                    
                    dlog?.info("unhideAnimation DONE")
                    self.rootLayer.removeAllAnimations()
                    self.isAnimatingShowHide = false
                    self.wasHiddenByAnimation = .none
                    completion?()
                }
            }
        }
    }
    
    private func transformForHiding()->CATransform3D {
        let w : CGFloat = self.bounds.width * 0.9
        let h : CGFloat = self.bounds.height * 0.5
        
        var transform = CATransform3DIdentity
        switch self.showHideAnimationType {
        case .shrinkToCenter, .none:
            transform = CATransform3DTranslate(transform, 0, -h, 0)
        case .shrinkToLeading:
            transform = CATransform3DTranslate(transform, IS_RTL_LAYOUT ? w : -w, -h, 0)
        case .shrinkToTrailing:
            transform = CATransform3DTranslate(transform, IS_RTL_LAYOUT ? -w : w, -h, 0)
        }
        return CATransform3DScale(transform, 0.01, 0.01, 1)
    }
    
    private func hideAnimation(duration:TimeInterval, delay:TimeInterval, completion:(()->Void)? = nil) {
        
        if !isAnimatingShowHide {
            isAnimatingShowHide = true
            dlog?.info("hideAnimation duration:\(duration) delay:\(delay)")
            
            rootLayer.centrizeAnchor(animated: false)
            ringsLayer.centrizeAnchor(animated: false)
            
            let supr = self.superview?.superview?.superview?.superview ?? self.superview?.superview?.superview ?? self.superview?.superview ?? self.superview
            let finalTransform = self.transformForHiding()
            
            widthBeforeLastHideAnimation = self.widthConstraint?.constant ?? self.ringsLayer.bounds.width
            onBeforeHideAnimating?()
            NSView.animate(duration: duration, delay: delay) { context in
                dlog?.info("hideAnimation START")
                context.allowsImplicitAnimation = true
                
                
                self.ringsLayer.transform = finalTransform
                self.widthConstraint?.constant = 1.0
                self.onHideAnimating?(context)
                
                if let supr = supr {
                    // Will probably not cause window resize
                    supr.layoutSubtreeIfNeeded()
                } else {
                    // May cause window resize
                    self.window?.layoutIfNeeded()
                }

            } completionHandler: {[weak self] in
                if let self = self {
                    
                    dlog?.info("hideAnimation DONE")
                    self.rootLayer.removeAllAnimations()
                    self.isHidden = true
                    self.isAnimatingShowHide = false
                    self.wasHiddenByAnimation = self.showHideAnimationType
                    completion?()
                }
            }
        }
    }
    
    private func newProgressSensitivityFraction()->CGFloat {
        var result : CGFloat = 360
        if self.bounds.width > 200 || self.bounds.height > 200 {
            result = 1440
        } else if self.bounds.width > 100 || self.bounds.height > 100 {
            result = 720
        }
        return result
    }
    
    private func setNewProgressStrokeEnd(part:CGFloat, animated:Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        
        self.progressRingLayerMask.strokeEnd = part
        
        CATransaction.commit()
    }
    
    private func setNewProgress(_ newVal:CGFloat, animated:Bool = true, forced:Bool = false) {
        let newValue = clamp(value: newVal, lowerlimit: 0.0, upperlimit: 1.0)
        let prev = self.progressType.isSpinable ? _spinningProgress : _progress
        let fraction = newProgressSensitivityFraction()
        var isForcedChange = forced
        if !isForcedChange {
            if self.isHidden && self.wasHiddenByAnimation != .none && newValue >= 0.0 {
                isForcedChange = true
            }
        }
        
        // dlog?.info("newVal=\(newVal) delta:\(abs(newValue - prev)) > frac:\((1.0 / fraction))")
        if (abs(newValue - prev) > (1.0 / fraction)) || isForcedChange {
            if self.progressType.isDeterminate {
                _spinningProgress = newValue
            } else {
                _progress = newValue
            }
            
            if IS_DEBUG {
                let prog = self.progressType == .determinate ? "Progress" : "Spinning progress"
                let hid = [self.isHidden ? "true" : "false", self.wasHiddenByAnimation != .none ? "*" : ":("].joined(separator: " ").trimmingCharacters(in: .whitespaces)
                dlog?.info("setNewProgress: \(prog): \(newValue) animated: \(animated) hidden: \(hid) forced:\(forced)")
            }
            
            // Actuallt change the progress mask layer here
            self.setNewProgressStrokeEnd(part: newValue, animated:animated)
            
            if progressType.isDeterminate && showHideAnimationType != .none &&
                !isAnimatingShowHide {
                // Animate show / hide on progress value changed:
                if newValue == 1.0 {
                    self.hideAnimation(duration: HIDE_ANIM_DURATION, delay: HIDE_ANIM_DELAY)
                } else if newValue < 1.0 && self.isHidden && self.wasHiddenByAnimation != .none {
                    self.unhideAnimation(duration: UNHIDE_ANIM_DURATION, delay: UNHIDE_ANIM_DELAY)
                }
            } else if !self.progressType.isDeterminate && self.wasHiddenByAnimation != .none {
                self.unhideAnimation(duration: UNHIDE_ANIM_DURATION, delay: UNHIDE_ANIM_DELAY)
            }
        }
    }
    
    //MARK: Animations / Spinner
    private func startSpinAnimations() {
        
        let layer = DEBUG_DRAW_MASK_AS_LAYER ? progressRingLayerMask : progressRingLayer
        layer.centrizeAnchor(animated: false, preventMoving: false)
        switch progressType {
        case .determinate:
            dlog?.note("startSpinAnimations called for progressType .none!")
            
        case .determinateSpin:
            dlog?.info("startSpinAnimations - simple")
            layer.startSpinAnimation()
            
        case .indeterminateSpin:
            dlog?.info("startSpinAnimations - fluctuates")
            layer.startSpinAnimation()
            progressRingLayerMask.startFluctuaingPathLayer()
        }
        
        isAnimatingSpin = progressType.isSpinable
    }
    
    private func stopSpinAnimations() {
        dlog?.info("stopSpinAnimations")
        let layer = DEBUG_DRAW_MASK_AS_LAYER ? progressRingLayerMask : progressRingLayer
        layer.stopSpinAnimation()
        progressRingLayerMask.stopFluctuaingPathLayer()
        isAnimatingSpin = false
    }
    
    private func updateSpinAnimations() {
        if self.progressType.isSpinable && !isAnimatingSpin {
            startSpinAnimations()
        } else if !self.progressType.isSpinable && isAnimatingSpin {
            stopSpinAnimations()
        }
    }
    
    public func resetToZero(animated:Bool = true, hides:Bool = true, completion:(()->Void)? = nil) {
        self._progress = 0
        self._spinningProgress = 0
        self.setNewProgress(0.0, animated: animated, forced: true)
        if hides {
            dlog?.info("resetToZero animated : \(animated)")
            if animated {
                // Animated hide
                self.hideAnimation(duration:0.3, delay: 0.001, completion: completion)
            } else {
                // Non-Animated
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                
                setNewProgressStrokeEnd(part: 0.0, animated: false)
                rootLayer.centrizeAnchor(animated: false)
                ringsLayer.centrizeAnchor(animated: false)
                widthBeforeLastHideAnimation = self.widthConstraint?.constant ?? self.ringsLayer.bounds.width
                self.onBeforeHideAnimating?()
                self.ringsLayer.transform = transformForHiding()
                self.widthConstraint?.constant = 1.0
                self.needsLayout = true
                self.superview?.needsLayout = true
                self.superview?.superview?.needsLayout = true
                self.onHideAnimating?(nil)
                    
                CATransaction.commit()
                
                // We make as if we were hidden
                wasHiddenByAnimation = showHideAnimationType
                
                completion?()
            }
        } else {
            completion?()
        }
    }
    
    // MARK: Dev / Debug
    func devTestIfNeeded() {
        guard DEBUG_DEV_TIMED_TEST else {
            return
        }

        self.progressType = .determinate
        DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
            dlog?.info("DEBUG_DEV_TIMED_TEST")
            self.progress = 0.2
        }
        DispatchQueue.main.asyncAfter(delayFromNow: 1.0) {
            self.progress = 0.5
        }
        DispatchQueue.main.asyncAfter(delayFromNow: 1.5) {
            self.progress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: 3.0) {
            self.progress = 0.5
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: 3.5) {
            self.progressType = .determinateSpin
        }
        DispatchQueue.main.asyncAfter(delayFromNow: 4.5) {
            self.progress = 1.0
        }
        DispatchQueue.main.asyncAfter(delayFromNow: 4.5) {
            self.progressType = .indeterminateSpin
        }
    }
}
/*
class X {
    // MARK: - private funcs
    
    
    private func setNewProgress(_ newValue:CGFloat, animated:Bool = true, force:Bool = false) {
        
    }

// MARK: - Private
private class Xeffect {
    
    func buildGradientImage(from spectrumColors: [NSColor], radius: CGFloat) -> NSImage {
        let numberOfColours = spectrumColors.count
        
        let diameter = radius * 2
        let center = NSPoint(x: radius, y: radius)
        let size = NSSize(width: diameter, height: diameter);
        
        let image = NSImage(size: size)
        image.lockFocus()
        
        (0..<numberOfColours).forEach { n in
            let color = spectrumColors[n]
            let startAngle = CGFloat(90 - n)
            let endAngle = CGFloat(90 - (n + 1))
            
            let bezierPath = NSBezierPath()
            bezierPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            bezierPath.line(to: center)
            bezierPath.close()
            
            color.set()
            bezierPath.fill()
            bezierPath.stroke()
        }
        
        image.unlockFocus()
        return image
    }
    
    func buildSpectrumColors(from startColor: NSColor, endColor: NSColor) -> [NSColor] {
        var spectrumColors = [NSColor]()
        var (fromRed, fromGreen, fromBlue) = (CGFloat(0.0), CGFloat(0.0), CGFloat(0.0))
        var (toRed, toGreen, toBlue) = (CGFloat(0.0), CGFloat(0.0), CGFloat(0.0))
        
        let startCol = startColor.usingColorSpace(.sRGB)!
        let endCol = endColor.usingColorSpace(.sRGB)!
        
        startCol.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: nil)
        endCol.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: nil)
        
        let numberOfColours = 10 // numberOfSpectrumColours
        let dRed = (toRed - fromRed) / CGFloat(numberOfColours - 1)
        let dGreen = (toGreen - fromGreen) / CGFloat(numberOfColours - 1)
        let dBlue = (toBlue - fromBlue) / CGFloat(numberOfColours - 1)
        
        for n in 0..<numberOfColours {
            spectrumColors.append(NSColor(red: fromRed + CGFloat(n) * dRed,
                                          green: fromGreen + CGFloat(n) * dGreen,
                                          blue: fromBlue + CGFloat(n) * dBlue, alpha: 1.0))
        }
        
        return spectrumColors
    }
}
*/
