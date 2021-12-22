//
//  MNProgress.swift
//  Bricks
//
//  Created by Ido on 21/12/2021.
//

import Foundation
import AppKit
import CoreAudioTypes

fileprivate let dlog : DSLogger? = DLog.forClass("MNProgress")

fileprivate var discreteMNProgNrFormatters : [String:NumberFormatter] = [:]


/// returns a formatted display string for progress units of completed items out of total items
/// - Parameters:
///   - completed: count of items completed
///   - total: count of total items to complete
///   - separator: thousands seperator
/// - Returns: a string in the format of "completed/total", with the assigned thousands separator
func progressUnitsDisplayString(completed:UInt64, total:UInt64, thousandsSeparator separator:String?)->String {
    guard total > 0 else {
        dlog?.fail("progressUnitsDisplayString total items is 0! (returning 0)")
        return ""
    }
    
    let completedF = clamp(value: completed, lowerlimit: 0, upperlimit: total) { val in
        dlog?.note("progressUnitsDisplayString completed items out of bounds, \(val) should be between [0...\(total)]")
    }
    
    if let separator = separator {
        var formatter = discreteMNProgNrFormatters[separator]
        if formatter == nil {
            formatter = NumberFormatter()
            formatter?.thousandSeparator = separator
            discreteMNProgNrFormatters[separator] = formatter
        }
        if let formatter = formatter {
            return "\(formatter.string(for: completedF) ?? "0")/\(formatter.string(for: total) ?? "0")"
        }
    }
    return "\(completedF)/\(total)"
}


/// returns a formatted percentage display string (0% - 100%) for a given progress fraction, with required decimal digit accuracy in the string.
/// - Parameters:
///   - fractionCompleted: fraction in the range of 0.0 ... 1.0 (othe values will be clamped)
///   - decimalDigits: amount of decimal digits in the resulting string, clamped to 0...12 digits.
/// - Returns: a string in the format of "100.0%" (or however many decimal digits required)
func progressFractionCompletedDisplayString(fractionCompleted: Double, decimalDigits:UInt = 0)->String {
    let fraction = clamp(value: fractionCompleted, lowerlimit: 0.0, upperlimit: 1.0) { val in
        dlog?.note("progressFractionCompletedDisplayString fraction out of bounds, \(val) should be between [0.0...1.0]")
    }
    
    if decimalDigits == 0 {
        return String(format: "%0", clamp(value: Int(fraction * 100), lowerlimit: 0, upperlimit: 100))
    } else {
        return String(format: "%0.\(clamp(value: decimalDigits, lowerlimit: 1, upperlimit: 12))", clamp(value: Int(fraction * 100), lowerlimit: 0, upperlimit: 100))
    }
}


/// Observers get updates of progress of any MNProgressEmitter
protocol MNProgressObserver {
    func mnProgress(emitter:MNProgressEmitter, didChangeLastAction:MNProgressAction?, fraction:Double, discretes:DiscreteMNProgStruct?)
    func mnProgress(emitter:MNProgressEmitter, action:MNProgressAction?, hadError:AppError, didStopAllProgress:Bool)
}

struct MNProgressAction {
    let title : String
    let subtitle : String?
    let info : Any?
    let isLongTimeAction : Bool
    
    init(title newTitle : String,
         subtitle newSubtitle : String?,
         info newInfo : Any? = nil,
         isLongTimeAction newIsLongTimeAction : Bool = false) {
        
        // Set new values
        self.title = newTitle
        self.subtitle = newSubtitle
        self.info = newInfo
        self.isLongTimeAction = newIsLongTimeAction
    }
}


protocol FractionalMNProg {
    var lastActionCompleted : MNProgressAction? { get }
    var fractionCompleted : Double { get }
    
    var fractionCompletedDisplayString : String { get }
    func fractionCompletedDisplayString(decimalDigits:UInt)->String
}

extension FractionalMNProg {
    var fractionCompletedDisplayString : String {
        return fractionCompletedDisplayString(decimalDigits: 0)
    }
    
