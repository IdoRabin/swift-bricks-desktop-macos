//
//  BrickSettings.swift
//  Bricks
//
//  Created by Ido Rabin on 11/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Cocoa

struct BrickSettings : Codable {
    
    var drawingSnapToGrid : Bool = true
    var drawingGridSize : CGFloat = 10.0
}
