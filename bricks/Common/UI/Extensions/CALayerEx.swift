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
    
    func disableActions(for keyPathes: [String]) {
        actions = Dictionary(uniqueKeysWithValues: keyPathes.map { ($0, NSNull()) })
    }
}

extension CAShapeLayer /* spin animation */ {
    func startFluctuaingPathLayer(duration:CFTimeInterval = 1, clockwise:Bool = true, flucMinPath:CGFloat = 0.1, flucMaxPath:CGFloat = 0.9) {
        let someInterval = CFTimeInterval(duration)
        
        // Change the path part being presented:
        let pathChangeAnimation = CABasicAnimation()
        pathChangeAnimation.keyPath = "strokeEnd"
        // let pathChangeDirection = clockwise ? 1.0 : -1.0
        let fromPathValue = clamp(value: flucMinPath, lowerlimit: 0.0, upperlimit: 1.0)
        let toPathValue = clamp(value: flucMaxPath, lowerlimit: 0.0, upperlimit: 1.0)
        pathChangeAnimation.fromValue = fromPathValue
        pathChangeAnimation.toValue = toPathValue
        pathChangeAnimation.duration = someInterval
        pathChangeAnimation.isCumulative = false
        pathChangeAnimation.autoreverses = true
        pathChangeAnimation.repeatCount = Float.infinity
        self.add(pathChangeAnimation, forKey: "fluctuatingPathSpinAnimation")
    }
    
    func stopFluctuaingPathLayer() {
        self.removeAnimation(forKey: "fluctuatingPathSpinAnimation")
    }
}

extension CALayer /* spin animation */ {
    
    func centerizeAnchor(animated:Bool = false, preventMoving:Bool = true) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        let newAnchorPoint = CGPoint(x: 0.5, y: 0.5)
        if preventMoving {
            var newPoint = CGPoint(x: bounds.width * newAnchorPoint.x,
                                   y: bounds.height * newAnchorPoint.y)
            
            
            var oldPoint = CGPoint(x: bounds.width * self.anchorPoint.x,
                                   y: bounds.height * self.anchorPoint.y)
            
            newPoint = newPoint.applying(CATransform3DGetAffineTransform(self.transform))
            oldPoint = oldPoint.applying(CATransform3DGetAffineTransform(self.transform))
            
            var position = self.position
            position.x -= oldPoint.x
            position.x += newPoint.x
            
            position.y -= oldPoint.y
            position.y += newPoint.y
            
            self.position = position
        }
        self.anchorPoint = newAnchorPoint
        CATransaction.commit()
    }
    
    func startSpinAnimation(duration:CFTimeInterval = 0.7, clockwise:Bool = true) {
        let rotationAnimation = CABasicAnimation()
        rotationAnimation.keyPath = "transform.rotation.z"

        let direction = clockwise ? -1.0 : 1.0
        let toValue = Double.pi * 2.0 * direction
        rotationAnimation.toValue = toValue
        rotationAnimation.duration = CFTimeInterval(duration)
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = Float.infinity
        
        self.add(rotationAnimation, forKey: "spinRotationAnimation")
    }
    
    func stopSpinAnimation() {
        self.removeAnimation(forKey: "spinRotationAnimation")
    }
    
    func animateScale(duration:CFTimeInterval, to toValue:CGFloat) {

        let scaleAnimation = CABasicAnimation()
        scaleAnimation.keyPath = #keyPath(CALayer.transform)
        // scaleAnimation.fromValue = CATransform3DScale(CATransform3DIdentity, 1, 1, 1)
        scaleAnimation.toValue = CATransform3DScale(CATransform3DIdentity, toValue, toValue, 1)
        scaleAnimation.duration =  CFTimeInterval(duration)
        scaleAnimation.isAdditive = true
        scaleAnimation.isCumulative = true
        
        self.add(scaleAnimation, forKey: "scaleAnimation")
    }
}

extension CATransaction {
    
    static func noAnimation(_ block: ()->Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        block()
        CATransaction.commit()
    }
    
    static func animate(animated:Bool, duration:TimeInterval, _ block: ()->Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        if animated {
            CATransaction.setAnimationDuration(duration)
        }
        block()
        CATransaction.commit()
    }
    
}