    func fractionCompletedDisplayString(decimalDigits:UInt = 0)->String {
        if decimalDigits == 0 {
            return String(format: "%0", clamp(value: Int(fractionCompleted * 100), lowerlimit: 0, upperlimit: 100))
        } else {
            return String(format: "%0.\(clamp(value: decimalDigits, lowerlimit: 1, upperlimit: 12))", clamp(value: Int(fractionCompleted * 100), lowerlimit: 0, upperlimit: 100))
        }
    }
}

protocol DiscreteMNProg : FractionalMNProg {
    
    var totalUnitsCnt : UInt64 { get }
    
    var completedUnitsCnt : UInt64 { get }
    
    var progressUnitsDisplayString : String { get }
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
        return Bricks.progressUnitsDisplayString(completed: completedUnitsCnt, total: totalUnitsCnt, thousandsSeparator: separator)
    }
}

struct DiscreteMNProgStruct {
    var totalUnitsCnt : UInt64 = 0
    var completedUnitsCnt : UInt64 = 0
    
    var fractionCompleted : Double {
        guard totalUnitsCnt > 0 else {
            return 0.0
        }
        return Double(completedUnitsCnt) / Double(totalUnitsCnt)
    }
    
    init(totalUnits : UInt64, completedUnits : UInt64 = 0) {
        totalUnitsCnt = totalUnits
        completedUnitsCnt = completedUnits
    }
    
    init(mnProg:DiscreteMNProg) {
        totalUnitsCnt = mnProg.totalUnitsCnt
        completedUnitsCnt = mnProg.completedUnitsCnt
    }
    
    var progressUnitsDisplayString : String {
        return self.progressUnitsDisplayString(thousandsSeparator: nil)
    }
    
    func progressUnitsDisplayString(thousandsSeparator separator:String? = ",")->String {
        return Bricks.progressUnitsDisplayString(completed: completedUnitsCnt, total: totalUnitsCnt, thousandsSeparator: separator)
    }
}

struct FractionalMNProgStruct : FractionalMNProg {
    var lastActionCompleted: MNProgressAction? = nil
    var fractionCompleted : Double = 0.0
}

typealias MNProgressEmitter = FractionalMNProg & DiscreteMNProg
enum MNProgressEnum : MNProgressEmitter {
    
    // cases:
    case fraction(FractionalMNProg)
    case discrete(DiscreteMNProg)
    
    // MARK : FractionalMNProg
    var lastActionCompleted : MNProgressAction? {
        switch self {
        case .fraction(let fractionalMNProg):
            return fractionalMNProg.lastActionCompleted
        case .discrete(let discreteMNProg):
            return discreteMNProg.lastActionCompleted
        }
    }
    
    var fractionCompleted : Double {
        switch self {
        case .fraction(let fractionalMNProg):
            return fractionalMNProg.fractionCompleted
        case .discrete(let discreteMNProg):
            return discreteMNProg.fractionCompleted
        }
    }
    
    // MARK : DiscreteMNProg
    var totalUnitsCnt : UInt64 {
        switch self {
        case .fraction:
            return 1
        case .discrete(let discreteMNProg):
            return discreteMNProg.totalUnitsCnt
        }
    }
    
    var completedUnitsCnt : UInt64 {
        switch self {
        case .fraction:
            return (self.fractionCompleted == 1.0) ? 1 : 0
        case .discrete(let discreteMNProg):
            return discreteMNProg.totalUnitsCnt
        }
    }
}

//class MNProgress : MNTreeNode<MNProgressEnum>, FractionalMNProg, DiscreteMNProg {
//
//    // MARK: FractionalMNProg
//    var lastActionCompleted: MNProgressAction? = nil
//
//    var fractionCompleted: Double {
//
//    }
//
//    // MARK: DiscreteMNProg
//    var totalUnitsCnt: UInt64
//
//    var completedUnitsCnt: UInt64
//
//
//}

