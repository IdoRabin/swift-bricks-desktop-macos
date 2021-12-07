//
//  GridViewSnapMode.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import AppKit

// Grid snap mode
enum GridViewSnapMode {
    case none
    case rounded
    case grid
    case secondaryGrid
}

protocol GridViewSnappable : NSView {
    
    func snapPoint(pt : CGPoint?, snapMode:GridViewSnapMode)->CGPoint?
    func snapLocationInView(for event: NSEvent, snapMode:GridViewSnapMode)->CGPoint?
}
