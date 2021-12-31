//
//  NSTabViewEx.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//

import AppKit

extension NSTabView {
    var segmentedControl : NSSegmentedControl? {
        for view in self.superview?.subviews ?? [] {
            if let segmented = view as? NSSegmentedControl {
                return segmented
            }
        }
        return nil
    }
}

