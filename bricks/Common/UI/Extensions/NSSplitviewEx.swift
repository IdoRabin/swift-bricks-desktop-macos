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
    
    private func isPanelCollapsed(at panelIndex:Int)->Bool {
        
        /*
         NOTE: there is a difference between DividerIndex and panelIndexes
         consider for example:  leadingPanel|panel|panel|trailingPanel
        */
        
        /*
         TODO: validate in RTL_LAYOUT: check if should be leading/trailing or left/right and relpace according to layout,
         this will depend on the splitView's auto flipping of panels and panels indexes to got LTR or RTL
         */
        
        let leadingPanelIndex = max(self.leadingDividerIndex - 1, 0)
        let trailingPanelIndex = max(self.trailingDividerIndex + 1, 0)
        
        // Make sure its either of the two panels, else warn:
        guard [leadingPanelIndex, trailingPanelIndex].contains(panelIndex) else {
            dlog?.note("isPanelCollapsed: failed detecting lead/trail for panel index: \(panelIndex) | leading: \(leadingPanelIndex) trailing:\(trailingPanelIndex) |")
            return false
        }
        
        let isLeading = (panelIndex <= leadingPanelIndex)
        let isTrailing = (panelIndex >= trailingPanelIndex)
        
        guard isLeading || isTrailing else {
            dlog?.warning("isPanelCollapsed failed detecting panel's side")
            return false
        }

        // Calc if collapsed:
        let minPos = self.minPossiblePositionOfDivider(at: panelIndex)
        let panel = self.arrangedSubviews[panelIndex]
        let subtract : CGFloat = isLeading ? panel.frame.maxX : panel.frame.width
        let extraLimit : CGFloat = 10.0
        
        // reult represents isCollapsed for the panel
        var result = self.isSubviewCollapsed(panel)
        if !result {
            if isLeading {
                result = abs(minPos - subtract) < extraLimit
            } else {
                result = panel.frame.width < extraLimit
            }
        }
        
        if Debug.IS_DEBUG {
            if isLeading {
                dlog?.info("isPanelCollapsed isLeading  collpsed: \(result)")
            } else {
                dlog?.info("isPanelCollapsed isTrailing collpsed: \(result)")
            }
            panel.debugBorder(color: isLeading ? NSColor.blue : NSColor.red)
        }
        return result
    }
    
    var isLeadingPanelCollapsed : Bool {
        return isPanelCollapsed(at: self.leadingDividerIndex)
    }
    
    var isTrailingPanelCollapsed : Bool {
        return isPanelCollapsed(at: self.trailingDividerIndex + 1)
    }
}
