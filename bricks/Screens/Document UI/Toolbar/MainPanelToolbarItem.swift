//
//  MainPanelToolbarItem.swift
//  Bricks
//
//  Created by Ido on 15/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("MainPanelToolbarItem")

class MainPanelToolbarItem : MNToolbarItem {
    override func awakeFromNib() {
        super.awakeFromNib()
        // dlog?.info("awoken!")
    }
}
