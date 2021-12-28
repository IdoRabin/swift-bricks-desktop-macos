//
//  NSView+Search Constraints.swift
//  Bricks
//
//  Created by Ido on 27/12/2021.
//

import AppKit

extension NSView {
    
    func constraints(affectingLayout orientation:NSLayoutConstraint.Orientation,
                     withFirstAttribute firstAttribute:NSLayoutConstraint.Attribute,
                     firstItem:NSView? = nil,
                     secondAttribute:NSLayoutConstraint.Attribute,
                     secondItem:NSView? = nil)->[NSLayoutConstraint] {
        
        return self.constraintsAffectingLayout(for: orientation).filter { constraint in
            var result = constraint.firstAttribute == firstAttribute &&
                         constraint.secondAttribute == secondAttribute
            if let firstObj = firstItem {
                result = result && constraint.firstItem === firstObj
            }
            if let secondItem = secondItem {
                result = result && constraint.secondItem === secondItem
            }
            return result
        }
    }
    
    func firstConstraint(affectingLayout orientation:NSLayoutConstraint.Orientation,
                         firstItem:NSView? = nil,
                     withFirstAttribute firstAttribute:NSLayoutConstraint.Attribute,
                     secondAttribute:NSLayoutConstraint.Attribute,
                         secondItem:NSView? = nil)->NSLayoutConstraint? {
        
        return constraints(affectingLayout: orientation,
                           withFirstAttribute: firstAttribute,
                           firstItem: firstItem,
                           secondAttribute: secondAttribute,
                           secondItem: secondItem).first
    }
    
    func addAspectRatioConstraint(isActive:Bool, multiplier:CGFloat, constant:CGFloat)->NSLayoutConstraint {
        let constaint = NSLayoutConstraint(item: self,
                                           attribute: .height,
                                           relatedBy: .equal,
                                           toItem: self,
                                           attribute: .width,
                                           multiplier: multiplier,
                                           constant: constant)
        self.addConstraint(constaint)
        constaint.isActive = isActive
        return constaint
    }
}

extension NSLayoutConstraint {
    
    static func activateAndReturn<Key:Hashable>(constraints: [Key : NSLayoutConstraint])->[Key : Weak<NSLayoutConstraint>] {
        NSLayoutConstraint.activate(constraints.valuesArray)
        var result : [Key : Weak<NSLayoutConstraint>]  = [:]
        for (key, val) in constraints {
            val.isActive = true
            result[key] = Weak<NSLayoutConstraint>(value: val)
        }
        return result
    }
    
}
