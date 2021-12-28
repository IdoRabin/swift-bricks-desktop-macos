//
//  CircleProgressBaseView.swift
//  Bricks
//
//  Created by Ido on 27/12/2021.
//

import Accelerate
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("CircleProgressBaseView")

class CircleProgressBaseView : NSView {
    
    let DEBUG_DRAWING = IS_DEBUG && false
    let DEBUG_DRAW_MASK_AS_LAYER = IS_DEBUG && false
    let DEBUG_DEV_TIMED_TEST = IS_DEBUG && false
    let DEBUG_SLOW_ANIMATIONS = IS_DEBUG && false
    
    let MAX_WIDTH : CGFloat = 1200.0
    let MAX_HEIGHT : CGFloat = 1200.0
    let MIN_WIDTH : CGFloat = 14.0
    let MIN_HEIGHT : CGFloat = 14.0
    
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
    
    @IBInspectable var backgroundColor  : NSColor = .clear { didSet { updateLayers() } }
    @IBInspectable var bkgRingIsFull : Bool = false { didSet { if bkgRingIsFull != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingWidth : CGFloat = 2.5 { didSet { if bkgRingWidth != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingColor : NSColor = .tertiaryLabelColor.blended(withFraction: 0.2, of: .secondaryLabelColor)! { didSet { if bkgRingColor != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingInset : CGFloat =  1.5 { didSet { if bkgRingInset != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingOpacity : Float =  0.5 { didSet { if bkgRingOpacity != oldValue { updateLayers() } } }
    
    @IBInspectable var progressRingWidth : CGFloat = 2.5 { didSet { if progressRingWidth != oldValue { updateLayers() } } }
    @IBInspectable var progressRingColor : NSColor = .controlAccentColor { didSet { if progressRingColor != oldValue { updateLayers() } } }
    @IBInspectable var progressRingInset : CGFloat = 1.5 { didSet { if progressRingInset != oldValue { updateLayers() } } }
    @IBInspectable var centerOffset : CGPoint = .zero { didSet { if centerOffset != oldValue { updateLayers() } } }
    
    // MARK: Private vars
    private var lastTotalHash : Int = 0
    private var _lastUsedLayersRect : CGRect = .zero
    private var _scale = 2.0
    
    private var _progress = 0.0
    @IBInspectable var progress : CGFloat {
        get { return _progress }
        set { self.setNewProgress(newValue, animated: true) }
    }
    
    var _spinningProgress = 0.0
    @IBInspectable var spinningProgress : CGFloat {
        get { return _spinningProgress }
        set { self.setNewProgress(newValue, animated: true) }
    }
    
    var progressType : ProgressType = .determinate {
        didSet {
            if progressType != oldValue {
                //if !self.progressType.isDeterminate && self.wasShrunkByAnimation != .none {
                //    self.unhideAnimation(duration: UNHIDE_ANIM_DURATION, delay: UNHIDE_ANIM_DELAY)
                //}
                
                if progressType.isSpinable != oldValue.isSpinable {
                    dlog?.info(">> \(progressType.isSpinable ? "Starting" : "Stopping") spinning state")
                    self.setNewProgress(progressType.isDeterminate ? _spinningProgress : _progress, animated: true, forced:true)
                    updateSpinAnimations()
                    updateLayers()
                } else if progressType.isSpinable {
                    // We continue spining, we just need to change the fluctuations in the prgeress:
                    switch progressType {
                    case .determinate:
                        break
                    case .determinateSpin:
                        progressRingLayerMask.stopFluctuaingPathLayer()
                    case .indeterminateSpin:
                        progressRingLayerMask.startFluctuaingPathLayer()
                    }
                }
            }
        }
    }
    
    // MARK: - Private Properties
    private var isAnimatingSpin = false
    private var isAnimatingIcon = false
    //private var lastUsedRect : CGRect = .zero
    
    private let rootLayer = CALayer()
    public let ringsLayer = CALayer()
    private let backgroundLayer = CALayer()
    private var bkgRingLayer = CAShapeLayer()
    private var progressRingLayer = CAShapeLayer()
    private var progressRingLayerMask = CAShapeLayer()
    
    // keypathes
    private let basicDisabledKeypathes : [String] = ["position", "frame", "bounds", "zPosition", "anchorPointZ", "contentsScale", "anchorPoint"]
    
    // MARK: Private funcs
    private func setNewProgressStrokeEnd(part:CGFloat, animated:Bool) {
        CATransaction.animate(animated: animated, duration: DEBUG_SLOW_ANIMATIONS ? 0.5 : 0.2) {
            self.progressRingLayerMask.strokeEnd = part
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
    
    private func setNewProgress(_ newVal:CGFloat, animated:Bool = true, forced:Bool = false) {
        let newValue = clamp(value: newVal, lowerlimit: 0.0, upperlimit: 1.0)
        let prev = self.progressType.isSpinable ? _spinningProgress : _progress
        let fraction = newProgressSensitivityFraction()
        let isForcedChange = forced // maybe other test to force the change?
        
        // dlog?.info("newVal=\(newVal) delta:\(abs(newValue - prev)) > frac:\((1.0 / fraction))")
        if (abs(newValue - prev) > (1.0 / fraction)) || isForcedChange {
            if self.progressType.isSpinable {
                _spinningProgress = newValue
            } else {
                _progress = newValue
            }
            
            // Actuallt change the progress mask layer here
            self.setNewProgressStrokeEnd(part: newValue, animated:animated)
            
            if IS_DEBUG {
                let prog = self.progressType == .determinate ? "Progress" : "Spinning progress"
                let hid = [self.isHidden ? "true" : "false"].joined(separator: " ").trimmingCharacters(in: .whitespaces)
                dlog?.info("z setNew: \(prog)=\(newValue) animated: \(animated) hidden: \(hid) forced: \(forced)")
            }
        }
    }
    
    private func calcRectForLayers()->CGRect {
        let rect = self.frame.boundsRect().boundedSquare().insetBy(dx: 0, dy: 0).offset(by: self.centerOffset).rounded()
        
        if !rect.isEmpty && !rect.isInfinite &&
            rect.width >= MIN_WIDTH && rect.width < MAX_WIDTH &&
            rect.height >= MIN_HEIGHT && rect.height < MAX_HEIGHT {
            return rect
        }
        
        if (self.bounds.width < MIN_WIDTH || self.bounds.height < MIN_HEIGHT) &&
            _lastUsedLayersRect.isEmpty == false &&
            _lastUsedLayersRect.width >= MIN_WIDTH &&
            _lastUsedLayersRect.height >= MIN_HEIGHT {
            return _lastUsedLayersRect
        }
        
        return self.bounds
    }
    
    // MARK: Hashable
    public override var hash: Int {
        var result : Int = self.frame.hashValue
        
        result = result ^ backgroundColor.hashValue ^ bkgRingWidth.hashValue ^ bkgRingColor.hashValue ^ bkgRingInset.hashValue ^ bkgRingOpacity.hashValue ^ self.bounds.width.hashValue
        
        result = result ^ progressRingWidth.hashValue ^ progressRingColor.hashValue ^ progressRingInset.hashValue ^ centerOffset.hashValue
        
        result = result ^ _spinningProgress.hashValue ^ _progress.hashValue ^ _scale.hashValue
        
        return result
    }
    
    // MARK: Spinner animations
    private func startSpinAnimations() {
        
        let layer = DEBUG_DRAW_MASK_AS_LAYER ? progressRingLayerMask : progressRingLayer
        layer.centerizeAnchor(animated: false, preventMoving: false)
        switch progressType {
        case .determinate:
            dlog?.note("startSpinAnimations called for progressType .none!")
            
        case .determinateSpin:
            dlog?.info("startSpinAnimations - simple")
            layer.startSpinAnimation(duration: DEBUG_SLOW_ANIMATIONS ? 1.7 : 0.7)
            
        case .indeterminateSpin:
            dlog?.info("startSpinAnimations - fluctuates")
            layer.startSpinAnimation(duration: DEBUG_SLOW_ANIMATIONS ? 1.7 : 0.7)
            progressRingLayerMask.startFluctuaingPathLayer(duration:DEBUG_SLOW_ANIMATIONS ? 2.0 : 1.0)
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
    
    // MARK: - private Updates
    private var nativeInset : CGFloat {
        return 0.5
    }
    
    private var bkgRingTotalInset : CGFloat {
        return bkgRingInset + (bkgRingWidth * 0.5) + nativeInset
    }
    
    private var progressRingTotalInset : CGFloat {
        return progressRingInset + (progressRingWidth * 0.5) + nativeInset
    }
    
    private var lastBkgHash : Int = 0
    func updateBackgroundLayer(rect: CGRect) {
        let newBkgHash = backgroundColor.hashValue ^ rect.hashValue ^ _scale.hashValue
        if lastBkgHash != newBkgHash {
            lastBkgHash = newBkgHash
            
            dlog?.info("updateBackgroundLayer \(rect)")
            backgroundLayer.frame = rect.boundsRect()
            backgroundLayer.backgroundColor = self.backgroundColor.cgColor
            backgroundLayer.disableActions(for: basicDisabledKeypathes)
            
            if DEBUG_DRAWING {
                // backgroundLayer.backgroundColor = NSColor.green.withAlphaComponent(0.2).cgColor
            }
        }
    }
    
    private var lastBkgRingHash : Int = 0
    func updateBkgRingLayer(rect: CGRect) {
        let newBkgRingHash = bkgRingInset.hashValue ^ bkgRingColor.hashValue ^ bkgRingWidth.hashValue ^ _scale.hashValue ^ bkgRingOpacity.hashValue ^ rect.hashValue
        
        if lastBkgRingHash != newBkgRingHash {
            lastBkgRingHash = newBkgRingHash
            
            // Bkg ring - full / empty circle
            let rct = rect.boundsRect().insetBy(dx: bkgRingTotalInset, dy: bkgRingTotalInset)
            dlog?.info("updateBkgRingLayer \(rct)")
            
            bkgRingLayer.path = CGPath(ellipseIn: rct, transform: nil)
            bkgRingLayer.backgroundColor = .clear
            
            let xfillColor = bkgRingColor.cgColor
            
            if bkgRingIsFull {
                bkgRingLayer.strokeColor = .clear
                bkgRingLayer.lineWidth = 0.0
                bkgRingLayer.fillColor = xfillColor
            } else {
                bkgRingLayer.fillColor = .clear
                bkgRingLayer.strokeColor = xfillColor
                bkgRingLayer.lineWidth = bkgRingWidth /// _scale
            }
            
            bkgRingLayer.disableActions(for: basicDisabledKeypathes)
            bkgRingLayer.opacity = clamp(value: bkgRingOpacity, lowerlimit: 0.0, upperlimit: 1.0, outOfBounds: { val in
                dlog?.note("bkgRingOpacity out of bounds: \(val) should be between 0.0 and 1.0")
            })
        }
    }
    
    private var lastProgressRingHash : Int = 0
    func updateProgressRingLayer(rect: CGRect) {
        let newProgressRingHash = progressRingInset.hashValue ^ progressRingWidth.hashValue ^ rect.hashValue ^ _scale.hashValue ^ bkgRingIsFull.hashValue
        
        if lastProgressRingHash != newProgressRingHash {
            lastProgressRingHash = newProgressRingHash
            
            
            
            // Bkg ring - full / empty circle
            let rct = rect.boundsRect().insetBy(dx: progressRingTotalInset, dy: progressRingTotalInset)
            dlog?.info("updateProgressRingLayer \(rct)")
            
            progressRingLayer.path = CGPath(ellipseIn: rct, transform: nil)
            progressRingLayer.backgroundColor = .clear
            
            if bkgRingIsFull {
                progressRingLayer.strokeColor = .clear
                progressRingLayer.lineWidth = 0.0
                progressRingLayer.fillColor = progressRingColor.cgColor
            } else {
                progressRingLayer.fillColor = .clear
                progressRingLayer.strokeColor = progressRingColor.cgColor
                progressRingLayer.lineWidth = progressRingWidth // / _scale
            }
            
            progressRingLayer.disableActions(for: basicDisabledKeypathes)
            progressRingLayer.opacity = 1.0
            progressRingLayer.bounds = rect
            progressRingLayer.actions = ["lineWidth": CABasicAnimation(), "path": CABasicAnimation()]
        }
    }
    
    private var lastProgressRingMaskHash : Int = 0
    func updateProgressRingLayerMask(rect:CGRect) {
        guard !rect.isNull && !rect.isInfinite else {
            return
        }
        
        let newProgressRingMaskHash = rect.hashValue ^ progressRingInset.hashValue ^ progressRingWidth.hashValue ^ _scale.hashValue
        if lastProgressRingMaskHash != newProgressRingMaskHash {
            lastProgressRingMaskHash = newProgressRingMaskHash
            
            let mask = self.progressRingLayerMask
            let isFirstTime = (mask.path == nil)
            
            var rct = rect.boundsRect().insetBy(dx: progressRingTotalInset, dy: progressRingTotalInset).rounded()
            if rct.isInfinite || rct.isNull {
                rct = rect
            }
            
            mask.fillColor = NSColor.clear.cgColor
            mask.strokeColor = NSColor.black.cgColor
            mask.lineWidth = (self.progressRingWidth) /// _scale
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
            var logAddedInfo = ""
            if isFirstTime {
                logAddedInfo = "SETUP progress was: \(round(self.progress * 100))%"
                mask.strokeEnd = self.progress
            }
            
            if IS_DEBUG {
                dlog?.info("updateProgressRingLayerMask \(rct) \(logAddedInfo)")
            }
            
        }
    }
    
    func updateLayers(rectForLayers:CGRect? = nil) {
        
        var rect = CGRect.zero
        if let rectForLayers = rectForLayers {
            rect = rectForLayers
        } else {
            rect = self.calcRectForLayers()
        }
        
        if rect.width < MIN_WIDTH || rect.height < MIN_HEIGHT {
            return
        }
        
        let newTotalHash = self.hash
        if (lastTotalHash != newTotalHash) || (rect != _lastUsedLayersRect) {
            lastTotalHash = newTotalHash
            if rect.width < MIN_WIDTH || rect.height < MIN_HEIGHT {
                rect = CGRect(origin: .zero, size: CGSize(width: MIN_WIDTH, height: MIN_HEIGHT))
            }
            if self.layer != rootLayer {
                self.layer = rootLayer
            }
            
            ringsLayer.frame = rect
            _lastUsedLayersRect = rect
            
            CATransaction.noAnimation {
                dlog?.info("updateLayers START bounds: \(rect) isHidden: \(self.isHidden)")
                dlog?.indentedBlock {
                    updateBackgroundLayer(rect: rect)
                    updateBkgRingLayer(rect: rect)
                    updateProgressRingLayer(rect: rect)
                    updateProgressRingLayerMask(rect:rect)
                }
            }
            
            dlog?.info("updateLayers END")
        }
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
    
    private func setupLayersIfNeeded() {
        //  //}, self.window != nil, self.superview != nil, self.bounds.width >= MIN_WIDTH else {
        guard self.layer != rootLayer else {
            return
        }
        
        DispatchQueue.main.performOncePerInstance(self) {
            let rect = self.calcRectForLayers()
            _lastUsedLayersRect = rect
            dlog?.info("setupLayersIfNeeded")
            dlog?.indentedBlock {
                self.layer = rootLayer
                self.wantsLayer = true
                self.layer?.masksToBounds = false
                rootLayer.frame = self.bounds.rounded()
                rootLayer.centerizeAnchor()
                
                if let layer = self.layer {
                    if DEBUG_DRAWING {
                        layer.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.2).cgColor
                        layer.border(color: .systemTeal.withAlphaComponent(0.5), width: 1)
                    }
                }
                dlog?.info("setup bounds: \(self.bounds) rootLayer.anchor:\(rootLayer.anchorPoint) rectForLayers:\(rect)")
                
                // setup ringsLayer
                ringsLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
                ringsLayer.frame = rootLayer.bounds
                if DEBUG_DRAWING {
                    ringsLayer.border(color: .red.withAlphaComponent(0.4), width: 2)
                }
                rootLayer.addSublayer(ringsLayer)
                
                // setuplayers
                let layers = [backgroundLayer, bkgRingLayer, progressRingLayer]
                layers.forEachIndex { index, layer in
                    layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
                    layer.frame = rect.boundsRect()
                    layer.centerizeAnchor()
                    ringsLayer.addSublayer(layer)
                }
                // ringsLayer.centerizeAnchor()
                
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
        }
    }
    
    private func setup() {
        
        DispatchQueue.main.performOncePerInstance(self) {
            setupLayersIfNeeded()
        }
    }
    
    // MARK: - Lifecycle
    
    private func layoutLayers() {
        guard self.superview != nil, self.window != nil else {
            return
        }
        
        var changes = 0
        let rect = self.calcRectForLayers()
        
        // On every layout call:
        CATransaction.noAnimation {
            ringsLayer.frame = rect
            let layers = [backgroundLayer, bkgRingLayer, progressRingLayer]
            
            layers.forEachIndex { index, layer in
                if layer.frame.size != rect.size {
                    layer.frame = rect
                    changes += 1
                }
            }
            if bkgRingLayer.path == nil {
                changes += 1
            }
            
            if changes > 0 {
                dlog?.info("layout START")
                dlog?.indentedBlock {
                    self.updateLayers(rectForLayers: rect)
                    dlog?.indentEnd()
                }
                dlog?.info("layout END")
            } else {
                dlog?.indentEnd()
            }
        }
    }
    
    public override func layout() {
        super.layout()
        self.layoutLayers()
    }
    
    public override func awakeFromNib() {
        DispatchQueue.main.async {
            self.setup()
        }
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
        dlog?.info("deinit")
    }
    
    public override var wantsDefaultClipping: Bool {
        return false
    }
    
    public override var fittingSize: NSSize {
        return intrinsicContentSize
    }
    
    public override var intrinsicContentSize: NSSize {
        var sze = super.intrinsicContentSize
        sze.width = max(sze.width, _lastUsedLayersRect.width)
        sze.height = max(sze.width, _lastUsedLayersRect.height)
        dlog?.info("intrinsicContentSize \(sze)")
        return sze
    }
    
    // MARK: Public funcs
    func presentIcon(image:NSImage, tint:NSColor, bkgColor:NSColor, duration totalDuration:TimeInterval = 1.5, completion:(()->Void)? = nil) {
        self.isAnimatingIcon = true
        let frm = self.bounds.boundedSquare().insetBy(dx: 0.5, dy: 0.5).offsetBy(dx: 0, dy: 0.5)
        let iconImageView = NSImageView(frame: frm)
        
        // Apply .Symbol configuration
        let config = NSImage.SymbolConfiguration(paletteColors: [tint, bkgColor])
        config.applying(.init(pointSize: 42, weight: .black, scale: .large))
        iconImageView.symbolConfiguration = config
        
        // Settings
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.wantsLayer = true
        iconImageView.layer?.transform = CATransform3DScale(CATransform3DIdentity, 0.3, 0.3, 1)
        
        // Circle layer
        let circleLayer = CALayer()
        circleLayer.backgroundColor = NSColor.textBackgroundColor.blended(withFraction: 0.2, of: tint)!.withAlphaComponent(0.5).cgColor
        circleLayer.frame = iconImageView.bounds.boundedSquare().insetBy(dx: 1, dy: 1).rounded()
        circleLayer.border(color: bkgColor, width: 1)
        circleLayer.corner(radius: circleLayer.frame.width * 0.5)
        iconImageView.layer?.insertSublayer(circleLayer, below: nil)
        circleLayer.centerizeAnchor()
        iconImageView.image = image
        
        // Show / hide
        self.addSubview(iconImageView)
        self.ringsLayer.opacity = 0.0
        iconImageView.layer?.centerizeAnchor()
        
        // Animate appear, bump and hide
        dlog?.info("presentIcon START")
        let durationA = totalDuration * 0.3
        let delay = totalDuration * 0.3
        let durationB = totalDuration * 0.4
        NSView.animate(duration: durationA, delay: 0.01) { context in
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            iconImageView.layer?.transform = CATransform3DIdentity
        } completionHandler: {
            //dlog?.info("presentIcon MID")
            iconImageView.layer?.centerizeAnchor()
            
            NSView.animate(duration: durationB, delay: delay) { context in
                context.allowsImplicitAnimation = true
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                iconImageView.layer?.transform = CATransform3DScale(CATransform3DIdentity, 0.3, 0.3, 1)
                iconImageView.layer?.opacity = 0.0
                self.isAnimatingIcon = false
                completion?()
            } completionHandler: {
                dlog?.info("presentIcon DONE")
                DispatchQueue.main.async {
                    circleLayer.removeFromSuperlayer()
                    iconImageView.removeFromSuperview()
                    self.ringsLayer.opacity = 1.0
                }
            }
        }
        
    }
}

extension CircleProgressBaseView /* debug */ {
    func devTestIfNeeded() {
        guard DEBUG_DEV_TIMED_TEST else {
            return
        }
        
        self.progressType = .determinate
        let delay : TimeInterval = 1.0
        DispatchQueue.main.asyncAfter(delayFromNow: delay + 0.1) {
            dlog?.info("DEBUG_DEV_TIMED_TEST")
            self.progress = 0.25
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: delay + 0.5) {
            self.progressType = .determinateSpin
            self.progress = 0.5
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: delay + 2.5) {
            self.progressType = .indeterminateSpin
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: delay + 4.5) {
            self.progressType = .determinate
        }
    }
}
