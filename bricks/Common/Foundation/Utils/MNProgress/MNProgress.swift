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

struct DiscreteMNProgStruct : DiscreteMNProg, Equatable {

    var totalUnitsCnt : UInt64 = 0
    var completedUnitsCnt : UInt64 = 0
    
    init(total : UInt64, completed : UInt64 = 0) {
        totalUnitsCnt = total
        completedUnitsCnt = completed
    }
    
    init(mnProg:DiscreteMNProg) {
        totalUnitsCnt = mnProg.totalUnitsCnt
        completedUnitsCnt = mnProg.completedUnitsCnt
    }
    
    static var empty : DiscreteMNProgStruct {
        return DiscreteMNProgStruct(total: 0, completed: 0)
    }
    
    static func ==(lhs:DiscreteMNProgStruct, rhs:DiscreteMNProgStruct)->Bool {
        return lhs.totalUnitsCnt == rhs.totalUnitsCnt && lhs.completedUnitsCnt == rhs.completedUnitsCnt
    }
    
}

struct FractionalMNProgStruct : FractionalMNProg {
    
    var fractionCompleted : Double = 0.0
    
    static var empty: FractionalMNProg {
        return FractionalMNProgStruct(fractionCompleted: 0)
    }
    
    static func ==(lhs:FractionalMNProgStruct, rhs:FractionalMNProgStruct)->Bool {
        return lhs.fractionCompleted == rhs.fractionCompleted
    }
}

enum MNProgressState : Int {
    case pending
    case inProgress
    case success
    case failed
    case userCanceled
}

enum MNProgressNum : Hashable, Equatable, FractionalMNProg {
    
    case unknown
    case fraction(Double)
    case discrete(DiscreteMNProgStruct)
    
    enum Simplified : Int {
        case unknown
        case fraction
        case discrete
    }
    
    
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        switch self {
        case .unknown:
            break
        case .fraction(let value):
            hasher.combine(value)
        case .discrete(let discreteMNProg):
            hasher.combine(discreteMNProg.totalUnitsCnt)
            hasher.combine(discreteMNProg.completedUnitsCnt)
        }
    }
    
    var simplified : Simplified {
        switch self {
        case .unknown: return .unknown
        case .fraction: return .fraction
        case .discrete: return .discrete
        }
    }
    
    var asDiscreteStruct : DiscreteMNProgStruct? {
        switch self {
        case .discrete(let discreteMNProgStruct):
            return discreteMNProgStruct
        default:
            return nil
        }
    }
    
    // MARK: Equatable
    static func ==(lhs:MNProgressNum, rhs:MNProgressNum)->Bool {
        var result = lhs.simplified == rhs.simplified
        if result {
            switch lhs.simplified {
            case .discrete:
                result = lhs.asDiscreteStruct == rhs.asDiscreteStruct
            case .fraction:
                result = (lhs.fractionCompleted == rhs.fractionCompleted)
            case .unknown:
                break // result is true
            }
        }
        return result
    }
    
    // MARK: FractionalMNProg
    var fractionCompleted: Double {
        switch self {
        case .unknown:
            return 0.0
        case .fraction(let value):
            return value
        case .discrete(let discreteStruct):
            return discreteStruct.fractionCompleted
        }
    }
}

struct MNProgress {
    var _progressNum : MNProgressNum = .unknown
    var _title : String?
    var _subtitle : String?
    var _info : Any?
    var _isLongTimeAction : Bool
    var _error : AppError?
    var _completionOverride : MNProgressState? = nil
    var completion : MNProgressState {
        if let comp = _completionOverride {
            return comp
        }
        if _progressNum == .unknown {
            return .pending
        } else if self._progressNum.fractionCompleted < 1.0 {
            return .inProgress
        } else {
            // fractionCompleted >= 1.0
            if let error = _error {
                if error.code == AppErrorCode.user_canceled.code {
                    return .userCanceled
                }
                return .failed
            } else {
                return .success
            }
        }
    }
    
    init(fractionCompleted:Double, info : Any? = nil) {
        _progressNum = .fraction(fractionCompleted)
        _title = nil
        _subtitle = nil
        _info = info
        _isLongTimeAction = false
        _error = nil
    }
    
