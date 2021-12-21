//
//  ProgressCounter.swift
//  XPlan
//
//  Created by Ido on 16/11/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("ProgressCounter")

protocol ProgressObserver {
    func progressDidChange(emitter:ProgressEmitter?, progress:CGFloat, count:Int?, total:Int?, info:Any?)
}

protocol ProgressEmitter {
    var progress : CGFloat { get } /* 0.0 ... 1.0*/
}

protocol CountedProgressEmitter : ProgressEmitter {
    var propgressTotalCnt : Int? { get }
    var propgressCurrentCnt : Int? { get }
    func setProgress(count:Int, total:Int)->CGFloat
}

/// Progress emitter for multiple counters, using a key to identify each counter
protocol MultiProgressEmitter {
    
    /// Total progress the multi progress made in all its counters summed up.
    var totalProgress : CGFloat { get } /* 0.0 ... 1.0 */
    
    /// Array of all ProgressEmitter this MultiProgressEmitter manages
    func progressCountersArray()->[ProgressEmitter]
    
    /// Dictionary copy of all ProgressEmitters and their respetive keys this MultiProgressEmitter manages
    func progressCounters()->[AnyHashable:ProgressEmitter]
    
    /// All ProgressEmitters for the given keys this MultiProgressEmitter manages
    func progressCounters(forKeys:[AnyHashable])->[ProgressEmitter]
    
    /// A ProgressEmitter for a given key this MultiProgressEmitter manages
    func progressCounter(forKey:AnyHashable)->ProgressEmitter?
}

fileprivate func safeClamp<T:Comparable>(value:T, lowerlimit:T, upperlimit:T)->T {
    if IS_DEBUG {
        if value > upperlimit {
            dlog?.note("safeClamp failed value: \(value) > upperlimit: \(upperlimit)")
        } else if value < lowerlimit {
            dlog?.note("safeClamp failed value: \(value) < lowerlimit: \(lowerlimit)")
        }
    }
    return clamp(value: value, lowerlimit: lowerlimit, upperlimit: upperlimit)
}

class ProgressCounter : CountedProgressEmitter {
    var observers = ObserversArray<ProgressObserver>()
    
    private func calcProgressIfPossible() {
        if let total = propgressTotalCnt, let cnt = self.propgressCurrentCnt {
            if total == 0 {
                self.progress = 0
            } else {
                self.progress = CGFloat(cnt) / CGFloat(total)
            }
        } else if IS_DEBUG {
            if propgressTotalCnt != nil || self.propgressCurrentCnt != nil {
                dlog?.note("calcProgressIfPossible went wrong? currentCnt:\(propgressCurrentCnt.descOrNil) / totalCnt:\(propgressTotalCnt.descOrNil) - only one has a value, while the other is nil?")
            }
        }
    }
    
    func reset() {
        _lastNotifiedProg = 0.0
    }
    
    private var _lastNotifiedProg : CGFloat = 0.0
    private func notifyObservers() {
        var prog = self.progress
        if let decimalPr = self.decimalPercision {
            let prec : CGFloat = CGFloat(pow(10.0, CGFloat(max(decimalPr, 0))))
            prog = round(self.progress * prec) / prec
        }
        prog = safeClamp(value: prog, lowerlimit: 0.0, upperlimit: 1.0)
        
        // Notify
        if _lastNotifiedProg != prog {
            _lastNotifiedProg = prog
            observers.enumerateOnMainThread { observer in
                observer.progressDidChange(emitter: self, progress: prog, count: nil, total: nil, info: nil)
            }
        }
    }
    
    var decimalPercision : Int? = 2 {
        didSet {
            calcProgressIfPossible()
        }
    }
    
    private var _totalCnt : Int? = nil
    var propgressTotalCnt : Int? {
        get { return _totalCnt }
        set { if newValue != _totalCnt {
            _totalCnt = newValue
            calcProgressIfPossible() // may set into self.progress
        }}
    }
    
