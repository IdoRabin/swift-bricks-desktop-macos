//
//  BrickStats.swift
//  Bricks
//
//  Created by Ido Rabin on 20/07/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation

class BrickStats: Codable {
    
    var sessionCount : UInt = 1
    var indexingCount : UInt = 0
    var modificationsCount : UInt = 0
    var savesCount : UInt = 0
    var loadsCount : UInt = 0
    
    var statsDisplayDictionary : [String:String] {
        get {
            var result : [String:String] = [:]
            result["sessions"] = String(sessionCount)
            result["indexing"] = String(indexingCount)
            result["savesCount"] = String(savesCount)
            result["modificationsCount"] = String(modificationsCount)
            result["loadsCount"] = String(loadsCount)
            return result
        }
    }
}
