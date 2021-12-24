//
//  TestMNProgressEmitter.swift
//  Bricks
//
//  Created by Ido on 23/12/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("MNProgress")

class TestMNProgressEmitter {
    
    var observers = ObserversArray<MNProgressObserver>()
    private var isPreventEmit : Bool = false

    static var shared = TestMNProgressEmitter()
    private init() {
        progress.onChanged = {[weak self](context, progress) in
            if let self = self, self.isPreventEmit == false {
                progress.emit(observers:self.observers)
            }
        }
    }

    var progress = MNProgress()
    
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
            progress.error = error
            progress.actionCompleted = MNProgressAction(title: "Test emitter failed with error", subtitle: "code #\(error.code)|\(error.domain)")
        }
        progress.emit(observers: self.observers)
    }
    
    private func emit() {
        guard !isPreventEmit else {
            return
        }

        progress.emit(observers: self.observers)
    }
    
    func clearAction(incrementUnits:Bool) {
        
        // Will emit automatically
        progress.actionCompleted = nil
    }
    
    func newAction(incrementUnits:Bool, title:String, subtitle:String?, isLong:Bool = false, info:Any? = nil) {
        blockChanges {
            let action = MNProgressAction(title: title, subtitle: subtitle, info: info, isLongTimeAction: isLong)
            if let discrete = progress.discrete {
                if incrementUnits && discrete.completedUnitsCnt < discrete.totalUnitsCnt {
                    progress.completedUnitsCnt = discrete.completedUnitsCnt + 1
                }
            }
            progress.actionCompleted = action
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

        DispatchQueue.main.asyncAfter(delayFromNow: delay) {[weak self] in
            if let self = self {
                var counter = 0
                self.progress.totalUnitsCnt = UInt64(totalChanges)
                let rnd = TimeInterval.random(in: 0.0..<(interval * 0.5))
                Timer.scheduledTimer(withTimeInterval: interval + rnd, repeats: true) {[weak self] timer in
                    if let self = self {
                        var isStop = false
                        var typeStr = ""
                        if counter < totalChanges {
                            let rand = Int.random(in: 0...24)
                            switch rand {
                            case 0...22:
                                self.progress.completedUnitsCnt = (self.progress.completedUnitsCnt ?? 0) + 1
                                typeStr = "increment"
                            case 23:
                                let prevCnt = self.progress.completedUnitsCnt ?? 0
                                self.newAction(incrementUnits: Bool.random(), title: "timedTest #\(counter) comp", subtitle: Int.random(in: 0...3) == 0 ? "Subtitle is now" : nil)
                                typeStr = "action \(prevCnt != (self.progress.completedUnitsCnt ?? 0) ? "+increment" : "")"
                            case 24:
                                isStop = Int.random(in: 0...100) == 100
                                self.emitError(error: AppError(AppErrorCode.misc_unknown, detail: "TestMNProgressEmitter.timedTest"), isStopsAllProgress: isStop)
                                typeStr = "error"
                            default:
                                break
                            }
                        } else {
                            isStop = true
                        }
                        if isStop || counter >= totalChanges {
                            dlog?.info("TestMNProgressEmitter emitting: [\(typeStr)] Last test")
                            timer.invalidate()
                        } else if let discrete = self.progress.discrete {
                            dlog?.info("TestMNProgressEmitter emitting: [\(typeStr)] test #\(counter) \(discrete.fractionCompletedDisplayString) | \(discrete.progressUnitsDisplayString)")
                        } else if let _ = self.progress.fractionCompleted {
                            dlog?.info("TestMNProgressEmitter emitting: [\(typeStr)] test #\(counter) \(self.progress.fractionCompletedDisplayString.descOrNil)")
                       }
                        counter += 1
                    }
                }
            }
        }
    }
}
