//
//  MNProgress.swift
//  Bricks
//
//  Created by Ido on 21/12/2021.
//

import Foundation

// Mix of the native Progress class and other ideas:
protocol MNProgressObserver {
    func mnProgressDidChange(emitter:FractionalMNProg?, progress:CGFloat, count:Int?, total:Int?, info:Any?)
}

protocol FractionalMNProg {
    var lastActionComplated : String? { get }
    var fractionComplated : Double { get }
}

protocol DiscreteMNProg : FractionalMNProg {
    var totalUnitsCnt : UInt64 { get }
    var completedUnitsCnt : UInt64 { get }
}

extension DiscreteMNProg {
    var fractionComplated : Double {
        guard totalUnitsCnt > 0 else {
            return 0.0
        }
        return Double(completedUnitsCnt) / Double(totalUnitsCnt)
    }
}

enum MNProgress {
    case fraction(FractionalMNProg)
    case discrete(DiscreteMNProg)
}

protocol MNProgressEmitter : DiscreteMNProg {
    var childMNProgressEmitters : [MNProgressEmitter] {get}
    
}
