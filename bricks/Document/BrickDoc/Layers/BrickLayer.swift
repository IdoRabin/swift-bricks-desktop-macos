//
//  BrickLayer.swift
//  Bricks
//
//  Created by Ido on 03/01/2022.
//

import Foundation
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("BrickLayer")

class BrickLayer : BUIDable, CodableHashable, CustomStringConvertible {
    
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
        
        var iconSymbolName : ImageString {
            switch self {
            case .visible:
                return ImageString("eye.fill")
            case .hidden:
                return ImageString("eye.slash.fill")
            }
        }
        
        func toggled()->Visiblity {
            switch self {
            case .visible: return .hidden
            case .hidden: return .visible
            }
        }
    }
    
    enum Access : Int, Codable {
        case locked
        case unlocked
        
        var isLocked : Bool { return self == .locked }
        var isUnlocked : Bool { return self != .locked }
        var iconSymbolName : ImageString {
            switch self {
            case .locked:
                return ImageString("lock.fill")
            case .unlocked:
                return ImageString("lock.open.fill")
            }
        }
        
        func toggled()->Access {
            switch self {
            case .locked: return .unlocked
            case .unlocked: return .locked
            }
        }
    }
    
    // MARK: Properties
    let id : LayerUID
    var name : String? = nil
    
    // MARK: Private
    // MARK: Lifecycle
    // MARK: Public
    var visiblity : Visiblity = .visible
    var access : Access = .unlocked
    var selection : Selection = .nonselected
    
    private (set) var creationDate : Date? = nil
    private (set) var creatingUserId : UserUID? = nil
    
    // Convenience var access
    var isSelected : Bool { return selection.isSelected}
    var isHidden : Bool { return visiblity.isHidden}
    var isVisible : Bool { return visiblity.isVisible}
    var isLocked : Bool { return access.isLocked}
    var isUnlocked : Bool { return access.isUnlocked}
    
    init(uid:LayerUID? = nil, name newTitle:String? = nil) {
        id = LayerUID(uid: uid?.uid ?? UUID())
        name = newTitle
    }
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: Equatable
    static func == (lhs: BrickLayer, rhs: BrickLayer) -> Bool {
        return lhs.id == rhs.id
    }
    
    var description: String {
        var results = ["<BrickLayer id:\(id.description)"]
        if let name = self.name, name.count > 0 {
            results.append("\"\(name)\"")
        }
        if self.isLocked {
            results.append("LCK")
        }
        if self.isHidden {
            results.append("HID")
        }
        if self.isSelected {
            results.append("SEL")
        }
        return results.joined(separator: String.NBSP) + ">"
    }
    
    func sanitize(_ str : String?)->String? {
        var result = Brick.sanitize(str)
        
        if let str = str?.lowercased() {
            if str.contains(AppStr.UNNAMED.localized()) &&
                str.contains(id.uid.uuidString.prefix(4).lowercased()){
                result = nil
            }
            
            if str.contains(id.uid.uuidString.lowercased()) {
                result = nil
            }
        }
        
        return result
    }
    
}
