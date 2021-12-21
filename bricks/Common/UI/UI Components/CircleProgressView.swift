//
//  CircleProgressView.swift
//  Bricks
//
//  Created by Ido on 19/12/2021.
//

import AppKit
import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("PieSlice")

// @IBDesignable
final public class CircleProgressView: NSView {
    let DEBUG_DRAWING = true
    let DEBUG_DRAW_MASK_AS_LAYER = false
    let DEBUG_DEV_TIMED_TEST = true
    
    
    let MAX_WIDTH : CGFloat = 1200.0
    let MAX_HEIGHT : CGFloat = 1200.0
    
    // MARK: - Private Properties
    private let rootLayer = CALayer()
    private let backgroundLayer = CALayer()
    private var bkgRingLayer = CAShapeLayer()
    private var progressRingLayer = CAShapeLayer()
    private var progressRingLayerMask = CAShapeLayer()
    private var lastUsedRect : CGRect = .zero
    private var indeterminateAnimating = false
    
    // keypathes
    private let basicDisabledKeypathes = ["position", "frame", "bounds", "zPosition", "anchorPointZ", "contentsScale", "anchorPoint"]
    
    // Inspectables:
    @IBInspectable var backgroundColor  : NSColor = .clear { didSet { updateLayers() } }
    var bkgRingIsFull : Bool = false { didSet { if bkgRingIsFull != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingWidth : CGFloat = 2.0 { didSet { if bkgRingWidth != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingColor : NSColor = .tertiaryLabelColor.blended(withFraction: 0.2, of: .secondaryLabelColor)! { didSet { if bkgRingColor != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingInset : CGFloat =  3.5 { didSet { if bkgRingInset != oldValue { updateLayers() } } }
    @IBInspectable var bkgRingOpacity : Float =  0.5 { didSet { if bkgRingOpacity != oldValue { updateLayers() } } }
    
    @IBInspectable var progressRingWidth : CGFloat = 2.0 { didSet { if progressRingWidth != oldValue { updateLayers() } } }
    @IBInspectable var progressRingColor : NSColor = .controlAccentColor { didSet { if progressRingColor != oldValue { updateLayers() } } }
    @IBInspectable var progressRingInset : CGFloat = 3.5 { didSet { if progressRingInset != oldValue { updateLayers() } } }
    @IBInspectable var centerOffset : CGPoint = .zero { didSet { if centerOffset != oldValue { updateLayers() } } }
    
    var _indeterminateProgress = 0.50
    @IBInspectable var indeterminateProgress : CGFloat {
        get {
            return _indeterminateProgress
        }
        set {
            self.setNewProgress(newValue, animated: true)
        }
    }
        
    @IBInspectable var isIndeterminate : Bool = false {
        didSet {
            if isIndeterminate != oldValue {
                dlog?.info(">> \(isIndeterminate ? "Starting" : "Stopping") indeterminate state")
                self.setNewProgress(isIndeterminate ? _indeterminateProgress : _progress, animated: true, force:true)
                updateIndeterminateAnimations()
                updateLayers()
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
        return sze
    }
    
    // MARK: Hashable
    public override var hash: Int {
        var result : Int = self.frame.hashValue
        result = result ^ backgroundColor.hashValue ^ bkgRingWidth.hashValue ^ bkgRingColor.hashValue ^ bkgRingInset.hashValue ^ bkgRingOpacity.hashValue
        
        result = result ^ progressRingWidth.hashValue ^ progressRingColor.hashValue ^ progressRingInset.hashValue ^ centerOffset.hashValue
        
        result = result ^ _indeterminateProgress.hashValue ^ _progress.hashValue ^ _scale.hashValue
        
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
    
    public override var frame: NSRect { didSet { if frame != oldValue { layout(); updateLayers() }  } }
    
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let screen = self.window?.screen {
            let val = clamp(value: self.window?.backingScaleFactor ?? screen.backingScaleFactor, lowerlimit: 0.01, upperlimit: 4.0)
            if self._scale != val {
                self._scale = val
            }
            self.updateLayers()
        }
    }
    
    public override func layout() {
        super.layout()
        let rect = self.rectForLayers()
        let layers = [backgroundLayer, bkgRingLayer, progressRingLayer]
        layers.forEachIndex { index, layer in
            layer.frame = rect
        }
        self.updateLayers()
    }
    
    // MARK: - private Updates
    private var lastBkgHash : Int = 0
    func updateBackgroundLayer(bounds rect: CGRect) {
        let newBkgHash = backgroundColor.hashValue ^ rect.hashValue ^ _scale.hashValue
        if lastBkgHash != newBkgHash {
            lastBkgHash = newBkgHash
            
            dlog?.info("   updateBackgroundLayer")
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
            dlog?.info("   updateBkgRingLayer")
            
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
            
            dlog?.info("   updateProgressRingLayer")
            
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
            
            dlog?.info("   updateProgressRingLayerMask")
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
            dlog?.info("progressRingLayerMask \(mask.frame.center) pmg:\(backgroundLayer.frame.center)")
        }
    }
    
    private var lastTotalHash : Int = 0
    func updateLayers() {
        let newTotalHash = self.hash
        if lastTotalHash != newTotalHash {
            lastTotalHash = newTotalHash
            let rect = self.rectForLayers().boundsRect()
            dlog?.info("updateLayers bounds:\(rect)")
            updateBackgroundLayer(bounds: rect)
            updateBkgRingLayer(bounds: rect)
            updateProgressRingLayer(bounds: rect)
            updateProgressRingLayerMask(bounds:rect)
        }
    }
    
    private func rectForLayers()->CGRect {
        let rect = rootLayer.frame.boundsRect().boundedSquare().insetBy(dx: 1, dy: 1).offset(by: self.centerOffset).rounded()
        
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
    
    private func setup() {
        DispatchQueue.main.performOncePerInstance(self) {
            lastUsedRect = self.frame.boundsRect()
            self.layer = rootLayer
            self.wantsLayer = true
            dlog?.info("setup bounds: \(self.bounds)")
            if let layer = self.layer {
                layer.masksToBounds = true
                if DEBUG_DRAWING {
                    layer.backgroundColor = NSColor.blue.withAlphaComponent(0.1).cgColor
                    layer.border(color: .blue.withAlphaComponent(0.5), width: 1)
                }
            }
            
            let rect = self.rectForLayers()
            let layers = [backgroundLayer, bkgRingLayer, progressRingLayer]
            layers.forEachIndex { index, layer in
                layer.autoresizingMask =  [.layerWidthSizable, .layerHeightSizable]
                layer.frame = rect
                rootLayer.addSublayer(layer)
                if DEBUG_DRAWING && index == 0 {
                    layer.border(color: .blue.withAlphaComponent(0.5), width: 0.5)
                }
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
            
            self.devTestIfNeeded()
        }
    }
    
    private func setNewProgress(_ newValue:CGFloat, animated:Bool = true, force:Bool = false) {
        let newValue = clamp(value: newValue, lowerlimit: 0.0, upperlimit: 1.0)
        var sigFraction : CGFloat = 360
        if self.bounds.width > 200 || self.bounds.height > 200 {
            sigFraction = 1440
        } else if self.bounds.width > 100 || self.bounds.height > 100 {
            sigFraction = 720
        }
        
        let prev = self.isIndeterminate ? _indeterminateProgress : _progress
        if (abs(newValue - prev) > 1.0 / sigFraction) || force {
            if self.isIndeterminate {
                _indeterminateProgress = newValue
            } else {
                _progress = newValue
            }
            
            if IS_DEBUG {
                let prog = isIndeterminate ? "Indeterminate" : "Progress"
                dlog?.info("setNew \(prog): \(newValue) animated: \(animated)")
            }
            
            CATransaction.begin()
            CATransaction.setDisableActions(!animated)
            
            self.progressRingLayerMask.strokeEnd = newValue
            
            CATransaction.commit()
        }
    }
    //MARK: Indeterminate
    private func startIndeterminateAnimations() {
//        dlog?.info("startIndeterminateAnimations")
//        let layer = DEBUG_DRAW_MASK_AS_LAYER ? mask : progressRingLayer
//        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
////        layer.startSpinAnimation()
//        indeterminateAnimating = true
    }
    
    private func stopIndeterminateAnimations() {
//        dlog?.info("stopIndeterminateAnimations")
//        let layer = DEBUG_DRAW_MASK_AS_LAYER ? mask : progsRingLayer
//        layer.stopSpinAnimation()
//        indeterminateAnimating = false
    }
    
    private func updateIndeterminateAnimations() {
//        if isIndeterminate && !indeterminateAnimating {
//            startIndeterminateAnimations()
//        } else if !isIndeterminate && indeterminateAnimating {
//            stopIndeterminateAnimations()
//        }
    }
    
    // MARK: Dev / Debug
    func devTestIfNeeded() {
        guard DEBUG_DEV_TIMED_TEST else {
            return
        }

        DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
            dlog?.info("DEBUG_DEV_TIMED_TEST")
            self.progress = 0.2
        }
        DispatchQueue.main.asyncAfter(delayFromNow: 1.0) {
            self.progress = 0.5
        }
        DispatchQueue.main.asyncAfter(delayFromNow: 1.5) {
            self.progress = 0.75
        }
        
//        DispatchQueue.main.asyncAfter(delayFromNow: 2) {
//            self.isIndeterminate = true
//        }
                    
//        DispatchQueue.main.asyncAfter(delayFromNow: 8) {
//            self.progress?.isIndeterminate = false
//        }
                    
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
