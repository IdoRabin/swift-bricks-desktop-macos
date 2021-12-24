//
//  MNProgressAction.swift
//  Bricks
//
//  Created by Ido on 23/12/2021.
//

import Foundation

struct MNProgressAction : Hashable {
    
    let title : String
    let subtitle : String?
    let info : Any?
    let isLongTimeAction : Bool
    
    init(title newTitle : String,
         subtitle newSubtitle : String?,
         info newInfo : Any? = nil,
         isLongTimeAction newIsLongTimeAction : Bool = false) {
        
        // Set new values
        self.title = newTitle
        self.subtitle = newSubtitle
        self.info = newInfo
        self.isLongTimeAction = newIsLongTimeAction
    }
    
    // MARK: hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(isLongTimeAction)
    }
    
    // MARK: equatable
    static func ==(lhs:MNProgressAction, rhs:MNProgressAction)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var isEmpty : Bool {
        return (title.count == 0 && subtitle?.count ?? 0 == 0 && info == nil)
    }
}