    private var _currentCnt : Int? = nil
    var propgressCurrentCnt : Int? {
        get { return _currentCnt }
        set { if newValue != _currentCnt {
            _currentCnt = newValue
            calcProgressIfPossible() // may set into self.progress
        }}
    }

    
    @discardableResult
    func setProgress(count:Int, total:Int)->CGFloat {
        if IS_DEBUG {
            if total <= 0 {
                dlog?.note("set(count:\(count), total:\(total) total <= 0.0")
            }
            if count > abs(total) {
                dlog?.note("set(count:\(count), total:\(total) count > abs(total)")
            }
            if count.signum() != total.signum() {
                dlog?.note("set(count:\(count), total:\(total). One is negative and one is positive")
            }
        }
        
        if ((_currentCnt != count) || (_totalCnt != total)) {
            _currentCnt = count
            _totalCnt = total
            self.calcProgressIfPossible()
        }
        return self.progress
    }
    
    var progress: CGFloat = 0.0 {
        didSet {
            if progress != oldValue {
                notifyObservers()
            }
        }
    }
}

extension ProgressCounter : Hashable {
    
    static func ==(lhs:ProgressCounter, rhs:ProgressCounter)-> Bool {
        return lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(String(memoryAddressOf: self))
    }
}

protocol MultiProgressObserver : ProgressObserver {
    
}

extension Sequence where Element : CountedProgressEmitter {
    /// Sum of all total counts for all CountedProgressEmitters in the array
    var sumTotalCnts : Int {
        var sum : Int = 0
        for prog in self {
            if let tot = prog.propgressTotalCnt {
                sum += tot
            }
        }
        return sum
    }
    
    /// Sum of all current counts for all CountedProgressEmitters in the array
    var sumCurrentCnts : Int {
        var sum : Int = 0
        for prog in self {
            if let cnt = prog.propgressCurrentCnt {
                sum += cnt
            }
        }
        return sum
    }
    
    /// Sum of all progress floats for all CountedProgressEmitters in the array
    var sumProgresses : CGFloat {
        var sum : CGFloat = 0
        for prog in self {
            sum += prog.progress
        }
        return sum
    }
}

extension Dictionary where Value : CountedProgressEmitter {
    
    
    /// Sum of all total counts for all CountedProgressEmitters in the dictionary
    var sumTotalCnts : Int {
        var sum : Int = 0
        for (_, prog) in self {
            if let tot = prog.propgressTotalCnt {
                sum += tot
            }
        }
        return sum
    }
    
    
    /// Sum of all current counts for all CountedProgressEmitters in the dictionary
    var sumCurrentCnts : Int {
        var sum : Int = 0
        for (_, prog) in self {
            if let cnt = prog.propgressCurrentCnt {
                sum += cnt
            }
        }
        return sum
    }
    
    /// Sum of all progress floats for all CountedProgressEmitters in the dictionary
    var sumProgresses : CGFloat {
        var sum : CGFloat = 0
        for (_, prog) in self {
            sum += prog.progress
        }
        return sum
    }
}

class MultiProgressCounter<Key:Hashable> {
    
    var observers = ObserversArray<MultiProgressObserver>()
    
    enum CalcTotalKind {
        
        //  When calculating the total progress - All ProgressCounters have equal weights.
        case equalWeights
        
        //  When calculating the total progress - Each ProgressCounter is weighted by its propgressTotalCnt out of the sum of totalCnts of all counterss
        case weightByTotals
        
        //  When calculating the total progress - The dictionay should describe the weight to be given for each counter by its key
        //  The sum of all values in the dictionary can be any value. The values in the dictionary will be normalized for all the weights to sum up to 1.
        case weightPerKey([Key:CGFloat])
    }
    
    var calcTotalKind : CalcTotalKind = .equalWeights
    private var progreii : [Key:ProgressCounter] = [:]
    
    func progressCounter(forKey key:Key)->ProgressCounter? {
        return progreii[key]
    }
    
