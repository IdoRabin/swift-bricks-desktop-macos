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
    let DEBUG_DRAWING = IS_DEBUG && true
    let DEBUG_DEV_TIMED_TEST = IS_DEBUG && true
    let DEBUG_SLOW_ANIMATIONS = IS_DEBUG && true
    
    let SHRINK_ANIM_DURATION : TimeInterval = 0.4
    let SHRINK_ANIM_DELAY : TimeInterval = 0.2
    let UNSHRINK_ANIM_DURATION : TimeInterval = 0.3
    let UNSHRINK_ANIM_DELAY : TimeInterval = 0.1
    
    /// Determines type of animation to perform when hiding/showing the view. All values except .none will mean that as progress value changes, we will-auto hide/show the circle with the appropriate animation.
    /// *case none*: will not animate shrink/unshrink while hiding / unhiding
    /// *case shrinkToLeading*: will animate the progress rings to shrink / unshrink to the leading verical center.
    /// *case shrinkToCenter*: will animate the progress rings to shrink / unshrink to the horitontal and verical center.
    /// *case shrinkToTrailing*: will animate the progress rings to shrink / unshrink to the trailing verical center.
    enum ShrinkAnimationType {
        case none
        case shrinkToLeading
        case shrinkToCenter
        case shrinkToTrailing
        
        var isNone : Bool {
            return self == .none
        }
    }
    
    private enum ShrinkDirection {
        case shrink
        case unshrink
        case none
        var isNone : Bool {
            return self == .none
        }
        var isShrink : Bool {
            return self == .shrink
        }
        var isUnshrink : Bool {
            return self == .unshrink
        }
    }
    
    // MARK: Inspectables properties
    @IBInspectable var backgroundColor  : NSColor {
        get { return baseView.backgroundColor}
        set { baseView.backgroundColor = newValue }
    }
    @IBInspectable var bkgRingIsFull : Bool {
        get { return baseView.bkgRingIsFull}
        set { baseView.bkgRingIsFull = newValue }
    }
    @IBInspectable var bkgRingWidth : CGFloat {
        get { return baseView.bkgRingWidth}
        set { baseView.bkgRingWidth = newValue }
    }
    @IBInspectable var bkgRingColor : NSColor {
        get { return baseView.bkgRingColor}
        set { baseView.bkgRingColor = newValue }
    }
    @IBInspectable var bkgRingInset : CGFloat {
        get { return baseView.bkgRingInset}
        set { baseView.bkgRingInset = newValue }
    }
    @IBInspectable var bkgRingOpacity : Float {
        get { return baseView.bkgRingOpacity}
        set { baseView.bkgRingOpacity = newValue }
    }
    @IBInspectable var progressRingWidth : CGFloat {
        get { return baseView.progressRingWidth}
        set { baseView.progressRingWidth = newValue }
    }
    @IBInspectable var progressRingColor : NSColor {
        get { return baseView.progressRingColor}
        set { baseView.progressRingColor = newValue }
    }
    @IBInspectable var progressRingInset : CGFloat {
        get { return baseView.progressRingInset}
        set { baseView.progressRingInset = newValue }
    }
    @IBInspectable var centerOffset : CGPoint {
        get { return baseView.centerOffset}
        set { baseView.centerOffset = newValue }
    }
    
    // Direct pass of property
    @IBInspectable var progress : CGFloat {
        get { return baseView.progress}
        set { baseView.progress = newValue }
    }
    
    var  progressType : CircleProgressBaseView.ProgressType {
        get { return baseView.progressType}
        set { baseView.progressType = newValue }
    }
    
    public override var isHidden: Bool {
        get { return super.isHidden }
        set { /* TODO: self.setIsHidden(newValue, animated: self.window != nil, isForced: false) */ }
    }
        
    private var _isContentsShrunk: Bool = true
    public var isContentsShrunk: Bool  {
        get {  return _isContentsShrunk }
        set {
            if newValue != isContentsShrunk {
                self.setIsShrunk(newValue, animated: (self.window != nil), isForced: true, isDelay: false)
            }
        }
    }
    
    @IBInspectable var isAutoShrinksOn100 : Bool = false
    @IBInspectable var isAutoUnshrinksOnGt0 : Bool = true // when progress changes to greater than 0.0
    
    // MARK: Outlets
    @IBOutlet weak var widthConstraint : NSLayoutConstraint? = nil
   
    // MARK: - Private Properties
    private var isAnimatingShrink = false
    private var wasShrunkByAnimation: ShrinkAnimationType = .none
    private var widthBeforeLastHideOrShrinkAnimation: CGFloat = 28
    private var baseviewLastUnshrunkRect : CGRect = .zero
    
    // MARK: Public properties
    /// Determines type of animation to perform when hiding/showing the view. All values except .none will mean that as progress value changes, we will-auto hide/show the circle with the appropriate animation.
    var shrinkAnimationType : ShrinkAnimationType = .shrinkToLeading
    weak var _baseView : CircleProgressBaseView? = nil
    var baseView : CircleProgressBaseView {
        get {
            // Lazy
            self.createBaseviewIfNeeded()
            return _baseView!
        }
    }
    
    // MARK: Evented properties
    var onBeforeShrinking: (( _ animated:Bool)->Void)? = nil
    var onShrinking: ((NSAnimationContext?)->Void)? = nil
    var onBeforeUnshrinking: (( _ animated:Bool)->Void)? = nil
    var onUnshrinking: ((NSAnimationContext?)->Void)? = nil
    
    // MARK: Private funcs
    private func createBaseviewIfNeeded() {
        if self._baseView == nil {
            let rect = self.frame.boundsRect().boundedSquare()
            let baseview = CircleProgressBaseView(frame:rect)
            baseview.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(baseview)
            _baseView = baseview
        }
    }
    
    private func setup() {
        DispatchQueue.main.performOncePerInstance(self) {
            
            self.createBaseviewIfNeeded()
            
            if DEBUG_DRAWING {
                self.debugBorder(color: .systemBlue.withAlphaComponent(0.4), width: 1)
                baseView.debugBorder(color: .systemTeal.withAlphaComponent(0.5), width: 1)
            }
        }
    }
    
    private func afterFirstLayoutIfNeeded() {
        guard self.superview != nil && self.window != nil else {
            return
        }
        
        DispatchQueue.main.performOncePerInstance(self) {
            dlog?.info("firstLayoutIfNeeded START")
            var shrinkDir : ShrinkDirection = .none
            dlog?.indentedBlock {
                if self.isContentsShrunk {
                    shrinkDir = .shrink
                    if isAutoUnshrinksOnGt0 && self.progress > 0.0 {
                        shrinkDir = .unshrink
                        dlog?.note("Ambigious init - started with self.isContentsShrunk == true, but with isAutoUnshrinksOnGt0 and self.progress > 0.0")
                    }
                } else {
                    shrinkDir = .unshrink
                    if isAutoShrinksOn100 && self.progress > 1.0 {
                        dlog?.note("Ambigious init - started with self.isContentsShrunk == false, but with isAutoUnshrinksOn100 and self.progress > 1.0")
                        shrinkDir = .shrink
                    }
                }
                
                dlog?.info("firstLayoutIfNeeded direction: \(shrinkDir)")
            }
            dlog?.info("firstLayoutIfNeeded DONE")
            self.saveWidthBeforeHideOrShrink(forced: true)
            
            DispatchQueue.main.async {
                switch shrinkDir {
                case .shrink:
                    self.setIsShrunk(true, animated: false, isForced: true, isDelay: false, completion: nil)
                case .unshrink:
                    // No need to unshrink on first layout - we assume first ever layout left us in "unshrunk" state.
                    dlog?.info(">> no need to unshrink on first layout")
                    break
                case .none:
                    break
                }
            }
            
        }
    }
    
    // MARK: - Lifecycle
    public override func layout() {
        super.layout()
        
        if baseView.constraints.count <= 2 {
            widthBeforeLastHideOrShrinkAnimation = self.bounds.width
            
            dlog?.info("layout setting up constraints:")
            baseView.removeConstraints(baseView.constraints)
            baseView.frame = self.bounds.boundedSquare()
            
            baseView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            baseView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            
            // Aspect ratio of 1.0
            baseView.addConstraint(NSLayoutConstraint(item: baseView,
                                                      attribute: .height,
                                                      relatedBy: .equal,
                                                      toItem: baseView,
                                                      attribute: .width,
                                                      multiplier: 1.0,
                                                      constant: 0))
            baseView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 1.0, constant: -1).isActive = true
            baseView.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: 1.0, constant: -1).isActive = true
            
            self.afterFirstLayoutIfNeeded()
        }
    }
    
    public override func awakeFromNib() {
        self.setup()
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        clearAllClosureProperties()
        _baseView?.removeFromSuperview()
    }
    
    // MARK: Public
    func clearAllClosureProperties() {
        self.onBeforeShrinking = nil
        self.onShrinking = nil
        self.onBeforeUnshrinking = nil
        self.onUnshrinking = nil
    }
    
    func presentIcon(image:NSImage, tint:NSColor, bkgColor:NSColor, duration:TimeInterval = 1.5, completion:(()->Void)? = nil) {
        baseView.presentIcon(image: image, tint: tint, bkgColor: bkgColor, duration: duration, completion: completion)
    }
    
    // MARK: Shrink / Unshrink
    private func saveWidthBeforeHideOrShrink(forced:Bool = false) {
        if !isAnimatingShrink && (self.isContentsShrunk == false || forced) {
            widthBeforeLastHideOrShrinkAnimation = baseView.MIN_WIDTH
            baseviewLastUnshrunkRect = baseView.frame
            if let constr = self.widthConstraint?.constant, constr >= baseView.MIN_WIDTH {
                widthBeforeLastHideOrShrinkAnimation = constr
            }
        } else {
            dlog?.note("saveWidthBeforeHideOrShrink cannot save when isAnimatingShrink == true")
        }
    }
    
    private func getSufficientSuperview(inView:NSView, depth:Int)->NSView? {
        guard depth < 7, let suprV = inView.superview else {
            //dlog?.info("getSufficientSuperview found:\(inView.basicDesc)")
            return inView
        }
        
        return getSufficientSuperview(inView: suprV, depth: depth + 1)
    }
    
    private func transformForShrinking()->CATransform3D {
        
        if baseviewLastUnshrunkRect.isEmpty &&
            baseView.frame.width  >= baseView.MIN_WIDTH &&
            baseView.frame.height >= baseView.MIN_HEIGHT
        {
            // Save fallback
            baseviewLastUnshrunkRect = baseView.frame
        }
        
        // We caluclate the size of a few pixels out of the while frame, this is the minimum scale that we anyway can present.
        var scale = min(3 / max(baseviewLastUnshrunkRect.width, 2), 0.2)
        if DEBUG_DRAWING {
            scale = 0.5
        }
        let invScale = (1 - scale)
        let newRect = self.baseView.layer!.frame.scaledAroundCenter(scale, scale)
        
        let w : CGFloat = self.bounds.width  - 1.4*newRect.width
        let h : CGFloat = 0.0 // self.bounds.height - 1.4*newRect.height
        
        var transform = CATransform3DIdentity
        
        // Translate
        switch self.shrinkAnimationType {
        case .shrinkToCenter, .none:
            transform = CATransform3DTranslate(transform, 0, -h, 0)
        case .shrinkToLeading:
            transform = CATransform3DTranslate(transform, IS_RTL_LAYOUT ? w : -w, -h, 0)
        case .shrinkToTrailing:
            transform = CATransform3DTranslate(transform, IS_RTL_LAYOUT ? -w : w, -h, 0)
        }
        
        // Scale
        transform = CATransform3DScale(transform, scale, scale, 1)
        
        DispatchQueue.main.asyncAfter(delayFromNow: 0.3) {
            dlog?.info("ha!:\n  \(newRect)\n  \(self.baseView.layer!.frame)")
        }
        
        return transform
    }
    
    func setIsShrunk(_ isShrink:Bool, animated:Bool = true, isForced:Bool, isDelay:Bool = true, completion:(()->Void)? = nil) {
        if self._isContentsShrunk != isShrink || isForced {
            
            
            let operName = isShrink ? "Shrink" : "Unshrink"
            dlog?.info("setIsShrunk to:[\(operName)] animated:\(animated) isForced:\(isForced) isDelay:\(isDelay) cur progress:\(progress)")
            
            // Get info required before operation starts:
            let newTransform = isShrink ? self.transformForShrinking() :  CATransform3DIdentity
            let xuprview = getSufficientSuperview(inView: self, depth: 0)
            let animationMultiplier = DEBUG_SLOW_ANIMATIONS ?  4.0 : 1.0
            let duration : TimeInterval = animationMultiplier * (isShrink ? SHRINK_ANIM_DURATION : UNSHRINK_ANIM_DURATION)
            let delay : TimeInterval    = animationMultiplier * (isDelay ? SHRINK_ANIM_DELAY : UNSHRINK_ANIM_DURATION)
            
            // Start operation if not in the middle of another
            if !isAnimatingShrink && !self.shrinkAnimationType.isNone {
                func start() {
                    // Before animations start:
                    self.saveWidthBeforeHideOrShrink(forced: isForced)
                    isAnimatingShrink = true
                    if isShrink {
                        onBeforeShrinking?(animated)
                    } else {
                        onBeforeUnshrinking?(animated)
                    }
                    
                    // Change flag:
                    self._isContentsShrunk = isShrink
                }
                
                func executeChanges(context:NSAnimationContext?) {
                    self.baseView.layer?.centerizeAnchor()
                    self.baseView.layer?.transform = newTransform
                }
                
                func finalize() {
                    self.wasShrunkByAnimation = self.shrinkAnimationType
                    isAnimatingShrink = false
                    completion?()
                }
                
                start()
                if animated {
                    
                    dlog?.info("operation \(operName) START")
                    dlog?.indentStart()
                    NSView.animate(duration: duration, delay: delay) { context in
                        
                        // Changes
                        context.allowsImplicitAnimation = true
                        executeChanges(context: context)
                        
                        if let supr = xuprview {
                            // Will probably not cause window resize
                            supr.layoutSubtreeIfNeeded()
                        } else {
                            // May cause window resize
                            self.window?.layoutIfNeeded()
                        }
                        
                        // External changes
                        if isShrink {
                            self.onShrinking?(context)
                        } else {
                            self.onUnshrinking?(context)
                        }
                        
                    } completionHandler: {
                        
                        // Done
                        finalize()
                        dlog?.indentEnd()
                        dlog?.info("operation \(operName) END")
                    }
                } else {
                    
                    // Changes
                    CATransaction.noAnimation {
                        executeChanges(context: nil)
                    }
                    
                    // Done
                    finalize()
                }
                
            } else if !shrinkAnimationType.isNone {
                dlog?.note("Already in the middle of a shrink / unshrink animation!")
                DispatchQueue.main.asyncAfter(delayFromNow: duration + delay + 0.01) {
                    if self._isContentsShrunk != isShrink {
                        self.setIsShrunk(isShrink, animated: animated, isForced: true, isDelay: isDelay, completion: completion)
                    }
                }
            }
        }
    }
    
    public func shrink(animated:Bool = true, completion:(()->Void)? = nil) {
        self.setIsShrunk(true, animated: true, isForced: false, isDelay: false)
    }
    
    public func unshrink(animated:Bool = true, completion:(()->Void)? = nil) {
        self.setIsShrunk(false, animated: true, isForced: false, isDelay: false)
    }
}

