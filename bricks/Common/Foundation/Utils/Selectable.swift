//
//  Selectable.swift
//  XPlan
//
//  Created by Ido on 07/11/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("Selectable")

protocol Selectable {
    var selectedIndexPaths : [IndexPath]  { get set}
    var selectedIndexPath : IndexPath?  { get set}
    var isAllowsMultipleSelection : Bool  { get }
    var isAllowsEmptySelection : Bool  { get }
}

extension Selectable /* default implementation */ {
    var selectedIndexPath : IndexPath? {
        get {
            return selectedIndexPaths.first
        }
        set {
            if let val = newValue {
                if isAllowsMultipleSelection {
                    selectedIndexPaths.append(val)
                    selectedIndexPaths = selectedIndexPaths.uniqueElements().sorted()
                } else {
                    selectedIndexPaths = [val]
                }
            } else if isAllowsEmptySelection {
                // Select none
                selectedIndexPaths.removeAll()
            } else {
                // Selecting none is not allowed
                dlog?.fail("\(type(of: self)) isAllowsEmptySelection is false, so seleting none / nil is not possible")
            }
        }
    }
}
