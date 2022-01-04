//
//  BrickLayer.swift
//  Bricks
//
//  Created by Ido on 03/01/2022.
//

import Foundation

class BrickLayer : BUIDable, CodableHashable {
    
    // MARK: Properties
    let id : LayerUID
    
    // MARK: Privare
    // MARK: Lifecycle
    // MARK: Public
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: Equatable
    static func == (lhs: BrickLayer, rhs: BrickLayer) -> Bool {
        return lhs.id == rhs.id
    }
    
    
}
