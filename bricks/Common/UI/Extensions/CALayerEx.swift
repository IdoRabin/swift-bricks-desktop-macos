//
//  CALayerEx.swift
//  Bricks
//
//  Created by Ido Rabin on 11/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Cocoa

extension NSView {
    func layerCornerAsCircle() {
        self.cornerAsCircle()
    }
    
    func cornerAsCircle() {
        self.layer?.cornerRadius = max(self.bounds.width, self.bounds.height) * 0.5
    }
}

extension CALayer /* borders*/ {
    
    func border(color:NSColor = NSColor.cyan, width:CGFloat = 1.0) {
        self.borderColor = color.cgColor
        self.borderWidth = width
    }
    
    func borderClear() {
        self.borderColor = NSColor.clear.cgColor
        self.borderWidth = 0.0
    }
    
    func corner(radius:CGFloat) {
        self.cornerRadius = radius
        self.masksToBounds = true
    }
    
    func cornerClear() {
        self.cornerRadius = 0.0
    }
    
    func debugBorder(color:NSColor, width:CGFloat) {
        #if DEBUG
        self.border(color:color, width:width)
        #endif
    }
    
    // MARK: Needed for YPRingProgressView
    func disableActions(for keyPathes: [String]) {
        actions = Dictionary(uniqueKeysWithValues: keyPathes.map { ($0, NSNull()) })
    }
}

extension CALayer /* spin animation */ {
    
    func startSpinAnimation(duration:CFTimeInterval = 1, clockwise:Bool = true) {
        let rotationAnimation = CABasicAnimation()
        rotationAnimation.keyPath = "transform.rotation.z"

        let direction = clockwise ? -1.0 : 1.0
        let toValue = Double.pi * 2.0 * direction
        let someInterval = CFTimeInterval(duration)
        rotationAnimation.toValue = toValue
        rotationAnimation.duration = someInterval
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = Float.infinity
        
        self.add(rotationAnimation, forKey: "spinRotationAnimation")
    }
    
    func startSpinAnimationForPathLayer(duration:CFTimeInterval = 2, clockwise:Bool = true) {
        
        let rotationAnimation = CABasicAnimation()
        rotationAnimation.keyPath = "transform.rotation.z"
        let direction = clockwise ? -1.0 : 1.0
        let toValue = Double.pi * 2.0 * direction
        let someInterval = CFTimeInterval(duration)
        rotationAnimation.toValue = toValue
        rotationAnimation.duration = someInterval
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = Float.infinity
        
        let pathChangeAnimation = CABasicAnimation()
        pathChangeAnimation.keyPath = "transform.rotation.z"
        let pathChangeDirection = clockwise ? -1.0 : 1.0
        let toPathValue = 360 * pathChangeDirection
        rotationAnimation.toValue = toPathValue
        rotationAnimation.duration = someInterval
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = Float.infinity
        
        self.add(rotationAnimation, forKey: "spinRotationAnimation")
    }
    
    func stopSpinAnimation() {
        self.removeAnimation(forKey: "spinRotationAnimation")
    }
    
    
}
