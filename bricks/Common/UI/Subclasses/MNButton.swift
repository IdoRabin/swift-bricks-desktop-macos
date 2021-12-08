//
//  MNButton.swift
//  XPlan
//
//  Created by Ido on 02/11/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("MNButton")

class MNButton: NSButton {
    
    // private properties
    private var hoverTrackingArea : NSTrackingArea? = nil
    
    // public var
    @IBInspectable var isDetectHover : Bool = false {
        didSet {
            self.updateTrackingAreas()
        }
    }
    
    var onMouseEnter : ((_ sender : MNButton)->Void)? = nil
    var onMouseExit : ((_ sender : MNButton)->Void)? = nil
    
    override func updateTrackingAreas() {
        if isDetectHover && self.trackingAreas.count == 0 {
            hoverTrackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: nil)
            self.addTrackingArea(hoverTrackingArea!)
        } else if isDetectHover == false && self.trackingAreas.count > 0, let area = self.hoverTrackingArea {
            self.removeTrackingArea(area)
        }
        
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        //dlog?.info("mouseUp")
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        //dlog?.info("mouseEntered")
        onMouseEnter?(self)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        //dlog?.info("mouseExited")
        onMouseExit?(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async {[self] in
            self.updateTrackingAreas()
        }
    }
    
    func titleNBSPPrefixIfNeeded(count:Int = 1) {
        if !self.title.hasPrefix(String.NBSP) {
            // dlog?.info("BTN \(button.title)")
            let firstChar = String.NBSP[String.NBSP.startIndex]
            self.title = self.title.paddingLeft(padCount: 1, withPad: firstChar)
            self.needsLayout = true
            self.needsDisplay = true
        }
    }
}

extension MNButton : NSValidatedUserInterfaceItem {
    
}
