//
//  DocWindow.swift
//  Bricks
//
//  Created by Ido on 11/04/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocWindow")

class DocWindow : NSWindow {
    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        let result = super.makeFirstResponder(responder)
        if result {
            // dlog?.info("makeFirstResponder \(responder.descOrNil)")
            MNFocus.shared.didBecomeFocusNotif(view: responder) // Tracks MNResponder changes
        }
        return result
    }
}
