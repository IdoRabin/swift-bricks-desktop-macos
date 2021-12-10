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


public extension NSBezierPath {

    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            @unknown default:
                fatalError()
            }
        }
        return path
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
}
