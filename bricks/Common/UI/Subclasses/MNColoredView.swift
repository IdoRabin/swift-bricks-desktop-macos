//
//  MNColoredView.swift
//  grafo
//
//  Created by Ido on 10/01/2021.
//

import Cocoa

class MNColoredView : MNBaseView {
    @IBInspectable var backgroundColor : NSColor? = .windowBackgroundColor
    @IBInspectable var borderColor : NSColor? = .controlBackgroundColor
    @IBInspectable var borderWidth : CGFloat = 2.0
    
    override func draw(_ dirtyRect: NSRect) {
        self.drawFillBackground(color: self.backgroundColor, dirtyRect: dirtyRect)
        self.drawBorder(thickness: borderWidth, color: borderColor ?? NSColor.yellow)
        super.draw(dirtyRect)
    }
}
