//
//  MNToolbarSpacerButton.swift
//  XPlan
//
//  Created by Ido on 22/11/2021.
//

import AppKit

class MNToolbarSpacerButton : NSButton {
    var mouseDownTime : Date? = nil
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}