class TestMNProgressEmitter : DiscreteMNProg {
    var observers = ObserversArray<MNProgressObserver>()
    private var isPreventEmit : Bool = false
    
    static var shared = TestMNProgressEmitter()
    private init() {
    }
    
    var lastActionCompleted: MNProgressAction? = nil {
        didSet {
            emit()
        }
    }
    
    /// Make multiple changes, and will emit a progress notification only after all changes were made
    /// - Parameter block: block containing all changes to be made
    func blockChanges(_ block : ()->Void) {
        isPreventEmit = true
        block()
        isPreventEmit = false
        emit()
    }
    
    
    var totalUnitsCnt: UInt64 = 0 {
        didSet {
            emit()
        }
    }
    
    var completedUnitsCnt: UInt64 = 0 {
        didSet {
            emit()
        }
    }
    
    func emitError(error:AppError, isStopsAllProgress:Bool) {
        self.blockChanges {
            lastActionCompleted = MNProgressAction(title: "Test emitter failed with error", subtitle: "code #\(error.code)|\(error.domain)")
        }
        observers.enumerateOnMainThread { observer in
            observer.mnProgress(emitter: self, action: self.lastActionCompleted, hadError: error, didStopAllProgress: isStopsAllProgress)
        }

    }
    
    private func emit() {
        guard !isPreventEmit else {
            return
        }
        
        observers.enumerateOnMainThread { observer in
            observer.mnProgress(emitter: self,
                                didChangeLastAction: self.lastActionCompleted,
                                fraction: self.fractionCompleted,
                                discretes: self.asDiscreteMNProgStruct)
        }
    }
    
    func clearAction(incrementUnits:Bool) {
        // Will emit automatically
        self.lastActionCompleted = nil
    }
    
    func newAction(incrementUnits:Bool, title:String, subtitle:String?, isLong:Bool = false, info:Any? = nil) {
        blockChanges {
            let action = MNProgressAction(title: title, subtitle: subtitle, info: info, isLongTimeAction: isLong)
            if incrementUnits && self.completedUnitsCnt < totalUnitsCnt {
                self.completedUnitsCnt += 1
            }
            self.lastActionCompleted = action
        }
    }
    
    func timedTest(delay:TimeInterval, interval:TimeInterval, changesCount totalChanges:Int, finishWith:Result<Int, AppError>, observerToAdd:MNProgressObserver? = nil) {
        guard interval > 0 else {
            dlog?.note("TestMNProgressEmitter timedTest interval must be > 0!")
            return
        }
        
        dlog?.info("TestMNProgressEmitter timedTest will start in \(delay) sec. for \(totalChanges) events. Will end with:\(finishWith)")
        if let observerToAdd = observerToAdd {
            self.observers.add(observer: observerToAdd)
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: delay) {
            var counter = 0
            let rnd = TimeInterval.random(in: 0.0..<(interval * 0.5))
            Timer.scheduledTimer(withTimeInterval: interval + rnd, repeats: true) { timer in
                var isStop = false
                if counter < totalChanges {
                    let rand = Int.random(in: 0...24)
                    switch rand {
                    case 0...22:
                        self.completedUnitsCnt += 1
                    case 23:
                        self.newAction(incrementUnits: Bool.random(), title: "timedTest #\(counter) comp", subtitle: Int.random(in: 0...3) == 0 ? "Subtitle is now" : nil)
                    case 24:
                        isStop = Int.random(in: 0...100) == 100
                        self.emitError(error: AppError(AppErrorCode.misc_unknown, detail: "TestMNProgressEmitter.timedTest"), isStopsAllProgress: isStop)
                    default:
                        break
                    }
                } else {
                    isStop = true
                }
                if isStop || counter >= totalChanges {
                    dlog?.info("TestMNProgressEmitter Last test ")
                    timer.invalidate()
                } else {
                    dlog?.info("TestMNProgressEmitter test #\(counter)")
                }
                counter += 1
            }
        }
    }
}
