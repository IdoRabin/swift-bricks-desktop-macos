//
//  Brick.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("Brick")

protocol Changable : AnyObject {
    func didChange(sender:Any, propsAndVals:[String:String])
}

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

extension Brick : Changable {
    func didChange(sender: Any, propsAndVals: [String : String]) {
        self.info.lastModifiedDate = Date()
        self.stats.modificationsCount += 1
    }
}
