//
//  NSTextFieldVCenterCell.swift
//  Bricks
//
//  Created by Ido on 25/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("NSTextFieldVCenterCell")

extension NSTextAlignment {

    /// Returns the opposite of the natural direction. If ui layout is LTR, result will be .right, if is RTL result will be .left
    static var inverseNatural : NSTextAlignment {
        return IS_RTL_LAYOUT ? .left : .right
    }
}

// Vertically centered text field cell
class NSTextFieldVCenterCell : NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        var hgt : CGFloat = 22.0
        if let parent = controlView as? NSTextField, let font = parent.font {
            hgt = font.boundingRectForFont.height
        } else {
            hgt = NSFont.systemFont(ofSize: NSFont.systemFontSize).boundingRectForFont.height // fallback / default
        }
        let newRect = NSRect(x: 0, y: (rect.size.height - hgt) / 2.0, width: rect.size.width, height: hgt)
        return super.drawingRect(forBounds: newRect)
    }
}