    init(totalUnitsCnt:UInt64, completedUnitsCnt:UInt64, info : Any? = nil) {
        _progressNum = .discrete(DiscreteMNProgStruct(total: totalUnitsCnt, completed: completedUnitsCnt))
        _title = nil
        _subtitle = nil
        _info = info
        _isLongTimeAction = false
        _error = nil
    }
    
    init(totalUnitsCnt:Int, completedUnitsCnt:Int, info : Any? = nil) throws {
        guard totalUnitsCnt > 0 && completedUnitsCnt > 0 else {
            throw AppError(AppErrorCode.misc_failed_creating, detail: "MNProgress with Int totalUnitsCnt: \(totalUnitsCnt) completedUnitsCnt: \(completedUnitsCnt) cannot host negative values")
        }
        _progressNum = .discrete(DiscreteMNProgStruct(total: UInt64(totalUnitsCnt), completed: UInt64(completedUnitsCnt)))
        _title = nil
        _subtitle = nil
        _info = info
        _isLongTimeAction = false
        _error = nil
    }
    
    init(totalUnitsCnt:Float, completedUnitsCnt:Float, rounding rule:FloatingPointRoundingRule = .toNearestOrAwayFromZero, info : Any? = nil) throws {
        guard totalUnitsCnt > 0 && completedUnitsCnt > 0 else {
            throw AppError(AppErrorCode.misc_failed_creating, detail: "MNProgress with Double totalUnitsCnt: \(totalUnitsCnt) completedUnitsCnt: \(completedUnitsCnt) cannot host negative values")
        }
        _progressNum = .discrete(DiscreteMNProgStruct(total: UInt64(totalUnitsCnt.rounded(rule)), completed: UInt64(completedUnitsCnt.rounded(rule))))
        _title = nil
        _subtitle = nil
        _info = info
        _isLongTimeAction = false
        _error = nil
    }
    
    init(totalUnitsCnt:Double, completedUnitsCnt:Double, rounding rule:FloatingPointRoundingRule = .toNearestOrAwayFromZero, info : Any? = nil) throws {
        guard totalUnitsCnt > 0 && completedUnitsCnt > 0 else {
            throw AppError(AppErrorCode.misc_failed_creating, detail: "MNProgress with Double totalUnitsCnt: \(totalUnitsCnt) completedUnitsCnt: \(completedUnitsCnt) cannot host negative values")
        }
        _progressNum = .discrete(DiscreteMNProgStruct(total: UInt64(totalUnitsCnt.rounded(rule)), completed: UInt64(completedUnitsCnt.rounded(rule))))
        _title = nil
        _subtitle = nil
        _info = info
        _isLongTimeAction = false
        _error = nil
    }
    
    init(title : String, subtitle : String? = nil, info : Any? = nil, isLongTimeAction : Bool = false, error : AppError? = nil) {
        self._progressNum = .unknown
        self._title = title
        self._subtitle = subtitle
        _info = info
        _isLongTimeAction = isLongTimeAction
        _error = error
    }
    
    init(error : AppError, title : String, subtitle : String? = nil, info : Any? = nil, isStopsProgress:Bool = false) {
        self._progressNum = .unknown
        self._title = title
        self._subtitle = subtitle ?? "\(error.domain)|\(error.code)"
        _info = info
        _isLongTimeAction = false
        _error = error
        if isStopsProgress {
            _completionOverride = (error.code == AppErrorCode.user_canceled.code) ? .userCanceled : .failed
        }
    }
    
    init(userCanceledTitle title: String, subtitle : String? = nil, info : Any? = nil) {
        self._progressNum = .unknown
        self._title = title
        self._subtitle = subtitle ?? "\(AppErrorCode.user_canceled.domain))|\(AppErrorCode.user_canceled)"
        _info = nil
        _isLongTimeAction = false
        _error = AppError(AppErrorCode.user_canceled)
        _completionOverride = .userCanceled
    }
    
    init(error : AppError, info : Any? = nil, isStopsProgress:Bool = false) {
        self._progressNum = .unknown
        self._title = error.localizedDescription
        self._subtitle = "\(error.domain)|\(error.code)"
        _info = nil
        _isLongTimeAction = false
        _error = error
        if isStopsProgress {
            _completionOverride = (error.code == AppErrorCode.user_canceled.code) ? .userCanceled : .failed
        }
    }
    