    func progress(forKey key:Key)->CGFloat? {
        guard let prog = progreii[key] else {
            dlog?.note("Progress for [\(key)] was not found. Creating now (0.0).")
            return nil
        }
        return prog.progress
    }
    
    
    /// Create a new ProgressCounter() for the given key with the given progress value, or does nothing and returns false if counter for this key already exists
    /// - Parameters:
    ///   - val: progress value to init with
    ///   - key: key to use for this ProgressCounter in the MultiProgressCounter
    /// - Returns: true if created a new ProgressCounter, false otherwise
    func createProgIfNeeded(_ val:CGFloat, forKey key:Key)->Bool {
        if progreii[key] == nil {
            let new = ProgressCounter()
            new.progress = val
            progreii[key] = new
            return true
        }
        
        dlog?.note("createProgIfNeeded ProgressCounter of key: [\(key)] already exists.")
        return false
    }
    
    
    /// Create a new ProgressCounter() for the given key with the given progress valuea, or does nothing and returns false if counter for this key already exists.
    /// - Parameters:
    ///   - count: int count out of total (progress = count / total)
    ///   - total: total count (progress = count / total)
    ///   - key:key to use for this ProgressCounter in the MultiProgressCounter
    /// - Returns: true if created a new ProgressCounter, false otherwise
    func createProgIfNeeded(count:Int, total:Int, forKey key:Key)->Bool {
        if progreii[key] == nil {
            let new = ProgressCounter()
            new.setProgress(count: count, total: total)
            progreii[key] = new
            return true
        }
        
        dlog?.note("createProgIfNeeded ProgressCounter of key: [\(key)] already exists.")
        return false
    }
    
    func setProgress(_ val:CGFloat, forKey key:Key) {
        if !self.createProgIfNeeded(val, forKey: key) {
            progreii[key]?.progress = val
        }
    }
    
    func setProgress(count:Int, total:Int, forKey key:Key) {
        if !self.createProgIfNeeded(count: count, total: total, forKey: key) {
            progreii[key]?.setProgress(count: count, total: total)
        }
    }
    
    func resetProgress(forKey key:Key) {
        progreii[key]?.reset()
    }
    
    private var _lastNotifiedTotalProg : CGFloat = 0.0
    private var lastTotalProg : CGFloat = 0.0 {
        didSet {
            if lastTotalProg != oldValue {
                notifyObservers()
            }
        }
    }
    
    private func notifyObservers() {
        var prog = self.lastTotalProg
        if let decimalPr = self.decimalPercision {
            let prec : CGFloat = CGFloat(pow(10.0, CGFloat(max(decimalPr, 0))))
            prog = round(self.lastTotalProg * prec) / prec
        }
        prog = safeClamp(value: prog, lowerlimit: 0.0, upperlimit: 1.0)

        // Notify
        if _lastNotifiedTotalProg != prog {
            _lastNotifiedTotalProg = prog
            observers.enumerateOnMainThread {[self] observer in
                observer.progressDidChange(emitter: self as? ProgressEmitter,
                                           progress: prog,
                                           count: progreii.sumCurrentCnts,
                                           total: progreii.sumTotalCnts,
                                           info: nil)
            }
        }
    }
    
    
    /// Return all progressConters with a non-nil propgressTotalCnt
    /// - Returns: count of all progressConters that have a non-nil propgressTotalCnt
    private func countAllItemedProgreii()->Int {
        var sum = 0
        for (_, prog) in progreii {
            sum += (prog.propgressTotalCnt != nil) ? 1 : 0
        }
        return sum
    }
    
    private func calcProgressAsEqualWeights() {
        
        //  When calculating the total progress - All ProgressCounters have equal weights.
        var sumProgress  : CGFloat = 0.0
        var countedItems : CGFloat = 0.0
        for (_, prog) in progreii {
            let progress = prog.progress
            let tot = prog.propgressTotalCnt ?? (progress != 0.0 ? 1 : 0)
            if progress != 0 || tot != 0 {
                sumProgress += safeClamp(value: abs(progress), lowerlimit: 0.0, upperlimit: 1.0)
                countedItems += 1.0
            }
        }
        
        self.lastTotalProg = (countedItems != 0.0) ? sumProgress / countedItems : 0.0
    }
    
    private func calcProgressAsWeightByTotals() {
        //  When calculating the total progress - Each ProgressCounter is weighted by its propgressTotalCnt out of the sum of totalCnts of all counterss
        //  A ProgressCounter with totalCnt of 0 is calced as if
        var sumTotals  : CGFloat = 0.0
        var sumProgress  : CGFloat = 0.0
        var countedItems : CGFloat = 0.0
        for (_, prog) in progreii {
            if let tot = prog.propgressTotalCnt {
                sumTotals += CGFloat(tot)
            }
        }
        for (_, prog) in progreii {
            if let tot = prog.propgressTotalCnt {
                let weight = CGFloat(tot) / sumTotals
                sumProgress += prog.progress * weight
                countedItems += 1
            }
        }
        
        self.lastTotalProg = (countedItems != 0.0) ? sumProgress / countedItems : 0.0
    }
    
