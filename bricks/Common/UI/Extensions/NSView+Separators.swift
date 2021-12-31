//
//  NSView+Separators.swift
//  XPlan
//
//  Created by Ido on 31/10/2021.
//

import Cocoa

class SeparatorLayer : CALayer {
    
}

class SeparatorView : NSView {
    
}

extension NSView /* separator layer */ {
    @objc enum SeparatorSide : Int, Equatable {
        case top
        case leading
        case bottom
        case trailing
        
        func xFlipped()->SeparatorSide {
            switch self {
            case .top, .bottom:
                return self
            case .leading:
                return .trailing
            case .trailing:
                return .leading
            }
        }
        
        func yFlipped()->SeparatorSide {
            switch self {
            case .top:
                return .bottom
            case .bottom:
                return .top
            case .leading, .trailing:
                return self
            }
        }
        
        func defaultViewAutoresizingMask(viewIsFlipped:Bool = true)->AutoresizingMask {
            var result : AutoresizingMask = []
            switch self {
            case .leading:
                result = [.height, .maxXMargin]
            case .trailing:
                result = [.height, .minXMargin]
            case .top:
                if !viewIsFlipped {
                    result = [.width, .minYMargin]
                } else {
                    result = [.width, .maxYMargin]
                }
            case .bottom:
                if !viewIsFlipped {
                    result = [.width, .maxYMargin]
                } else {
                    result = [.width, .minYMargin]
                }
            }
            return result
        }
        
        func defaultLayerAutoresizingMask()->CAAutoresizingMask {
            var result : CAAutoresizingMask = []
            switch self {
            case .leading:
                result = [.layerHeightSizable, .layerMaxXMargin]
            case .trailing:
                result = [.layerHeightSizable, .layerMinXMargin]
            case .top:
                result = [.layerWidthSizable, .layerMinYMargin]
                
            case .bottom:
                result = [.layerWidthSizable, .layerMaxYMargin]
            }
            return result
        }
        
        var isVerticalSperator : Bool {
            switch self {
            case .trailing, .leading:
                return true
            case .top, .bottom:
                return false
            }
        }
        
        var isHorizontalSperator : Bool {
            return !self.isVerticalSperator
        }
    }
    
    func calcSeperatorThicknessForCurScreen(thickness:CGFloat = 0.0)->CGFloat {
        let thkcns : CGFloat = thickness > 0.0 ? thickness : (1.0 / (NSScreen.main?.backingScaleFactor ?? 1.0)) * 2.0
        return thkcns
    }
    
    private func rectForSeperatorLayer(side:SeparatorSide, thickness:CGFloat = 0.0, addDelta:CGFloat = 0.0)->CGRect {
        let thkcns : CGFloat = calcSeperatorThicknessForCurScreen(thickness: thickness)
        
        var frm = self.bounds
        var directionaledSide = self.userInterfaceLayoutDirection == .rightToLeft ? side.xFlipped() : side
        if self.isFlipped == false {
            directionaledSide = directionaledSide.yFlipped()
        }
        
        switch directionaledSide {
        case .leading:
            frm.size.width = thkcns
            frm.origin.x = 0 + addDelta

        case .trailing:
            frm.origin.x = frm.maxX - thkcns - addDelta
            frm.size.width = thkcns
            
        case .top:
            frm.origin.y += addDelta
            frm.size.height = thkcns
            
        case .bottom:
            frm.origin.y = frm.maxY - thkcns - addDelta
            frm.size.height = thkcns
        }
        
        return frm
    }
    
    func clearSeperators() {
        
        // Layers
        var layersToRemove : [CALayer] =  []
        for layer in self.layer?.sublayers ?? [] {
            if let sub = layer as? SeparatorLayer {
                layersToRemove.append(sub)
            }
        }
        for sub in layersToRemove {
            sub.removeFromSuperlayer()
        }
        
        // Views
        var viewsToRemove : [NSView] =  []
        for view in self.subviews {
            if let sub = view as? SeparatorView {
                viewsToRemove.append(sub)
            }
        }
        for sub in viewsToRemove {
            sub.removeFromSuperview()
        }
    }
    
    @discardableResult
    func addSeparatorLayer(side:SeparatorSide, color:NSColor = NSColor.separatorColor, thickness:CGFloat = 0.0, yDelta:CGFloat = 0.0, clearingPrevious:Bool = true)->SeparatorLayer {
        if clearingPrevious {
            self.clearSeperators()
        }
        
        let layer = SeparatorLayer()
        let thkcns : CGFloat = thickness > 0.0 ? thickness : (1.0 / (NSScreen.main?.backingScaleFactor ?? 1.0)) * 2.0
        layer.backgroundColor = color.cgColor
        layer.frame = self.rectForSeperatorLayer(side: side, thickness: thkcns, addDelta: yDelta)
        let directionaledSide = self.userInterfaceLayoutDirection == .rightToLeft ? side.xFlipped() : side
        layer.autoresizingMask = directionaledSide.defaultLayerAutoresizingMask()
        
        self.layer?.addSublayer(layer)
        return layer
    }
    
    @discardableResult
    func addSeparatorView(side:SeparatorSide, color:NSColor = NSColor.separatorColor, thickness:CGFloat = 0.0, addDelta:CGFloat = 0.0, clearingPrevious:Bool = true)->NSView {
        
        if clearingPrevious {
            self.clearSeperators()
        }
        
        let thkcns : CGFloat = thickness > 0.0 ? thickness : (1.0 / (NSScreen.main?.backingScaleFactor ?? 1.0)) * 2.0
        let frm = self.rectForSeperatorLayer(side: side, thickness: thkcns, addDelta: addDelta)
        let view = NSView(frame: frm)
        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
        let directionaledSide = self.userInterfaceLayoutDirection == .rightToLeft ? side.xFlipped() : side
        view.autoresizingMask = directionaledSide.defaultViewAutoresizingMask(viewIsFlipped: self.isFlipped)
        self.addSubview(view)
        return view
    }
    
    var firstSeperatorView : SeparatorView? {
        return self.firstSubview(which: { view in
            view is SeparatorView
        }, downtree: false) as? SeparatorView
    }
}
