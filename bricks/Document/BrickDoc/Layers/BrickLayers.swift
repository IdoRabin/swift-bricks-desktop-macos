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
    private(set) weak var selectedLayer : BrickLayer? = nil
    
    // MARK: Privare
    // MARK: Lifecycle
    // MARK: Public
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(orderedLayers)
    }
    
    // MARK: Equatable
    static func == (lhs: BrickLayers, rhs: BrickLayers) -> Bool {
        return lhs.orderedLayers == rhs.orderedLayers
    }
    
}
