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
    
    var isComplete : Bool {
        switch self {
        case .pending ,.inProgress:
            return false
        case .success, .failed, .userCanceled:
            return true
        }
    }
    
    var isFailed : Bool {
        return self == .failed || self == .userCanceled
    }
    
    var isCanceled : Bool {
        return self == .userCanceled
    }
    
    var isSuccess : Bool {
        return self == .success
    }
    
    var imageSystemSymbolName : String {
        switch self {
        case .pending:       return "" // "pause.circle.fill" ? "hand.raised.square.on.square" ? "plus.square.fill.on.square.fill"
        case .inProgress:    return "" // "gearshape.circle.fill" ? "ellipsis.circle.fill"
        case .success:       return "checkmark.circle"
        case .failed:        return "exclamationmark.circle" // .triangle
        case .userCanceled:  return "x.circle"
        }
    }
    
    var iconImage : NSImage? {
        let image = NSImage(systemSymbolName: self.imageSystemSymbolName, accessibilityDescription: nil)
        return image
    }
    
    var iconTintColor : NSColor {
        switch self {
        case .pending:       return NSColor.clear
        case .inProgress:    return NSColor.clear
        case .success:       return NSColor.appSuccessGreen
        case .failed:        return NSColor.appFailureRed
        case .userCanceled:  return NSColor.appFailureOrange
        }
    }
    
    var iconBkgColor : NSColor {
        switch self {
        case .pending:       return NSColor.clear
        case .inProgress:    return NSColor.clear
        case .success:       return NSColor.appSuccessGreen
        case .failed:        return NSColor.appFailureRed
        case .userCanceled:  return NSColor.appFailureOrange
        }
    }
    var displayString : String {
        switch self {
        case .pending:       return AppStr.PENDING.localized()
        case .inProgress:    return AppStr.PROGRESS.localized()
        case .success:       return AppStr.SUCCESS.localized()
        case .failed:        return AppStr.FAILED.localized()
        case .userCanceled:  return AppStr.USER_CANCELED.localized()
        }
    }
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
    
    var asDiscreteStructOrNil : DiscreteMNProgStruct? {
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
                result = lhs.asDiscreteStructOrNil == rhs.asDiscreteStructOrNil
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

fileprivate struct MNProgressStateContextTuple : Equatable {
    let state: MNProgressState
    let context:String
    static func ==(lhs:MNProgressStateContextTuple, rhs:MNProgressStateContextTuple)->Bool {
        return lhs.state == rhs.state &&
               lhs.context == rhs.context
    }
}

struct MNProgressEmitSignature : Equatable, Hashable {
    let msg : String
    let fraction : CGFloat
    let titlesHash : Int
    let userInfoHash : Int
    let errorHash : Int
    let stateHash : Int
    
    init (messageName:String, progress:MNProgress) {
        msg = messageName
        fraction = progress.fractionCompleted
        titlesHash = (progress.title?.hashValue ?? 0) ^ (progress.subtitle?.hashValue ?? 0)
        userInfoHash = (progress.userInfo != nil ? 1 : 0)
        errorHash = (progress.error?.code ?? 0) ^ (progress.error?.domain.hashValue ?? 0)
        stateHash = progress.state.hashValue
    }
    
    init() {
        msg = ""
        fraction = 0.0
        titlesHash = 0
        userInfoHash = 0
        errorHash = 0
        stateHash = 0
    }
    
    static var empty : MNProgressEmitSignature {
        return MNProgressEmitSignature()
    }
}

struct MNProgress : FractionalMNProg {
    private var _progressNum : MNProgressNum = .unknown
    private var _title : String?
    private var _subtitle : String?
    private var _userInfo : Any?
    private var _isLongTimeAction : Bool
    private var _error : AppError?
    private var _lastStateChange : (MNProgressState, MNProgressState) = (.pending, .pending)
    private var _stateOverride : MNProgressState? = nil
    public var onStateChanged : ((MNProgress, MNProgressState, MNProgressState)->Void)? = nil
    public var onChanged : ((MNProgress, [String])->Void)? = nil
    private var _lastEmittedSignature : MNProgressEmitSignature = .empty
    
    // MARK: Read-only properties
    var state : MNProgressState {
        if let stt = _stateOverride {
            return stt
        }
        let fraction = self.fractionCompleted
        if _progressNum == .unknown {
            return .pending
        } else if fraction >= 0.0 && fraction < 1.0 {
            // fractionCompleted < 1.0
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
    
    var title : String? {
        return _title
    }
    
    var subtitle : String? {
        return _subtitle
    }
    
    var userInfo : Any? {
        return _userInfo
    }
    
    var isLongTimeAction : Bool {
        return _isLongTimeAction
    }
    
    var error : AppError? {
        return _error
    }
    
    var discreteStructOrNil : DiscreteMNProgStruct? {
        return _progressNum.asDiscreteStructOrNil
    }
    
    // MARK: FractionalMNProg
    var fractionCompleted: Double {
        switch _progressNum {
        case .unknown:
            return 0.0
        case .fraction(let double):
            return double
        case .discrete(let discreteMNProgStruct):
            return discreteMNProgStruct.fractionCompleted
        }
    }
    
    var totalUnitsCnt : UInt64? {
        return self.discreteStructOrNil?.totalUnitsCnt
    }
    
    var completedUnitsCnt : UInt64? {
        return self.discreteStructOrNil?.completedUnitsCnt
    }
    
    // MARK: Mutations
    private mutating func changed(context:String) {
        let key = "MNProgress.\(String(memoryAddressOfStruct: &self))"
        let cts = MNProgressStateContextTuple(state: self.state, context: context)
        TimedEventFilter.shared.filterEvent(key: key, threshold: 0.1, accumulating: cts) {[self] contexts in
            if let contexts = contexts, contexts.count > 0 {
                let startState = contexts.first?.state ?? _lastStateChange.1
                let endState = self.state
                if startState != endState {
                    dlog?.info("state changed from: \(startState) to: \(endState)")
                    self.onStateChanged?(self, startState, endState)
                }
                
                // dlog?.info("changed(context:) \(contexts.map { $0.context }.descriptionsJoined)")
                self.onChanged?(self, contexts.map { $0.context })
            }
        }
    }
    
    mutating func setProgress(fractionCompleted newFraction:Float, isStateInProgress : Bool = true) throws {
        try self.setProgress(fractionCompleted: Double(newFraction), isStateInProgress:isStateInProgress)
    }
    
    mutating func setProgress(fractionCompleted newFraction:Double, isStateInProgress : Bool = true, isCompletesWhenFull: Bool = true) throws {
        guard fractionCompleted < 0 else {
            throw AppError(AppErrorCode.misc_failed_creating, detail: "MNProgress.setProgress.Failed with a negative fractionCompleted : Double")
        }
        
        if self.fractionCompleted != newFraction {
            let prevNum = self._progressNum
            let prevFraction = self.fractionCompleted

            let fractionChangeed = prevFraction != newFraction
            if fractionChangeed && isStateInProgress && newFraction < 1.0 {
                self.setState(.inProgress, error: nil, fraction: nil)
                changed(context: "state=.inProgress")
            } else if prevFraction != newFraction && isCompletesWhenFull && newFraction == 1.0 && self.state.isComplete == false {
                self.setState(.success, error: nil, fraction: nil)
                changed(context: "state=.success")
            }
            if fractionChangeed {
                self._progressNum = .fraction(newFraction)
                dlog?.info("setProgress fraction: \(self.fractionCompletedDisplayString)")
                changed(context: "progress fraction=\(newFraction)")
            }
            
            if (prevNum == .unknown) || (prevFraction <= 0.0 && newFraction > 0.0) {
                // out of bounds?
            }
        }
    }
    
    mutating func setProgress(totalUnitsCnt:UInt64, completedUnitsCnt:UInt64, isStateInProgress : Bool = true, isCompletesWhenFull: Bool = true) {
        let prevStruct = self.discreteStructOrNil
        let newStruct = DiscreteMNProgStruct(total: totalUnitsCnt, completed: completedUnitsCnt)

        self._progressNum = .discrete(newStruct)
        // dlog?.info("setProgress discretes: \(newStruct.progressUnitsDisplayString) | \(self.fractionCompletedDisplayString)")
        
        var willChange = false
        if let prevStruct = prevStruct, prevStruct != newStruct  {
            willChange = true
        } else if prevStruct == nil {
            willChange = true
        }
        
        // Order is important
        if willChange && isStateInProgress && newStruct.fractionCompleted < 1.0 {
            self.setState(.inProgress, error: nil, fraction: nil)
            changed(context: "state=.inProgress")
        } else if willChange && isCompletesWhenFull && newStruct.fractionCompleted == 1.0 && self.state.isComplete == false {
            self.setState(.success, error: nil, fraction: nil)
            changed(context: "state=.success")
        }
        
        if willChange {
            changed(context: "discretes=\(newStruct.completedUnitsCnt)/\(newStruct.totalUnitsCnt)")
        }
    }
    
    mutating func setProgress(totalUnitsCnt:Int, completedUnitsCnt:Int, isStateInProgress : Bool = true) throws {
        guard totalUnitsCnt >= 0 && completedUnitsCnt >= 0 else {
            throw AppError(AppErrorCode.misc_failed_creating, detail: "MNProgress.setProgress.Failed creating DiscreteMNProgStruct with a negative Int")
        }
        
        self.setProgress(totalUnitsCnt: UInt64(totalUnitsCnt), completedUnitsCnt: UInt64(completedUnitsCnt))
    }
    
    mutating func setState(_ newState: MNProgressState, error:AppError?, fraction:Double?) {
        if self._stateOverride != newState ||
            (newState == .inProgress && _lastStateChange.0 == .pending) {
            // Set new state
            let prev = self.state
            self._stateOverride = newState
            let new = self.state
            if prev != new || (prev == new && prev == .inProgress) {
                _lastStateChange = (prev, new)
            }
            changed(context: "state=.newState")
        }
        
        if (self._error?.code ?? 0) != (error?.code ?? 0) {
            self._error = error
            changed(context: "error=\(error?.domainCodeDesc ?? "<nil>" )")
        }
        if let fraction = fraction {
            switch self._progressNum {
            case .unknown, .fraction:
                if self.fractionCompleted != fraction {
                    self._progressNum = .fraction(fraction)
                    changed(context: "fraction=\(self.fractionCompletedDisplayString)")
                }
            case .discrete(let adisc):
                let newCompleted = UInt64(ceil(Double(adisc.totalUnitsCnt) * fraction))
                if self.fractionCompleted != fraction {
                    self._progressNum = .discrete(DiscreteMNProgStruct(total: adisc.totalUnitsCnt, completed: newCompleted))
                    changed(context: "discretes=\(self.fractionCompletedDisplayString)")
                }
            }
        }
    }
    
    mutating func setTitle(title:String, subtitle:String?) {

        if self._title != title {
            self._title = title
            changed(context: "title=\(title)")
        }
        
        if self._subtitle != subtitle {
            self._subtitle = subtitle
            changed(context: "subtitle = \(subtitle ?? "<nil>")")
        }
    }
    
    mutating func clearTitles() {
        if self._title?.count ?? 0 != 0 || self.subtitle?.count ?? 0 != 0 {
            self._title = nil
            self._subtitle = nil
            changed(context: "(title,subtitle)=(nil,nil)")
        }
    }
    
    mutating func setUserInfo(userInfo newInfo:Any?) {
        if self.userInfo == nil && newInfo != nil ||
            self.userInfo != nil && newInfo == nil {
            self._userInfo = newInfo
            changed(context: "userInfo")
        } else if let userInfo = userInfo, let newInfo = newInfo {
            // TODO: Find a mechanis for opaque equatabls, i.e checking two type erased infos if they are equal..
            // For now we test pointer equality
            if userInfo as AnyObject !== newInfo as AnyObject {
                self._userInfo = newInfo
                changed(context: "userInfo")
            }
        }
    }
    
    mutating func incerementCompletedUnits(isCompletesOnLast:Bool = true) {
        if let num = self.discreteStructOrNil {
            if IS_DEBUG && num.completedUnitsCnt + 1 > num.totalUnitsCnt {
                dlog?.note("incerementCompletedUnits made the progress above 100%! \(num.progressUnitsDisplayString) = \(num.fractionCompletedDisplayString)")
            }
            if num.totalUnitsCnt == num.completedUnitsCnt + 1 && !self.state.isComplete {
                self.setState(.success, error: nil, fraction: nil)
            }
            self.setProgress(totalUnitsCnt: num.totalUnitsCnt, completedUnitsCnt: num.completedUnitsCnt + 1)
        }
    }
    
    mutating func clearUserInfo() {
        if self.userInfo != nil {
            self._userInfo = nil
            changed(context: "userInfo")
        }
    }
    
    mutating func setIsLongTimeAction(_ newVal : Bool) {
        if self.isLongTimeAction != newVal {
            _isLongTimeAction = newVal
            changed(context: "isLongTimeAction=\(newVal)")
        }
    }
    
    mutating func setError(_ newError : AppError?, isFailsProgress:Bool) {
        
        if isFailsProgress {
            if newError == nil {
                dlog?.note("setError set isStopsProgress:true while the error was set to nil!")
            }
            // Will trigger calling completed
            // func mnProgress(sender:Any, didComplete:...
            self.setState(.failed, error: newError, fraction: nil)
        }
        
        if self.error != newError {
            self._error = newError
            changed(context: "error=\(newError?.localizedDescription ?? "<nil>")")
        }
    }
    
    @discardableResult
    mutating func complete(successTitle:String?, subtitle:String?)->Bool {
        guard !self.state.isComplete else {
            dlog?.note("Cannot complete the MNProgress -> it has already completed: \(self.state)")
            return false
        }
        
        if let successTitle = successTitle {
            self.setTitle(title: successTitle, subtitle: subtitle)
        } else if let subtitle = subtitle {
            self.setTitle(title: subtitle, subtitle: nil)
        }
        
        if let discr = self.discreteStructOrNil {
            self.setProgress(totalUnitsCnt: discr.totalUnitsCnt, completedUnitsCnt: discr.totalUnitsCnt)
        } else {
            do {
                try self.setProgress(fractionCompleted: Double(1.0))
            } catch let error {
                dlog?.note("setProgress 1.0 failed! \(error.localizedDescription)")
            }
        }
        
        return true
    }
    
    @discardableResult
    mutating func complete(withError:AppError?, title:String?, subtitle:String?)->Bool {
        guard !self.state.isComplete else {
            dlog?.note("Cannot complete the MNProgress -> it has already completed: \(self.state)")
            return false
        }
        
        if error?.code == AppErrorCode.user_canceled.code {
            return self.completeUserCanceled()
        }
        
        self.setError(withError, isFailsProgress: true)
        return true
    }
    
    @discardableResult
    mutating func completeUserCanceled()->Bool {
        guard !self.state.isComplete else {
            dlog?.note("Cannot complete the MNProgress -> it has already completed: \(self.state)")
            return false
        }
        
        self.setState(.userCanceled, error: nil, fraction: nil)
        
        return true
    }
    
    // MARK: LifeCycle
    init(fractionCompleted:Float, info : Any? = nil) {
        _progressNum = .fraction(Double(fractionCompleted))
        _title = nil
        _subtitle = nil
        _userInfo = info
        _isLongTimeAction = false
        _error = nil
    }
    
    init(fractionCompleted:Double, info : Any? = nil) {
        _progressNum = .fraction(fractionCompleted)
        _title = nil
        _subtitle = nil
        _userInfo = info
        _isLongTimeAction = false
        _error = nil
    }
    
    init(totalUnitsCnt:UInt64, completedUnitsCnt:UInt64, info : Any? = nil) {
        _progressNum = .discrete(DiscreteMNProgStruct(total: totalUnitsCnt, completed: completedUnitsCnt))
        _title = nil
        _subtitle = nil
        _userInfo = info
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
        _userInfo = info
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
        _userInfo = info
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
        _userInfo = info
        _isLongTimeAction = false
        _error = nil
    }
    
    init(title : String, subtitle : String? = nil, info : Any? = nil, isLongTimeAction : Bool = false, error : AppError? = nil) {
        self._progressNum = .unknown
        self._title = title
        self._subtitle = subtitle
        _userInfo = info
        _isLongTimeAction = isLongTimeAction
        _error = error
    }
    
    init(error : AppError, title : String, subtitle : String? = nil, info : Any? = nil, isStopsProgress:Bool = false) {
        self._progressNum = .unknown
        self._title = title
        self._subtitle = subtitle ?? "\(error.domainCodeDesc)"
        _userInfo = info
        _isLongTimeAction = false
        _error = error
        if isStopsProgress {
            _stateOverride = (error.code == AppErrorCode.user_canceled.code) ? .userCanceled : .failed
        }
    }
    
    init(userCanceledTitle title: String, subtitle : String? = nil, info : Any? = nil) {
        self._progressNum = .unknown
        self._title = title
        self._subtitle = subtitle ?? "\(AppErrorCode.user_canceled.domainCodeDesc)"
        _userInfo = nil
        _isLongTimeAction = false
        _error = AppError(AppErrorCode.user_canceled)
        _stateOverride = .userCanceled
    }
    
    init(error : AppError, info : Any? = nil, isStopsProgress:Bool = false) {
        self._progressNum = .unknown
        self._title = error.localizedDescription
        self._subtitle = "\(error.domainCodeDesc)"
        _userInfo = nil
        _isLongTimeAction = false
        _error = error
        if isStopsProgress {
            _stateOverride = (error.code == AppErrorCode.user_canceled.code) ? .userCanceled : .failed
        }
    }
    
    init(completed:MNProgressState, title: String, subtitle : String? = nil, info : Any? = nil) {
        self._progressNum = .unknown
        self._title = title
        self._subtitle = subtitle
        _userInfo = nil
        _isLongTimeAction = false
        
        let prevState = self.state
        if prevState != completed {
            _lastStateChange = (prevState, completed)
            _stateOverride = completed
        }
        
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
    var isEmpty: Bool {
        return self.fractionCompleted == 0 && state == .pending
    }
    
    static var empty : MNProgress {
        var result = MNProgress(fractionCompleted: 0.0, info: nil)
        result.setState(.pending, error: nil, fraction: nil)
        return result
    }
    
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
            return String(format: "%d%%", clamp(value: Int(fraction * 100), lowerlimit: Int(0), upperlimit: Int(100)))
        } else {
            return String(format: "%0.\(clamp(value: decimalDigits, lowerlimit: 1, upperlimit: 12))f%%", clamp(value: Int(fraction * 100), lowerlimit: 0, upperlimit: 100))
        }
    }
}

extension MNProgress /* emit to an MNProgressObserver */ {
    
    mutating func emit(observers : ObserversArray<MNProgressObserver>, sender:Any) {
        emit(observers: observers.array(), sender: sender)
    }
    
    mutating func emit(observer : MNProgressObserver, sender:Any) {
        self.emit(observers: [observer], sender: sender)
    }
    
    mutating func emit(observers : [MNProgressObserver], sender:Any) {
        
        func execute(_ block:@escaping (MNProgressObserver)->Void) {
            DispatchQueue.mainIfNeeded {
                observers.forEach { observer in
                    block(observer)
                }
            }
        }
        
        let fraction = self.fractionCompleted
        let discrete = self._progressNum.asDiscreteStructOrNil
        let immutableCopy = self
        switch _lastStateChange {
        case (_, .pending):
            let newSummary = MNProgressEmitSignature(messageName: "pending", progress: self)
            if newSummary != self._lastEmittedSignature {
                self._lastEmittedSignature = newSummary
                execute { observer in
                    observer.mnProgress(sender: sender, isPendingProgress: immutableCopy, fraction: fraction, discretes: discrete)
                }
            } else {
                // dlog?.note("Already emitted signature: \(newSummary.msg) prec: \(round(newSummary.fraction * 10000) / 100)")
            }
        case (.pending, .inProgress):
            let newSummary = MNProgressEmitSignature(messageName: "startProgress", progress: self)
            if newSummary != self._lastEmittedSignature {
                self._lastEmittedSignature = newSummary
                
                execute { observer in
                    observer.mnProgress(sender: sender, didStartProgress: immutableCopy, fraction: fraction, discretes: discrete)
                }
                _lastStateChange = (.inProgress, .inProgress)
            } else {
                // dlog?.note("Already emitted signature: \(newSummary.msg) prec: \(round(newSummary.fraction * 10000) / 100)")
            }
        case (_, .inProgress):
            let newSummary = MNProgressEmitSignature(messageName: "progress", progress: self)
            if newSummary != self._lastEmittedSignature {
                self._lastEmittedSignature = newSummary
                
                execute { observer in
                    observer.mnProgress(sender: sender, didProgress: immutableCopy, fraction: fraction, discretes: discrete)
                }
                // self.logAll(title:"")
                
            } else {
                // dlog?.note("Already emitted signature: \(newSummary.msg) prec: \(round(newSummary.fraction * 10000) / 100)")
            }
        case (_, .userCanceled), (_, .failed), (_, .success):
            let newSummary = MNProgressEmitSignature(messageName: "complete", progress: self)
            if newSummary != self._lastEmittedSignature {
                self._lastEmittedSignature = newSummary
                
                execute { observer in
                    observer.mnProgress(sender: sender, didComplete: immutableCopy, state: immutableCopy.state)
                }
            } else {
                // dlog?.note("Already emitted signature: \(newSummary.msg) prec: \(round(newSummary.fraction * 10000) / 100)")
            }
        }
    }
    
}

extension MNProgress : CustomStringConvertible {
    var description: String {
        let fractionStr = self.fractionCompletedDisplayString
        return "\(type(of: self)) \(self.title ?? AppStr.UNTITLED.localized()) state: \(self.state) progress: \(fractionStr) discrete: \(self.discreteStructOrNil?.progressUnitsDisplayString ?? "<not discrete>")"
    }
}

extension MNProgress : Hashable {
    
    static func == (lhs: MNProgress, rhs: MNProgress) -> Bool {
        return lhs.state == rhs.state && lhs.hashValue == rhs.hashValue
    }
    
}
