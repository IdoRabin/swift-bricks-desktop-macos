//
//  NSButtonEx.swift
//  Bricks
//
//  Created by Ido on 09/12/2021.
//

import AppKit

extension NSButton {
    var attributesForWholeTitle : [NSAttributedString.Key : Any] {
        if self.title.count == 0 {
            self.title = String.ZWSP
        }
        return self.attributedTitle.attributes(at: 0, longestEffectiveRange: nil, in: NSMakeRange(0, self.title.count))
    }
}
