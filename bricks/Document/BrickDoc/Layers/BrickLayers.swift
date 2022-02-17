//
//  BrickLayers.swift
//  Bricks
//
//  Created by Ido on 03/01/2022.
//

import Foundation


class BrickLayers : CodableHashable {
    static let MAX_LAYERS_ALLOWED = 32
    
    // MARK: Properties
    private(set) var orderedLayers : [BrickLayer] = []
    
    // MARK: Privare
    // MARK: Lifecycle
    // MARK: Public
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(orderedLayers)
    }
    
    var selectedLayers : [BrickLayer] {
        return self.orderedLayers.filter(selection: .selected)
    }
    
    // MARK: Equatable
    static func == (lhs: BrickLayers, rhs: BrickLayers) -> Bool {
        return lhs.orderedLayers == rhs.orderedLayers
    }
    
    // MARK: Equality
    var count : Int {
        return orderedLayers.count
    }
    
    // MARK: Count and layers access
    var layersByOrderIndex : [Int:BrickLayer] {
        var result : [Int:BrickLayer]  = [:]
        orderedLayers.forEachIndex { index, layer in
            result[index] = layer
        }
        return result
    }
    
    func count(visiblility:BrickLayer.Visiblity)->Int {
        return orderedLayers.filter(visiblility: visiblility).count
    }
    
    func count(access:BrickLayer.Access)->Int {
        return orderedLayers.filter(access: access).count
    }
}

extension Sequence where Element : BrickLayer {
    func filter(access:BrickLayer.Access)->[BrickLayer] {
        return self.filter({ layer in
            layer.access == access
        })
    }
    
    func filter(visiblility:BrickLayer.Visiblity)->[BrickLayer] {
        return self.filter({ layer in
            layer.visiblity == visiblility
        })
    }
    
    func filter(selection:BrickLayer.Selection)->[BrickLayer] {
        return self.filter({ layer in
            layer.selection == selection
        })
    }
}
