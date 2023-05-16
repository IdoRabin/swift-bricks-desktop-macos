//
//  NSSplitviewEx.swift
//  Bricks
//
//  Created by Ido on 12/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("NSSplitView")

extension NSSplitView {
    
    var leadingDividerIndex : Int {
        return 0 // self.arrangedSubviews.count
    }
    
    var trailingDividerIndex : Int {
        return max(self.arrangedSubviews.count - 2, 0)
    }
    
    func isPanelCollapsed(at index:Int)->Bool {
        var isLeading = false
        guard [self.leadingDividerIndex, self.trailingDividerIndex].contains(index) else {
            return false
        }
        
        isLeading = (index == self.leadingDividerIndex)
        
        if let vc = self.window?.contentViewController as? NSSplitViewController {
            if let splitItem = isLeading ? vc.splitViewItems.first : vc.splitViewItems.last {
                // ?
            }
        }
        
        let minPos = self.minPossiblePositionOfDivider(at: index)
        guard let subview : NSView = isLeading ? self.arrangedSubviews.first : self.arrangedSubviews.last else {
            return false
        }
        let subtract : CGFloat = isLeading ? subview.frame.maxX : subview.frame.width
        
        // dlog?.info("L minPos \(minPos) w:\(subview.frame.widt h)")
        let extraLimit : CGFloat = 10.0
        return self.isSubviewCollapsed(subview) || abs(minPos - subtract) < extraLimit || subview.frame.width < extraLimit
    }
    
    var isLeadingPanelCollapsed : Bool {
        return isPanelCollapsed(at: self.leadingDividerIndex)
    }
    
    var isTrailingPanelCollapsed : Bool {
        return isPanelCollapsed(at: self.trailingDividerIndex + 1)
    }
}
