//
//  CircleProgressView.swift
//  Bricks
//
//  Created by Ido on 27/12/2021.
//

import Accelerate
import AppKit

fileprivate let dlog : DSLogger? = nil // DLog.forClass("CircleProgressBaseView")

fileprivate extension CGRect {
    func encforcingMinimumSqrSze(_ size:CGFloat)->CGRect {
        var result = self
        if result.origin.x.isInfinite || result.origin.x.isNaN ||
            result.origin.y.isInfinite || result.origin.y.isNaN {
            result.origin = .zero
        }
        
        if result.width < size {
            result = result.growAroundCener(widthAdd: size - result.width, heightAdd: 0)
        }
        if result.height < size {
            result = result.growAroundCener(widthAdd: 0, heightAdd: size - result.height)
        }
        return result
    }
}

class CircleProgressView : NSView {
    
    struct IconPresentationInfo {
        let image:NSImage
        let tint:NSColor
        let bkgColor:NSColor
        let duration:TimeInterval
    }
    
    private let DEBUG_DRAWING = Debug.IS_DEBUG && false
    private let DEBUG_DRAW_MASK_AS_LAYER = Debug.IS_DEBUG && false
    private let DEBUG_DEV_TIMED_TEST = Debug.IS_DEBUG && false
    private let DEBUG_SLOW_ANIMATIONS = Debug.IS_DEBUG && false
    
    let MAX_WIDTH : CGFloat = 1200.0
    let MAX_HEIGHT : CGFloat = 1200.0
    let MIN_WIDTH : CGFloat = 6.0
    
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
    @IBInspectable var bkgRingInset : CGFloat =  3.5 { didSet { if bkgRingInset != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingOpacity : Float =  0.5 { didSet { if bkgRingOpacity != oldValue { updateLayers() } } }
    
    @IBInspectable var progressRingWidth : CGFloat = 2.5 { didSet { if progressRingWidth != oldValue { updateLayers() } } }
    @IBInspectable var progressRingColor : NSColor = .controlAccentColor { didSet { if progressRingColor != oldValue { updateLayers() } } }
    @IBInspectable var progressRingInset : CGFloat = 3.5 { didSet { if progressRingInset != oldValue { updateLayers() } } }
    @IBInspectable var centerOffset : CGPoint = .zero { didSet { if centerOffset != oldValue { updateLayers() } } }
    
    @IBInspectable var centerText : String? = nil {
        didSet {
            if centerText != oldValue {
                self.autoAdjustCenterFontIfNeeded(rect:self.ringsLayer.frame)
                self.updateTextLayer(rect: self.calcRectForLayers(), forced: true)
            }
        }
    }
    @IBInspectable var centerTextColor : NSColor = NSColor.secondaryLabelColor.blended(withFraction: 0.4, of: .labelColor)!
    @IBInspectable var centerFont : NSFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    @IBInspectable var isAdjustsCenterFontSizeFor2Digits : Bool = true
    
    // MARK: Private vars
    private var lastTotalHash : Int = 0
    private var _lastUsedLayersRect : CGRect = .zero
    private var _scale = 2.0
    private var minSize = 6.0
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
 
                if progressType.isSpinable != oldValue.isSpinable {
                    // dlog?.info(">> \(progressType.isSpinable ? "Starting" : "Stopping") spinning state")
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
    private let ringsLayer = CALayer()
    private let backgroundLayer = CALayer()
    private var bkgRingLayer = CAShapeLayer()
    private var progressRingLayer = CAShapeLayer()
    private var progressRingLayerMask = CAShapeLayer()
    private var textLayer = CATextLayer()
    
    public var isIconPresented : Bool {
        return isAnimatingIcon
    }
    
    // keypathes
    private let basicDisabledKeypathes : [String] = [] // ["position", "frame", "bounds", "zPosition", "anchorPointZ", "contentsScale", "anchorPoint"]
    
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
            
            //if Debug.IS_DEBUG {
             //   let prog = self.progressType == .determinate ? "Progress" : "Spinning           progress"
             //   let hid = [self.isHidden ? "true" : "false"].joined(separator: "            ").trimmingCharacters(in: .whitespaces)
             //   dlog?.info("z setNew: \(prog)=\(newValue) animated: \(animated) hidden: \(hid)          forced: \(forced)")
            //}
        }
    }
    
    private func calcRectForLayers()->CGRect {
        self.calcMinSize()
        var rect = self.frame.boundsRect().boundedSquare().offset(by: self.centerOffset).rounded()
        let delta = rect.width - minSize
        if delta < 0 {
            rect = rect.growAroundCener(widthAdd: abs(delta), heightAdd: abs(delta))
        }
        return rect
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
            
            // dlog?.info("updateBackgroundLayer \(rect)")
            backgroundLayer.backgroundColor = self.backgroundColor.cgColor
            backgroundLayer.disableActions(for: basicDisabledKeypathes)
            backgroundLayer.frame = self.bounds
            
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
            var rct = rect.insetBy(dx: bkgRingTotalInset, dy: bkgRingTotalInset)
            rct = rct.encforcingMinimumSqrSze(minSize)
            if rct.isNull || rct.isInfinite {
                rct = rect
            }
            // dlog?.info("updateBkgRingLayer \(rct)")
            
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
            var rct = rect.insetBy(dx: progressRingTotalInset, dy: progressRingTotalInset)
            rct = rct.encforcingMinimumSqrSze(minSize)
            if rct.isNull || rct.isInfinite {
                rct = rect
            }
            // dlog?.info("updateProgressRingLayer \(rct)")
            
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
            progressRingLayer.actions = ["lineWidth": CABasicAnimation(), "path": CABasicAnimation()]
            
            progressRingLayer.contentsCenter = bkgRingLayer.contentsCenter
            progressRingLayer.anchorPoint = bkgRingLayer.anchorPoint
            progressRingLayer.frame = bkgRingLayer.frame
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
            
            var rct = rect.insetBy(dx: progressRingTotalInset, dy: progressRingTotalInset).rounded()
            rct = rct.encforcingMinimumSqrSze(minSize)
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
            // dlog?.info("      mask center \(mask.frame.center) bkgLayer center:\(backgroundLayer.frame.center)")
            var logAddedInfo : String = ""
            if isFirstTime {
                logAddedInfo = "SETUP progress was: \(round(self.progress * 100))%"
                mask.strokeEnd = self.progress
            }
            
            if Debug.IS_DEBUG {
                dlog?.info("updateProgressRingLayerMask \(rct) \(logAddedInfo)")
            }
            
        }
    }
    
