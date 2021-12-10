//
//  MNMenuItem.swift.swift
//  Bricks
//
//  Created by Ido on 09/12/2021.
//

import Foundation

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("MNButton")

class MNMenuItem: NSMenuItem {
    
    var associatedCommand : AppCommand.Type? = nil {
        didSet {
            if let cmd = self.associatedCommand {
                // self.toolTip = cmd.tooltipTitleFull
                self.title = cmd.menuTitle ?? cmd.buttonTitle
                self.keyEquivalent = cmd.keyboardShortcut.chars
                self.keyEquivalentModifierMask = cmd.keyboardShortcut.modifiers
            }
        }
    }
    
}

