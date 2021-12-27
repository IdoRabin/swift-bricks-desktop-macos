//
//  TestMNProgressEmitter.swift
//  Bricks
//
//  Created by Ido on 23/12/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = nil // DLog.forClass("TestMNProgressEmitter")

class TestMNProgressEmitter {

    var observers = ObserversArray<MNProgressObserver>()
    private var isPreventEmit : Bool = false

    static var shared = TestMNProgressEmitter()
    private init() {
        progress.onStateChanged = {[weak self] (mnProgress : MNProgress, fromState : MNProgressState, toState : MNProgressState) in
            if let self = self {
                self.emit()
            }
        }
        progress.onChanged = {[weak self] (mnProgress : MNProgress, changes : [String]) in
            if let self = self {
                self.emit()
            }
        }
    }
    
    var progress = MNProgress.empty

    /// Make multiple changes, and will emit a progress notification only after all changes were made
    /// - Parameter block: block containing all changes to be made
    func blockChanges(_ block : ()->Void) {
        isPreventEmit = true
        block()
        isPreventEmit = false
        emit()
    }
    
    func emitError(error:AppError, isStopsAllProgress:Bool) {
        self.blockChanges {
            progress.setError(error, isFailsProgress: isStopsAllProgress)
            progress.setTitle(title: "Test emitter failed with error", subtitle: "\(error.domainCodeDesc)")
        }
        progress.emit(observers: self.observers, sender: self)
    }

    private func emit() {
        guard !isPreventEmit else {
            return
        }

        if true {
            self.progress.emit(observers: self.observers, sender: self)
        } else {
            // let key = "\(type(of: self)).\(String(memoryAddressOf: self)).emit"
            // TimedEventFilter.shared.filterEvent(key: key, threshold: 0.1) {[weak self] in
            //     if let self = self {
            //         self.progress.emit(observers: self.observers, sender: self)
            //     }
            // }
        }
    }

    func clearAction(incrementUnits:Bool) {

        // Will emit automatically
        progress.clearTitles()
    }

    func newAction(incrementUnits:Bool, incrementsCompletesOnLast : Bool = true, title:String, subtitle:String?, isLong:Bool = false, info:Any? = nil) {
        blockChanges {
            progress.setTitle(title: title, subtitle: subtitle)
            progress.setIsLongTimeAction(isLong)
            progress.setUserInfo(userInfo: info)
            
            if incrementUnits {
                progress.incerementCompletedUnits(isCompletesOnLast: incrementsCompletesOnLast)
            }
        }
        progress.emit(observers: self.observers, sender: self)
    }

    func timedTest(delay:TimeInterval, interval:TimeInterval, changesCount totalChanges:Int, finishWith:Result<Int, AppError>?, observerToAdd:MNProgressObserver? = nil) {
        guard interval > 0 else {
            dlog?.note("TestMNProgressEmitter timedTest interval must be > 0!")
            return
        }

        dlog?.info("TestMNProgressEmitter timedTest will start in \(delay) sec. for \(totalChanges) events. Will end with:\(finishWith.descOrNil)")
        if let observerToAdd = observerToAdd {
            self.observers.add(observer: observerToAdd)
        }

        DispatchQueue.main.asyncAfter(delayFromNow: delay) {[weak self] in
            if let self = self {
                var counter = 0
                do {
                    try self.progress.setProgress(totalUnitsCnt: totalChanges, completedUnitsCnt: 0)
                } catch let error {
                    dlog?.note("timedTest threw error:\(error.localizedDescription)")
                }
                
                let isCanStopMidProgress = (finishWith == nil) && false
                
                let rnd = TimeInterval.random(in: 0.0..<(interval * 0.5))
                Timer.scheduledTimer(withTimeInterval: interval + rnd, repeats: true) {[weak self] timer in
                    if let self = self {
                        var isStop = false
                        var typeStr = ""
                        if counter < totalChanges {
                            let rand = Int.random(in: 0...24)
                            switch rand {
                            case 0...16:
                                // Increment by 1
                                //try self.progress.setProgress(totalUnitsCnt: totalChanges, completedUnitsCnt: counter)
                                self.progress.incerementCompletedUnits(isCompletesOnLast: isCanStopMidProgress)
                                typeStr = "increment"
                            case 17:
                                if isCanStopMidProgress {
                                    typeStr = "canceled"
                                    if self.progress.completeUserCanceled() {
                                        isStop = true
                                    }
                                }
                            case 18...20:
                                // Emit error
                                if isCanStopMidProgress {
                                    isStop = (counter == totalChanges) || Int.random(in: 0...100) > 75
                                }
                                self.emitError(error: AppError(AppErrorCode.misc_unknown, detail: "TestMNProgressEmitter.timedTest"), isStopsAllProgress: isStop)
                                typeStr = isStop ? "stoperror" : "  error  "
                                
                            case 21...24:
                                // Set new titles:
                                let prevCnt = self.progress.completedUnitsCnt ?? 0
                                self.newAction(incrementUnits: Bool.random(), incrementsCompletesOnLast:isCanStopMidProgress, title: "timedTest #\(counter) comp", subtitle: Int.random(in: 0...3) == 0 ? "Subtitle is now" : nil)
                                typeStr = (prevCnt != self.progress.completedUnitsCnt) ? "titles ++" : "titles   "
                            
                            default:
                                dlog?.note("Unknown step! \(counter)")
                                break
                            }
                        } else {
                            isStop = true
                            typeStr = "completed"
                        }
                        
                        if typeStr != "completed" && (isStop || self.progress.completedUnitsCnt ?? 0 >= totalChanges) {
                            dlog?.info("Timer emitting: [\(typeStr)] Last test state: \(self.progress.state)")
                            timer.invalidate()
                            
                        } else if counter >= totalChanges {
                            if self.progress.state.isComplete == false {
                                
                                if let finishWith = finishWith {
                                    switch finishWith {
                                    case .success:
                                        self.progress.complete(successTitle: "finishWith Success title", subtitle: "finishWith Success subtitle lorem iPsum")
                                    case .failure(let error):
                                        self.progress.complete(withError: error, title: "finishWith error title", subtitle: nil)
                                    }
                                }
                                switch Int.random(in: 0..<2) {
                                case 0:
                                    dlog?.info("Timer emitting: [\(typeStr)] completing SUCCESS")
                                    self.progress.complete(successTitle: "Success title", subtitle: "Success subtitle lorem iPsum")
                                case 1:
                                    dlog?.info("Timer emitting: [\(typeStr)] completing FAIL")
                                    self.progress.complete(withError: AppError(AppErrorCode.misc_unknown, detail: "TestMNProgressEmitter faile at end"), title: "Failed on last step", subtitle: "Failure on last step subtitle")
                                default:
                                    dlog?.note("unknown completion mode")
                                }
                            }
                            timer.invalidate()
                        } else {
                            dlog?.info("Timer emitting * : [\(typeStr)] test #\(counter) \(self.progress.fractionCompletedDisplayString)")
                        }
                        
                        if counter >= totalChanges && self.progress.state.isComplete == false {
                            dlog?.note("unknown completion mode at timer end.")
                        }
                        counter += 1
                    }
                }
            }
        }
    }
}
