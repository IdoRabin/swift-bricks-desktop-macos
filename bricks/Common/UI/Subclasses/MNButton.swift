//
//  MNButton.swift
//  XPlan
//
//  Created by Ido on 02/11/2021.
//

import AppKit

class MNButton: NSButton {
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        // XPDocVC.current?.validateUserInterfaceItems([self])
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
