//
//  MNProgress protocols.swift
//  Bricks
//
//  Created by Ido on 23/12/2021.
//

import Foundation

/// Observers get updates of progress of any emitter of MNProgress
protocol MNProgressObserver {
    func mnProgress(sender:Any, isPendingProgress:MNProgress, fraction:Double, discretes:DiscreteMNProg?)
    func mnProgress(sender:Any, didStartProgress:MNProgress, fraction:Double, discretes:DiscreteMNProg?)
    func mnProgress(sender:Any, didProgress:MNProgress, fraction:Double, discretes:DiscreteMNProg?)
    func mnProgress(sender:Any, didComplete:MNProgress, state:MNProgressState)
}

protocol FractionalMNProg {
    var fractionCompleted : Double { get }
    
    var fractionCompletedDisplayString : String { get }
    func fractionCompletedDisplayString(decimalDigits:UInt)->String
    
    var isEmpty : Bool { get }
}

extension FractionalMNProg {
    
    var fractionCompletedDisplayString : String {
        return fractionCompletedDisplayString(decimalDigits: 0)
    }
    
    func fractionCompletedDisplayString(decimalDigits:UInt = 0)->String {
        return MNProgress.progressFractionCompletedDisplayString(fractionCompleted: self.fractionCompleted, decimalDigits: decimalDigits)
    }
    
    // MARK: hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(fractionCompleted)
    }
    
    var isEmpty : Bool {
        return fractionCompleted == 0.0
    }
}

protocol DiscreteMNProg : FractionalMNProg {
    
    var totalUnitsCnt : UInt64 { get }
    
    var completedUnitsCnt : UInt64 { get }
    
    var progressUnitsDisplayString : String { get }
    
    var isOverflow : Bool { get }
}

extension DiscreteMNProg {
    
    var fractionCompleted : Double {
        guard totalUnitsCnt > 0 else {
            return 0.0
        }
        return Double(completedUnitsCnt) / Double(totalUnitsCnt)
    }
    
    var asDiscreteMNProgStruct : DiscreteMNProgStruct {
        return DiscreteMNProgStruct(mnProg: self)
    }
    
    // Convenience - for naming fo fit the observer protocol nicely
    var asUnitsStruct : DiscreteMNProgStruct {
        return self.asDiscreteMNProgStruct
    }
    
    var progressUnitsDisplayString : String {
        return self.progressUnitsDisplayString(thousandsSeparator: nil)
    }
    
    func progressUnitsDisplayString(thousandsSeparator separator:String? = ",")->String {
        return MNProgress.progressUnitsDisplayString(completed: completedUnitsCnt, total: totalUnitsCnt, thousandsSeparator: separator)
    }
    
    // MARK: hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(totalUnitsCnt)
        hasher.combine(completedUnitsCnt)
    }
    
    var isEmpty : Bool {
        return completedUnitsCnt == 0 && totalUnitsCnt == 0
    }
    var isOverflow : Bool {
        return !isEmpty && completedUnitsCnt > totalUnitsCnt
    }
}