    init(completed:MNProgressState, title: String, subtitle : String? = nil, info : Any? = nil) {
        self._progressNum = .unknown
        self._title = title
        self._subtitle = subtitle
        _info = nil
        _isLongTimeAction = false
        _completionOverride = completed
        
        switch completed {
        case .success:
            self._progressNum = .fraction(1)
        case .userCanceled:
            self._error = AppError(AppErrorCode.user_canceled)
        default:
            break
        }
        _error = nil
    }
    
    // MARK: Static
    static fileprivate var discreteMNProgNrFormatters : [String:NumberFormatter] = [:]

    /// returns a formatted display string for progress units of completed items out of total items
    /// - Parameters:
    ///   - completed: count of items completed
    ///   - total: count of total items to complete
    ///   - separator: thousands seperator
    /// - Returns: a string in the format of "completed/total", with the assigned thousands separator
    static func progressUnitsDisplayString(completed:UInt64, total:UInt64, thousandsSeparator separator:String?)->String {
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
    static func progressFractionCompletedDisplayString(fractionCompleted: Double, decimalDigits:UInt = 0)->String {
        let fraction = clamp(value: fractionCompleted, lowerlimit: 0.0, upperlimit: 1.0) { val in
            dlog?.note("progressFractionCompletedDisplayString fraction out of bounds, \(val) should be between [0.0...1.0]")
        }
        
        if decimalDigits == 0 {
            return String(format: "%0", clamp(value: Int(fraction * 100), lowerlimit: 0, upperlimit: 100))
        } else {
            return String(format: "%0.\(clamp(value: decimalDigits, lowerlimit: 1, upperlimit: 12))", clamp(value: Int(fraction * 100), lowerlimit: 0, upperlimit: 100))
        }
    }
}

extension MNProgress {
    
}


/*
// MNProgress is a bit like an OptionSet of MNProgressEnum where each option has an associated value.
struct MNProgress {
    
    var items : Set<MNProgressType>
    
    private func item(ofType type : MNProgressType.Simplified)->MNProgressType? {
        if let found = items.first(where: { item in
            item.simplified == type
        }) {
            return found
        }
        return nil
    }
    
    // MARK: lifecycle
    init() {
        items = Set<MNProgressType>()
    }
    
    static var empty : MNProgress {
        return MNProgress()
    }
    
    var isEmpty : Bool {
        return items.count == 0
    }
    
    // MARK: Validataion
    @discardableResult
    func validate()->Bool {
        
        
        guard self.items.count > 0 else {
            dlog?.note("Invalid MNProgress - must contain at least one item")
            return false
        }
        
        let simplifiedItems = self.items.simplified
        if let fractionCompleted : Double = self.item(ofType: .fraction), let discFraction = discrete?.fractionCompleted {
            let delta = abs(fractionCompleted - discFraction)
            if delta > 0.001 {
                // the two data points do not match
                dlog?.note("Invalid MNProgress - discrete counts mismatched the fraction completed.")
                return false
            }
        }
        
        if let discrete = discrete, discrete.isOverflow {
            dlog?.note("NOTE: MNProgress - discrete numbers did overflow (>100% progress)")
        }
        
        if let fraction = fractionCompleted, fraction > 1.0 {
            dlog?.note("NOTE: MNProgress - fraction did overflow (>100% progress)")
        }
        
        if simplifiedItems.contains(.fraction) && simplifiedItems.contains(.discrete) {
            var nativeFraction : Double? = nil
            if let fraction : Double = self.item(ofType: .fraction) {
                nativeFraction = fraction
            } else if let fraction : FractionalMNProgStruct = self.item(ofType: .fraction) {
                nativeFraction = fraction.fractionCompleted
            }
            if let fractionCompleted = nativeFraction, let discFraction = discrete?.fractionCompleted {
                let delta = abs(fractionCompleted - discFraction)
                if delta > 0.001 {
                    // the two data points do not match
                    if IS_DEBUG {
                        let fractionStr = Self.progressFractionCompletedDisplayString(fractionCompleted: fractionCompleted)
                        let discFractionStr = Self.progressFractionCompletedDisplayString(fractionCompleted: discFraction)
                        dlog?.note("Invalid MNProgress - discrete counts mismatched the fraction completed. fraction: \(fractionStr) discrete items count:\(self.progressUnitsDisplayString.descOrNil) -> calced fraction: \(discFractionStr)")
                    }
                    return false
                }
            }
        }
        
        return true
    }
    
    // MARK: Update from source
    mutating func update(fromFractional prog:FractionalMNProg & AnyObject) {
        guard prog !== self.item(ofType: .fraction) else {
            return
        }
        
        if let disc = prog as? DiscreteMNProg & AnyObject {
            self.update(fromDiscrete: disc)
            return
        }
        
        if let discrete = self.discrete {
            if abs(discrete.fractionCompleted - prog.fractionCompleted) > 0.001 {
                dlog?.note("Updating progress: dicrete counts do not match the fractional being added! \(self.progressUnitsDisplayString.descOrNil) = \(self.fractionCompletedDisplayString.descOrNil) != \(prog.fractionCompletedDisplayString)")
            }
        }
        
        self.fractionCompleted = prog.fractionCompleted
    }
    
    mutating func update(fromDiscrete prog:DiscreteMNProg & AnyObject) {
        if prog.isOverflow {
            dlog?.note("Updating progress: adding dicrete numbers that are > 100%")
        }
        
        if let frac : FractionalMNProg = self.item(ofType: .fraction)  {
            if abs(prog.fractionCompleted - frac.fractionCompleted) > 0.001 {
                dlog?.note("Updating progress: dicreets being added does not match the fraction elready in. adding: \(prog.progressUnitsDisplayString) = \(prog.fractionCompletedDisplayString) != \(self.fractionCompletedDisplayString.descOrNil)")
            }
        }
        
        self.discrete = DiscreteMNProgStruct(totalUnits: prog.totalUnitsCnt, completedUnits: prog.completedUnitsCnt)
    }
    
    var onChanged : ((_ context:String, _ progress:MNProgress)->Void)? = nil
    
    // MARK: Display strings
    var progressUnitsDisplayString : String? {
        return self.progressUnitsDisplayString(thousandsSeparator: nil)
    }
    
    var fractionCompletedDisplayString : String? {
        return fractionCompletedDisplayString(decimalDigits: 0)
    }
    
    func fractionCompletedDisplayString(decimalDigits:UInt = 0)->String? {
        guard let fraction = self.fractionCompleted else {
            return nil
        }
        
        return MNProgress.progressFractionCompletedDisplayString(fractionCompleted: fraction, decimalDigits: decimalDigits)
    }
    
    func progressUnitsDisplayString(thousandsSeparator separator:String? = ",")->String? {
        guard let discrete = self.discrete else {
            return nil
        }
        return MNProgress.progressUnitsDisplayString(completed: discrete.completedUnitsCnt, total: discrete.totalUnitsCnt, thousandsSeparator: separator)
    }
    
    func didChange(context:String) {
        dlog?.info("didChange \(context)")
        onChanged?(context, self)
    }
    
    // MARK: Properties
    var completed: MNProgressCompletionType? {
        get {
            if let result : MNProgressCompletionType = self.item(ofType: .completed) {
                return result
            }
            return nil
        }
        set {
            var wasChanged = false
            if let val = newValue {
                wasChanged = (val != self.completed)
                items.update(with: .completed(val))
            } else {
                wasChanged = (self.completed != nil)
                items.remove(type: .completed)
            }
            if wasChanged {
                didChange(context: "completed")
            }
            validate()
        }
    }
    
    var error: AppError? {
        get {
            if let result : AppError = self.item(ofType: .error) {
                return result
            }
            return nil
        }
        set {
            var wasChanged = false
            if let val = newValue {
                wasChanged = (val.domain != self.error?.domain || val.code != self.error?.code)
                items.update(with: .error(val))
            } else {
                wasChanged = error != nil
                items.remove(type: .error)
            }
            if wasChanged {
                didChange(context: "error")
            }
            validate()
        }
    }
    
    var actionCompleted: MNProgressAction? {
        get {
            if let result : MNProgressAction = self.item(ofType: .actionCompleted) {
                return result
            }
            return nil
        }
        set {
            var wasChanged = false
            if let val = newValue {
                wasChanged = (val != self.actionCompleted)
                items.update(with: .actionCompleted(val))
            } else {
                wasChanged = actionCompleted != nil
                items.remove(type: .actionCompleted)
            }
            if wasChanged {
                didChange(context: "actionCompleted")
            }
            validate()
        }
    }
    
    var discrete: DiscreteMNProg? {
        get {
            if let result : DiscreteMNProg = self.item(ofType: .discrete) {
                return result
            }
            return nil
        }
        set {
            var wasChanged = false
            if let val = newValue {
                wasChanged = (val.fractionCompleted != self.discrete?.fractionCompleted || val.totalUnitsCnt != self.discrete?.totalUnitsCnt || val.completedUnitsCnt != self.discrete?.completedUnitsCnt)
                let newStruct = DiscreteMNProgStruct(totalUnits: val.totalUnitsCnt, completedUnits: val.completedUnitsCnt)
                items.update(with: .discrete(newStruct))
            } else {
                wasChanged = (self.discrete != nil)
                items.remove(type: .discrete)
            }
            if wasChanged {
                didChange(context: "discrete")
            }
            validate()
        }
    }
    
    var totalUnitsCnt: UInt64? {
        get {
            return self.discrete?.totalUnitsCnt
        }
        set {
            if let val = newValue {
                let newDiscrete = DiscreteMNProgStruct(totalUnits: val, completedUnits: self.discrete?.completedUnitsCnt ?? 0)
                self.discrete = newDiscrete
            } else {
                self.discrete = nil
            }
        }
    }
    
    var completedUnitsCnt: UInt64? {
        get {
            return self.discrete?.completedUnitsCnt
        }
        set {
            if let val = newValue {
                let newDiscrete = DiscreteMNProgStruct(totalUnits: self.discrete?.totalUnitsCnt ?? 0, completedUnits: val)
                self.discrete = newDiscrete
            } else {
                self.discrete = nil
            }
        }
    }
    
    var fractionCompleted: Double? {
        get {
            if let discrete = self.discrete {
                return discrete.fractionCompleted
            } else if let fraction : Double = self.item(ofType: .fraction) {
                return fraction
            } else if let fraction : FractionalMNProgStruct = self.item(ofType: .fraction) {
                return fraction.fractionCompleted
            }
            return nil
        }
        set {
            var wasChanged = false
            if let val = newValue {
                wasChanged = (val != self.fractionCompleted)
                items.update(with: .fraction(FractionalMNProgStruct(fractionCompleted: val)))
            } else {
                wasChanged = (self.fractionCompleted != nil)
                items.remove(type: .fraction)
            }
            if wasChanged {
                didChange(context: "fractionCompleted")
            }
            validate()
        }
    }
}

extension MNProgress /* emit to an MNProgressObserver */ {
    
