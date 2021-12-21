//
//  NSBezierPathEx.swift
//  Bricks
//
//  Created by Ido on 19/12/2021.
//

import AppKit

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

    // MARK: - NSBezierPath + ringPath
    // MARK: Needed for YPRingProgressView
    class func ringPath(from rect: NSRect, with ringWidth: CGFloat) -> NSBezierPath {
        let inset = ringWidth / 2
        let rectWithInset = rect.insetBy(dx: inset, dy: inset)
        
        let radius = rectWithInset.width / 2
        let center = CGPoint(x: rectWithInset.midX, y: rectWithInset.midY)
        
        let ringPath = NSBezierPath()
        ringPath.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: -270, clockwise: true)
        return ringPath
    }
}
