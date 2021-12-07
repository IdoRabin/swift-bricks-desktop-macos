//
//  NSTitleDetailTableCellView.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import AppKit

class NSTitleDetailTableCellView: NSTableCellView {
    
    var detailLabel : NSTextField? = nil
    
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            var selected = self.backgroundStyle == .emphasized // Was changed from ".dark"
            if let row = self.superview as? NSTableRowView {
                selected = row.isSelected
            }
            
            if !selected {
                // DLog.ui.info("light \(textField?.stringValue)")
                if (textField?.tag == 1) {
                    textField?.textColor = NSColor(white: 0.04, alpha: 1.0)
                }
                detailLabel?.textColor = (self.textField?.textColor ?? NSColor.textColor).withAlphaComponent(0.5)
            } else {
                // DLog.ui.info("dark \(textField?.stringValue)")
                if (textField?.tag == 1) {
                    textField?.textColor = NSColor.white // selected
                }
                self.detailLabel?.textColor = NSColor.alternateSelectedControlTextColor
            }
        }
    }

    private func setup() {
        detailLabel = NSTextField(frame: self.textField?.frame ?? CGRect(x: 0, y: 0, width: self.bounds.width, height: 44.0))
        detailLabel?.font = NSFont.systemFont(ofSize: 11.0, weight: NSFont.Weight.light)
        detailLabel?.backgroundColor = NSColor.clear
        detailLabel?.isEditable = false
        detailLabel?.textColor = (self.textField?.textColor ?? NSColor.textColor).withAlphaComponent(0.5)
        detailLabel?.isBordered = false
        detailLabel?.drawsBackground = false
        detailLabel?.lineBreakMode = .byTruncatingHead
        self.addSubview(detailLabel!)
    }
    
    func setupTextFieldIfNeeded() {
        if self.textField == nil {
            let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
            tf.isEditable = false
            tf.isBezeled = false
            tf.isSelectable = true
            tf.tag = 1
            tf.isBordered = false
            tf.focusRingType = .none
            tf.drawsBackground = false
            tf.textColor = (self.backgroundStyle == .normal /* was .light*/) ? NSColor(white: 0.04, alpha: 1.0) : NSColor.white
            self.addSubview(tf)
            self.textField = tf
        }
    }
    
    override func layout() {
        super.layout()
        if let textField = self.textField {
            
            let size = detailLabel?.sizeThatFits(self.bounds.size) ?? CGSize(width: 320, height: 20.0)
            let w  = max(size.width - (self.imageView?.frame.width ?? 42.0) - 10.0, textField.frame.width)
            detailLabel?.frame = textField.frame.changed(y:round((self.bounds.height - 2*size.height) / 2.0) , width:w, height: size.height)
            
            let textHeight = textField.sizeThatFits(CGSize(width: self.bounds.width, height: 20)).height
            if detailLabel?.stringValue.count == 0 {
                textField.frame = textField.frame.changed(y: round((self.bounds.height - textHeight) / 2.0), height:textHeight)
            } else {
                textField.frame = textField.frame.changed(y: detailLabel?.frame.maxY ?? 0.0, height:textHeight)
            }
            
        }
    }
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        if (textField?.tag == 1) {
//            textField?.textColor = NSColor.red
//        }
//    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.setup()
    }
    
}
