//
//  BrickDocUIDs.swift
//  Bricks
//
//  Created by Ido on 06/04/2022.
//

import Foundation

struct BrickDocUID : BUID {
    var uid : UUID!
    var type : String { return TUID.Types.doc.rawValue }
}

struct LayerUID : BUID {
    var uid : UUID!
    var type : String { return TUID.Types.layer.rawValue }
}

struct UserUID : BUID {
    var uid : UUID!
    var type : String { return TUID.Types.user.rawValue }
    
    init(uidString: String? = nil) {
        if let uidString = uidString?.components(separatedBy: "|").last {
            uid = UUID(uuidString: uidString)
        } else {
            uid = UUID()
        }
        
    }
}

