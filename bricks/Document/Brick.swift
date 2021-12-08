//
//  Brick.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("Brick")

class Brick : Codable, CustomDebugStringConvertible, Identifiable {
    var info : BrickBasicInfo
    var settings : BrickSettings
    var stats : BrickStats
    
    // MARK: Identifiable
    var id : BrickDocUUID {
        return info.id
    }
    
    // MARK: Lifecycle
    init() {
        info = BrickBasicInfo()
        settings = BrickSettings()
        stats = BrickStats()
    }
    
    // MARK: CustomDebugStringConvertible
    var debugDescription: String {
        get {
            return "Brick\n\(info.debugDescription)"
        }
    }
}
