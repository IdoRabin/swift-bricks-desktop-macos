//
//  BrickLayer.swift
//  Bricks
//
//  Created by Ido on 03/01/2022.
//

import Foundation

class BrickLayer : BUIDable, CodableHashable {
    
    enum Selection : Int, Codable {
        case selected
        case nonselected
        
        var isSelected : Bool { return self == .selected }
    }
    
    enum Visiblity : Int, Codable {
        case hidden
        case visible
        
        var isHidden : Bool { return self == .hidden }
        var isVisible : Bool { return self != .hidden }
        
        var iconSymbolName : String {
            switch self {
            case .visible:
                return "eye.fill"
            case .hidden:
                return "eye.slash.fill"
            }
        }
    }
    
    enum Access : Int, Codable {
        case locked
        case unlocked
        
        var isLocked : Bool { return self == .locked }
        var isUnlocked : Bool { return self != .locked }
        var iconSymbolName : String {
            switch self {
            case .locked:
                return "lock.fill"
            case .unlocked:
                return "lock.open.fill"
            }
        }
    }
    
    
    // MARK: Properties
    let id : LayerUID
    
    // MARK: Private
    // MARK: Lifecycle
    // MARK: Public
    var visiblity : Visiblity = .visible
    var access : Access = .unlocked
    var selection : Selection = .nonselected
    
    // Convenience var access
    var isSelected : Bool { return selection.isSelected}
    var isHidden : Bool { return visiblity.isHidden}
    var isVisible : Bool { return visiblity.isVisible}
    var isLocked : Bool { return access.isLocked}
    var isUnlocked : Bool { return access.isUnlocked}
    
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: Equatable
    static func == (lhs: BrickLayer, rhs: BrickLayer) -> Bool {
        return lhs.id == rhs.id
    }
    
    
}
