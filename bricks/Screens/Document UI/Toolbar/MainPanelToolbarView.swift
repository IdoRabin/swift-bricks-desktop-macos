//
//  MainPanelToolbarItem.swift
//  Bricks
//
//  Created by Ido on 15/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("MainPanelToolbarItem")

class MainPanelToolbarView : NSView {
    override func awakeFromNib() {
        super.awakeFromNib()
        // dlog?.info("awoken!")
    }
}