    private var lastTextLayerHash : Int = 0
    func updateTextLayer(rect:CGRect, forced : Bool = false) {
        guard !rect.isNull && !rect.isInfinite else {
            return
        }
        let newTextLayerHash = rect.hashValue ^ centerFont.pointSize.hashValue ^ centerText.hashValue ^ centerTextColor.hashValue ^ _scale.hashValue ^ isAdjustsCenterFontSizeFor2Digits.hashValue
        
        if lastTextLayerHash != newTextLayerHash || forced {
            lastTextLayerHash = newTextLayerHash
            textLayer.opacity = (rect.width > 6 && rect.height > 6) ? 1.0 : 0.0
            if let centerText = centerText, centerText.count > 0 {
                textLayer.font = centerFont
                textLayer.fontSize = centerFont.pointSize
                textLayer.alignmentMode = .center
                textLayer.foregroundColor = centerTextColor.cgColor
                 
                let frm = centerText.boundingRect(with: rect.size, options: .usesLineFragmentOrigin, attributes: [.font:centerFont], context: nil)
                textLayer.frame = frm.settingNewCenter(rect.center).insetBy(dx: -0.1, dy: -0.1)
                textLayer.string = centerText
                
            }
        }
    }
    
    private func calcMinSize() {
        minSize = [bkgRingInset, progressRingInset, MIN_WIDTH, max(progressRingWidth, bkgRingWidth) + 1.0].max()!
    }
    
