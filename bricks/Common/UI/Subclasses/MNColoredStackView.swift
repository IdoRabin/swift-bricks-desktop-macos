//
//  MNColoredStackView.swift
//  grafo
//
//  Created by Ido on 10/01/2021.
//

import Cocoa

class MNColoredStackView : NSStackView {
    @IBInspectable var backgroundColor : NSColor? = .windowBackgroundColor
    @IBInspectable var borderColor : NSColor? = .controlBackgroundColor
    
    override func draw(_ dirtyRect: NSRect) {
        self.drawFillBackground(color: self.backgroundColor, dirtyRect: dirtyRect)
        self.drawBorder(thickness: 2, color: borderColor ?? NSColor.yellow)
        super.draw(dirtyRect)
    }
}
