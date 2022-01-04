//
//  BUID.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import Foundation

protocol BUID : Codable, Hashable, CustomStringConvertible {
    var uid : UUID! { get }
    var type : String { get }
}

extension BUID {
    
    // Rquatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.type == rhs.type && lhs.uid == rhs.uid
    }
    
    // Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(uid)
    }
    
    public var uuidString: String {
        return "\(type)|" + uid.uuidString
    }
    
    public var description: String {
        return uuidString
    }
}

public struct TUID : BUID {
    var uid : UUID!
    var type : String = "?"
    
    enum Types : String {
        case doc = "DOC"
        case layer = "LYR"
    }
    
    init(type newType:Types, uuid: UUID) {
        uid = uuid
        type = newType.rawValue
    }
    
    init(type newType:Types, uidString: String? = nil) {
        if let uidString = uidString?.components(separatedBy: "|").last {
            uid = UUID(uuidString: uidString)
        } else {
            uid = UUID()
        }
        
        type = newType.rawValue
    }
    
    init(type newType:String, uidString: String? = nil) {
        if let uidString = uidString?.components(separatedBy: "|").last {
            uid = UUID(uuidString: uidString)
        } else {
            uid = UUID()
        }
        
        type = newType
    }
}

protocol BUIDable : Identifiable where ID: BUID {
    
}