//
//    public override var frame: NSRect { didSet { if frame != oldValue { layout() }  } }
//
//    private var startedHiddden : Bool = false
//
//    public override func viewDidMoveToWindow() {
//        super.viewDidMoveToWindow()
//
//        guard self.window != nil, let screen = self.window?.screen else {
//            return
//        }
//
//        let val = clamp(value: self.window?.backingScaleFactor ?? screen.backingScaleFactor, lowerlimit: 0.01, upperlimit: 4.0)
//        if self._scale != val {
//            self._scale = val
//        }
//        DispatchQueue.main.performOncePerInstance(self) {
//            self.setupIfNeeded()
//        }
//    }

//
//    // MARK: - private Updates
//    // MARK: - private setup

//
//    private func setupIfNeeded() {
//        guard self.layer != rootLayer else {
//            return
//        }
//        self.setup()
//    }

//    private func hideAnimation(duration:TimeInterval, delay:TimeInterval, completion:(()->Void)? = nil) {
//
////        if !isAnimatingShrink {
////            isAnimatingShrink = true
////            dlog?.info("hideAnimation duration:\(duration) delay:\(delay)")
////
////            rootLayer.centerizeAnchor(animated: false)
////            ringsLayer.centerizeAnchor(animated: false)
////
////            let supr = self.superview?.superview?.superview?.superview ?? self.superview?.superview?.superview ?? self.superview?.superview ?? self.superview
////            let finalTransform = self.transformForHiding()
////
////            self.saveWidthBeforeHide()
////            onBeforeHideAnimating?()
////            NSView.animate(duration: duration, delay: delay) { context in
////                dlog?.info("hideAnimation START")
////                context.allowsImplicitAnimation = true
////
////
////                self.ringsLayer.transform = finalTransform
////                self.widthConstraint?.constant = 1.0
////                self.onHideAnimating?(context)
////
////                if let supr = supr {
////                    // Will probably not cause window resize
////                    supr.layoutSubtreeIfNeeded()
////                } else {
////                    // May cause window resize
////                    self.window?.layoutIfNeeded()
////                }
////
////            } completionHandler: {[weak self] in
////                if let self = self {
////
////                    dlog?.info("hideAnimation DONE")
////                    self.rootLayer.removeAllAnimations()
////                    self.isHidden = true
////                    self.isAnimatingShrink = false
////                    self.wasShrunkByAnimation = self.shrinkAnimationType
////                    completion?()
////
////                    if self.isHidden == false {
////                        self.setIsHidden(false, animated: true, isForced: true)
////                    }
////                }
////            }
////        }
//    }
//
//    private func unhideAnimation(duration:TimeInterval, delay:TimeInterval, completion:(()->Void)? = nil) {
////        if !isAnimatingShrink {
////            isAnimatingShrink = true
////            dlog?.info("unhideAnimation duration: \(duration) delay:\(delay)")
////
////            rootLayer.centerizeAnchor(animated: false)
////            ringsLayer.centerizeAnchor(animated: false)
////
////            let supr = self.superview?.superview?.superview?.superview ?? self.superview?.superview?.superview ?? self.superview?.superview ?? self.superview
////
////            onBeforeUnhideAnimating?()
////            self.isHidden = false
////            NSView.animate(duration: duration, delay: delay) {[self] context in
////                dlog?.info("unhideAnimation START")
////                dlog?.indentStart()
////                context.allowsImplicitAnimation = true
////                ringsLayer.transform = CATransform3DIdentity
////                widthConstraint?.constant = widthBeforeLastHideOrShrinkAnimation
////                ringsLayer.frame = self.rectForLayers()
////                ringsLayer.centerizeAnchor()
////                self.onUnhideAnimating?(context)
////
////                if let supr = supr {
////                    // Will probably not cause window resize
////                    supr.layoutSubtreeIfNeeded()
////                } else {
////                    // May cause window resize
////                    self.window?.layoutIfNeeded()
////                }
////
////            } completionHandler: {[weak self] in
////                if let self = self {
////
////                    self.rootLayer.removeAllAnimations()
////                    self.isAnimatingShrink = false
////                    self.wasShrunkByAnimation = .none
////                    completion?()
////
////                    if self.isHidden == true {
////                        self.setIsHidden(true, animated: true, isForced: true)
////                    }
////                    dlog?.indentEnd()
////                    dlog?.info("unhideAnimation DONE")
////
////                    for layer in [self.ringsLayer, self.backgroundLayer, self.bkgRingLayer, self.progressRingLayer, self.progressRingLayerMask] {
////                        layer.setNeedsLayout()
//////                        let scaleX = layer.value(forKeyPath: "transform.scale.x") as? CGFloat
//////                        let scaleY = layer.value(forKeyPath: "transform.scale.y") as? CGFloat
//////                        // dlog?.info("layer : \(layer.frame) \(layer.bounds) \(scaleX.descOrNil) \(scaleY.descOrNil)")
//////                        if let layer = layer as? CAShapeLayer {
//////                            dlog?.info("layer : \(layer.path)")
//////                        }
////                    }
////                }
////            }
////        }
//    }
//


