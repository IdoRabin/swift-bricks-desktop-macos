//
//  BrickStats.swift
//  Bricks
//
//  Created by Ido Rabin on 20/07/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation

class BrickStats: Codable {
    var sessionCount : Int = 0
    var indexingCount : Int = 0
    
    var statsDisplayDictionary : [String:String] {
        get {
            var result : [String:String] = [:]
            result["sessions"] = String(sessionCount)
            result["indexing"] = String(indexingCount)
            return result
        }
    }
}