    private func updateLayers(rectForLayers:CGRect? = nil) {
        
        var rect = CGRect.zero
        if let rectForLayers = rectForLayers {
            rect = rectForLayers
        } else {
            rect = self.calcRectForLayers()
        }

        
        let newTotalHash = self.hash
        if (lastTotalHash != newTotalHash) || (rect != _lastUsedLayersRect) {
            lastTotalHash = newTotalHash
            if self.layer != rootLayer {
                self.layer = rootLayer
            }
            
            _lastUsedLayersRect = rect
            var rct = self.bounds
            if rct.width < minSize {
                rct = rct.growAroundCener(widthAdd: minSize - rct.width, heightAdd: 0)
            }
            if rct.height < minSize {
                rct = rct.growAroundCener(widthAdd: 0, heightAdd: minSize - rct.height)
            }
            
            self.ringsLayer.frame = rct
            ringsLayer.centerizeAnchor()
            
            self.autoAdjustCenterFontIfNeeded(rect:rct)
            
            dlog?.info("updateLayers START rect: \(rect.size) isHidden: \(self.isHidden) ")
            
            DLog.indentedBlock(logger:dlog) {
                updateBackgroundLayer(rect: rect)
                updateBkgRingLayer(rect: rect)
                updateProgressRingLayer(rect: rect)
                updateProgressRingLayerMask(rect:rect)
                updateTextLayer(rect: rect)
            }
            
            for layer in [backgroundLayer, bkgRingLayer, progressRingLayer, progressRingLayerMask] {
                layer.frame = rct
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
            // dlog?.info("setupLayersIfNeeded")
            DLog.indentedBlock(logger:dlog) {
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
                // dlog?.info("setup bounds: \(self.bounds) rootLayer.anchor:\(rootLayer.anchorPoint) rectForLayers:\(rect)")
                
                // setup ringsLayer
                ringsLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
                ringsLayer.frame = rootLayer.bounds
                if DEBUG_DRAWING {
                    ringsLayer.border(color: .red.withAlphaComponent(0.4), width: 3)
                }
                rootLayer.addSublayer(ringsLayer)
                
                // setuplayers
                let layers = [backgroundLayer, bkgRingLayer, progressRingLayer, textLayer]
                layers.forEachIndex { index, layer in
                    layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
                    layer.frame = rect.boundsRect()
                    layer.centerizeAnchor()
                    ringsLayer.addSublayer(layer)
                }

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
    
    private var _lastAdjustedFontHash = 0
    private func autoAdjustCenterFontIfNeeded(rect:CGRect) {
        guard isAdjustsCenterFontSizeFor2Digits else {
            return
        }
        
        let newHash = rect.scaledAroundCenter(0.5, 0.5).rounded().scaledAroundCenter(2.0, 2.0).hashValue ^ self.centerFont.fontName.hashValue
        if  newHash != _lastAdjustedFontHash && !self.isAnimatingIcon {
            _lastAdjustedFontHash = newHash
            let strVal = (self.centerText ?? "99").paddingLeft(toLength: 2, withPad: "9")
            
            // We want to inset to fit in a circle, not its bounding box:
            // ((diameter)*√2) / 2
            //    let boundingSqrSide = rect.boundedSquare().width
            //    let boundedSqrSide : CGFloat = (boundingSqrSide * 1.41421) / 2.0
            //    let inset = abs(boundingSqrSide - boundedSqrSide)
            //    DLog.ui.info("ratio: \(boundedSqrSide) / \(boundingSqrSide) = \(boundedSqrSide / boundingSqrSide )")
            // NOTE: The ratio between the side of a binding square for a circle and the side of the square bound by the circle is ALWAYS 0.707105
            // - which is 1/1.41421 .. i.e. 1/sqrt(2)
            // regardless of size of circle etc..
            let rect = rect.boundedSquare().scaledAroundCenter(0.707105, 0.707105).rounded().insetBy(dx: 3, dy: 3)
            let newFont = strVal.getBestFittingFont(forBoundingSize: rect.size, baseFont: self.centerFont, forceInitialSize: self.centerFont.pointSize)
            centerFont = newFont
            // DLog.ui.info("autoAdjustCenterFontIfNeeded    best fit font size: \(centerFont.pointSize)")
        }
    }
    
    // MARK: - Lifecycle
    
    private func layoutLayers() {
        guard self.superview != nil, self.window != nil else {
            return
        }
        
        let rect = self.calcRectForLayers()
        // dlog?.info("layoutLayers in bounds:\(self.bounds.size) rect:\(rect.size)")
        self.updateLayers(rectForLayers: rect)
    }
    
    public override var frame : CGRect {
        get {
            return super.frame
        }
        set {
            if super.frame != newValue {
                super.frame = newValue
                self.updateLayers()
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
    
    // MARK: Public funcs
    func presentIcon(info:IconPresentationInfo?, completion:(()->Void)? = nil) {
        if let info = info {
            self.presentIcon(image: info.image, tint: info.tint, bkgColor: info.bkgColor, duration: info.duration, completion: completion)
        } else {
            completion?()
        }
    }
    
    func presentIcon(image:NSImage, tint:NSColor, bkgColor:NSColor, duration totalDuration:TimeInterval = 1.5, completion:(()->Void)? = nil) {
        guard self.frame.width > 1 else {
            dlog?.note("presentIcon was called when bounds were too small \(self.bounds)")
            return
        }
        
        guard isAnimatingIcon == false else {
            DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
                self.presentIcon(image: image, tint: tint, bkgColor: bkgColor, duration: totalDuration, completion: completion)
            }
            return
        }
        
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
            context.allowsImplicitAnimation = false
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            iconImageView.layer?.transform = CATransform3DIdentity
        } completionHandler: {
            dlog?.info("presentIcon MID")
            iconImageView.layer?.centerizeAnchor()
            
            NSView.animate(duration: durationB, delay: delay) { context in
                context.allowsImplicitAnimation = false
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

extension CircleProgressView /* debug */ {
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
            self.progress = 0.95
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: delay + 2.5) {
            self.progressType = .indeterminateSpin
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: delay + 4.5) {
            self.progressType = .determinate
        }
    }
}