    func emit(observers : ObserversArray<MNProgressObserver>) {
        emit(observers: observers.array())
    }
    
    func emit(observer : MNProgressObserver) {
        self.emit(observers: [observer])
    }
    
    func emit(observers : [MNProgressObserver]) {
        
        func execute(_ block:@escaping (MNProgressObserver)->Void) {
            DispatchQueue.mainIfNeeded {
                observers.forEach { observer in
                    block(observer)
                }
            }
        }
        
        let simplified = self.items.simplified
        if (simplified.contains(.discrete) || simplified.contains(.fraction)) &&
            !simplified.contains(.completed) {
            execute { observer in
                observer.mnProgress(emitter: self, didProgress: self, fraction: self.fractionCompleted ?? 0.0, discretes: self.discrete)
            }
        } else if (simplified.contains(.error) || simplified.contains(.actionCompleted)) &&
                    !simplified.contains(.completed) {
            execute { observer in
                observer.mnProgress(emitter: self, didChange: self, action: self.actionCompleted, error: self.error)
            }
        } else if simplified.contains(.completed), let completed = self.completed {
            
            execute { observer in
                observer.mnProgress(emitter: self, didComplete: self, type: completed, error: self.error)
            }
        } else {
            dlog?.note("emit: TODO: Analyze this situation better")
            execute { observer in
                observer.mnProgress(emitter: self, didChange: self, action: self.actionCompleted, error: self.error)
            }
        }
        
    }
}
*/