//
//    private func calcAutoShrinkDirection(prevProgress:CGFloat, newProgress:CGFloat)->ShrinkDirection {
//        guard progressType.isDeterminate else {
//            return .none
//        }
//        var result : ShrinkDirection = .none
//        let shouldAutoUnshrink  = (isAutoUnshrinksOnGt0 && prevProgress == 0.0 && newProgress > 0.0)  && !shrinkAnimationType.isNone
//        let shouldAutoShrink    = (isAutoShrinksOn100   && prevProgress < 1.0  && newProgress >= 1.0) && !shrinkAnimationType.isNone
//        if shouldAutoShrink {
//            result = .shrink
//        }
//        if shouldAutoUnshrink {
//            result = .unshrink
//
//            if IS_DEBUG && shouldAutoShrink {
//                dlog?.note("calcAutoShrinkDirection shouldAutoUnshrink and shouldAutoShrink should not be both true!")
//            }
//        }
//        return result
//    }
//
//    public func resetToZero(animated:Bool = true, hides:Bool = true, completion:(()->Void)? = nil) {
////        self._progress = 0
////        self._spinningProgress = 0
////        self.setNewProgress(0.0, animated: animated, forced: true)
////        if hides {
////            dlog?.info("resetToZero animated : \(animated)")
////            if animated {
////                // Animated hide
////                self.hideAnimation(duration:0.3, delay: 0.001, completion: completion)
////            } else {
////                // Non-Animated
////                CATransaction.begin()
////                CATransaction.setDisableActions(true)
////
////                setNewProgressStrokeEnd(part: 0.0, animated: false)
////                rootLayer.centerizeAnchor(animated: false)
////                ringsLayer.centerizeAnchor(animated: false)
////                widthBeforeLastHideOrShrinkAnimation = self.widthConstraint?.constant ?? self.ringsLayer.bounds.width
////                self.onBeforeShrinking?(animated:false)
////                self.ringsLayer.transform = transformForShrinking()
////                self.widthConstraint?.constant = 1.0
////                self.needsLayout = true
////                self.superview?.needsLayout = true
////                self.superview?.superview?.needsLayout = true
////                self.onShrinking?(nil)
////
////                CATransaction.commit()
////
////                // We make as if we were hidden
////                wasShrunkByAnimation = shrinkAnimationType
////
////                // DispatchQueue.main.async
////                completion?()
////            }
////        } else {
////            completion?()
////        }
//    }
//
//    // MARK: Dev / Debug
//    func devTestIfNeeded() {
//        guard DEBUG_DEV_TIMED_TEST else {
//            return
//        }
//

//
//        DispatchQueue.main.asyncAfter(delayFromNow: delay + 3.0) {
//            self.widthConstraint?.animator().constant = 59
//        }
////        DispatchQueue.main.asyncAfter(delayFromNow: delay + 1.5) {
////            self.progress = 1.0
////        }
////        DispatchQueue.main.asyncAfter(delayFromNow: delay + 3.0) {
////            self.progress = 0.5
////        }
////
////        DispatchQueue.main.asyncAfter(delayFromNow: delay + 3.5) {
////            self.progressType = .determinateSpin
////        }
////        DispatchQueue.main.asyncAfter(delayFromNow: delay + 4.5) {
////            self.progress = 1.0
////        }
////        DispatchQueue.main.asyncAfter(delayFromNow: delay + 4.5) {
////            self.progressType = .indeterminateSpin
////        }
//    }
//}

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
