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
        if index == self.leadingDividerIndex, let subview = self.arrangedSubviews.first {
            let minPos = self.minPossiblePositionOfDivider(at: index)
            // dlog?.info("L minPos \(minPos) w:\(subview.frame.width)")
            return self.isSubviewCollapsed(subview) || abs(minPos - subview.frame.maxX) < 10.0 
        }
        
//        if index == self.trailingDividerIndex, let subview = self.arrangedSubviews.last {
//            let minPos = self.minPossiblePositionOfDivider(at: index)
//            dlog?.info("T minPos \(minPos) w:\(subview.frame.width)")
//            return self.isSubviewCollapsed(subview)
//        }
//
//        if self.arrangedSubviews.count > 2 && index > 0 && index < self.arrangedSubviews.count - 1 {
//            return self.isSubviewCollapsed(self.arrangedSubviews[index])
//        }
        
        return false
    }
    
    var isLeadingPanelCollapsed : Bool {
        return isPanelCollapsed(at: self.leadingDividerIndex)
    }
    
    var isTrailingPanelCollapsed : Bool {
        return isPanelCollapsed(at: self.trailingDividerIndex)
    }
}
