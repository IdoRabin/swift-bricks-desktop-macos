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

class Brick : Codable, CustomDebugStringConvertible, BUIDable {
    
    var info : BrickBasicInfo
    var settings : BrickSettings
    var stats : BrickStats
    var layers : BrickLayers
    
    // MARK: Identifiable / BUIDable
    var id : BrickDocUID {
        return info.id
    }
    
    // MARK: Lifecycle
    init() {
        info = BrickBasicInfo()
        settings = BrickSettings()
        stats = BrickStats()
        layers = BrickLayers()
    }
    
    enum CodingKeys : CodingKey {
        case info
        case settings
        case stats
        case layers
    }
    
    // MARK: Decodable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.info = try container.decode(BrickBasicInfo.self, forKey: .info)
        self.settings = try container.decode(BrickSettings.self, forKey: .settings)
        self.stats = try container.decode(BrickStats.self, forKey: .stats)
        self.layers = try container.decode(BrickLayers.self, forKey: .layers)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(info, forKey: .info)
        try container.encode(settings, forKey: .settings)
        try container.encode(stats, forKey: .stats)
        try container.encode(layers, forKey: .layers)
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