    private func calcProgressAsWeightsPerKey(_ dic:[Key:CGFloat]) {
        //  When calculating the total progress - The dictionay should describe the weight to be given for each counter by its key
        //  The sum of all values in the dictionary can be any value. The values in the dictionary will be normalized for all the weights to sum up to 1.
        if IS_DEBUG {
            var sum : CGFloat = 0.0
            for (_, val) in dic {
                if val <= 0 {
                    dlog?.note("calcProgressAsWeightsPerKey - weight <= 0.0")
                } else if val > 1.0 {
                    dlog?.note("calcProgressAsWeightsPerKey - weight > 1.0")
                }
                sum += val
            }
            if sum < 0.99999 || sum > 1.00001 {
                dlog?.note("calcProgressAsWeightsPerKey - sum of all weights != 1.0")
            }
        }
        
        // Now we can calc the progress:
        var progressSum : CGFloat = 0.0
        var countedItems : CGFloat = 0.0
        let newDic = dic.normalizingValues()
        for (key, val) in self.progreii {
            if let weight = newDic[key] {
                progressSum += (weight * val.progress)
                countedItems += 1
            } else {
                dlog?.info("calcProgressAsWeightsPerKey no weight for key: \(key)")
            }
        }
        
        self.lastTotalProg = (countedItems != 0.0) ? progressSum : 0.0
    }
    
    private func calcTotalProgressIfPossible() {

        switch calcTotalKind {
        case .equalWeights:
            //  When calculating the total progress - All ProgressCounters have equal weights.
            calcProgressAsEqualWeights()
            
        case .weightByTotals:
            //  When calculating the total progress - Each ProgressCounter is weighted by its propgressTotalCnt out of the sum of totalCnts of all counterss
            //  A ProgressCounter with propgressTotalCnt of 0 is calced as if
            self.calcProgressAsWeightByTotals()
            
        case .weightPerKey(let dictionary):
            //  When calculating the total progress - The dictionay should describe the weight to be given for each counter by its key
            //  The sum of all values in the dictionary can be any value. The values in the dictionary will be normalized for all the weights to sum up to 1.
            self.calcProgressAsWeightsPerKey(dictionary)
            
        }
    }
    
    var decimalPercision : Int? = 2 {
        didSet {
            calcTotalProgressIfPossible()
        }
    }
}

extension MultiProgressCounter : MultiProgressEmitter {
    
    /// Total progress the multi progress made in all its counters summed up.
    var totalProgress: CGFloat {
        if self._lastNotifiedTotalProg == 0.0 || self.lastTotalProg == 0.0 {
            self.calcTotalProgressIfPossible()
        }
        return self.lastTotalProg
    }
    
    ///  All Progress emitters managed by this MultiProgressCounter
    /// - Returns:Array of all ProgressEmitter that this MultiProgressCounter manages
    func progressCountersArray()->[ProgressEmitter] {
        return self.progreii.valuesArray
    }
    
    ///  All Progress emitters managed by this MultiProgressCounter, by key
    /// - Returns:dictionary of all counteres managed by this MultiProgressCounter by thir respective keys
    func progressCounters() -> [AnyHashable : ProgressEmitter] {
        return self.progreii
    }
    
    
    /// All ProgressEmitters for the given keys this MultiProgressEmitter manages
    /// - Parameter keys: keys to use to filter the counters
    /// - Returns:all counters managed by this MultiProgressCounter that correspond to the given keys
    func progressCounters(forKeys keys:[AnyHashable])->[ProgressEmitter] {
        guard let keys = keys as? [Key] else {
            dlog?.note("progressCounter(forKeys:..) keys are expected to be of type \(Key.self)")
            return []
        }
        var result : [ProgressEmitter] = []
        for key in keys {
            if let emt = self.progreii[key] {
                result.append(emt)
            }
        }
        return result
    }
    
    
    /// A ProgressEmitter for a given key this MultiProgressEmitter manages
    /// - Parameter key: keys to use to find the wanted counter
    /// - Returns: The ProgressEmitter for the given key, or nil
    func progressCounter(forKey key:AnyHashable)->ProgressEmitter? {
        guard let key = key as? Key else {
            dlog?.note("progressCounter(forKey:..) key is expected to be of type \(Key.self)")
            return nil
        }
        return self.progreii[key]
    }
}
