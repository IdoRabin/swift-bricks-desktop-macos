//
//  NSViewEx.swift
//  grafo
//
//  Created by Ido on 18/01/2021.
//

import Cocoa

struct NSBorder {
    let thickness : CGFloat
    
    let color : NSColor
    
    init(color newColor:NSColor, thickness newThickness:CGFloat) {
        color = newColor
        thickness = newThickness
    }
}

extension NSView {
    
    func drawRect(rect:CGRect, fillColor: NSColor?, border:NSBorder? = nil) {
        let context = NSGraphicsContext.current?.cgContext
        
        let path = NSBezierPath(rect: rect)
        if let fillColor = fillColor, fillColor != NSColor.clear, fillColor.alphaComponent > 0 {
            fillColor.setFill()
            path.fill()
        }
        
        if let border = border, border.color != NSColor.clear, border.color.alphaComponent > 0 {
            context?.setLineWidth(border.thickness)
            border.color.setStroke()
            path.lineWidth = border.thickness
            path.stroke()
        }
    }
    
    func drawCircle(center:CGPoint, radius:CGFloat, fillColor:NSColor?, border:NSBorder? = nil) {
        guard radius > 0 else {
            return
        }
        
        let rect = center.rectAroundCenter(width: radius * 2, height: radius * 2)
        self.drawEllipse(rect: rect, fillColor:fillColor, border:border)
    }
    
    func drawBoundedCircle(rect:CGRect, fillColor:NSColor?, border:NSBorder? = nil) {
        self.drawEllipse(rect: rect.boundedSquare(), fillColor:fillColor, border:border)
    }
    
    func drawBoundingCircle(rect:CGRect, fillColor:NSColor?, border:NSBorder? = nil) {
        self.drawEllipse(rect: rect.boundingSquare(), fillColor:fillColor, border:border)
    }
    
    func drawEllipse(rect:CGRect, fillColor:NSColor?, border:NSBorder? = nil) {
        guard !rect.isEmpty && !rect.isNull && !rect.isInfinite else {
            return
        }

        let context = NSGraphicsContext.current!.cgContext
        context.saveGState()
        if let fillColor = fillColor, fillColor != NSColor.clear, fillColor.alphaComponent > 0  {
            context.setFillColor(fillColor.cgColor)
            context.fillEllipse(in: rect)
        }
        
        if let border = border, border.color != NSColor.clear, border.color.alphaComponent > 0 {
            context.setLineWidth(border.thickness)
            context.setStrokeColor(border.color.cgColor)
            context.strokeEllipse(in: rect)
        }
        
        context.restoreGState()
    }
}

extension NSView {
    
    func drawFillBackground(color:NSColor?, dirtyRect:CGRect) {
        if let color = color {
            color.setFill()
            self.bounds.intersection(dirtyRect).fill()
        }
    }
    
    func drawBorder(thickness:CGFloat = 1.0, color:NSColor?) {
        if let color = color {
            color.set() // as stroke
            let borderPath = NSBezierPath(rect:self.bounds)
            borderPath.lineWidth = thickness
            borderPath.stroke()
        }
    }
}

extension NSEvent {
    
    func locationInView(_ nsView:NSView)->CGPoint? {
        let point = self.locationInWindow
        if nsView.window == self.window
        {
            let converted = nsView.convert(point, from: nil)
            return converted
        }
        return nil
    }
}

extension NSView {

    @discardableResult   // 1
    func fromNib<T : NSView>() -> T? {   // 2
        let name = String(describing: self)
        var contentViews : NSArray? = nil
        if Bundle.main.loadNibNamed(name, owner: nil, topLevelObjects: &contentViews), let contentViews = contentViews {
            return contentViews.first { anyItm in
                anyItm is T
            } as? T
        }
        return nil
    }
    
    @objc static func fromNib()->Self? {
        var contentViews : NSArray? = nil
        let name = String(describing: self)
        if Bundle.main.loadNibNamed(name, owner: nil, topLevelObjects: &contentViews), let contentViews = contentViews {
            return contentViews.first { anyItm in
                anyItm is Self
            } as? Self
        }
        return nil
    }
}

class NSViewBkgLayer : CALayer {
    
}

extension NSView /* Layers*/ {
    
    @discardableResult
    func updateBkgColorLayer(color:NSColor, insets:NSEdgeInsets = NSEdgeInsetsZero)->CALayer? {
        if self.wantsLayer == false {
            DLog.ui["NSViewEx"]?.info("updateBkgColorLayer for NSView \(type(of: self)) that wantsLayer == false")
        }
        
        let bkgLayer = self.layer?.sublayers?.filter({ layer in
            layer is NSViewBkgLayer
        }).first
                                                            
        guard bkgLayer == nil else {
            bkgLayer?.backgroundColor = color.cgColor
            bkgLayer?.frame = self.bounds.insetted(by: insets)
            return bkgLayer!
        }
        
        let layer = NSViewBkgLayer()
        layer.backgroundColor = color.cgColor
        layer.frame = self.bounds.insetted(by: insets)
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        self.layer?.insertSublayer(layer, at: 0)
        
        return layer
    }
}
