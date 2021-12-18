//
//  NSScreenEx.swift
//  Bricks
//
//  Created by Ido on 18/12/2021.
//

import Foundation
import AppKit

extension NSScreen {
    static var widest : NSScreen? {
        return NSScreen.screens.max { scr1, scr2 in
            scr1.frame.width > scr2.frame.width
        } ?? NSScreen.main
    }
}
