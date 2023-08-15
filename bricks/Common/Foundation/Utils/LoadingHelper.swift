//
//  LoadingWaiter.swift
//  zync
//
//  Created by Ido on 27/05/2021.
//  Copyright © 2021. All rights reserved.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("LoadingWaiter")

protocol WhenLoadedable : AnyObject {
    
    var loadingHelper : LoadingHelper {get}
    
    func whenLoaded(_ completion:@escaping AppResultUpdatedBlock)
    
    var isLoaded : Bool {get}
}

extension WhenLoadedable /* Default implementations */ {
    func whenLoaded(_ completion:@escaping AppResultUpdatedBlock)
    {
        self.loadingHelper.whenLoaded(completion)
    }
    
    var isLoaded : Bool {
        return self.loadingHelper.isLoaded
    }
}

protocol WhenLoadedableEx : WhenLoadedable {
    func isNeedsLoading()->Bool
    func load(userInfo:Any?)->AppResultUpdated
}


/// LoadingHelper is class with a set of properties and behaviours meants to assist other classe handle async "load" processes on init / on demand
class LoadingHelper {
    
    private var _label : String = "Unknown"
    private var _loadingLock = NSRecursiveLock()
    private var _isLoadingNow : Bool = false
    private var _isCallingCompletionsAndClearNow : Bool = false
    private var _loadResult : AppResultUpdated? = nil
    private var _loadingCompletions : [AppResultUpdatedBlock]? = []
    private var _didDeinit : Bool = false
    
    func creatingLoadingError()->AppError {
        return AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading in \(self.label))")
    }

    private var logPrefix : String {
        return "|\(self._label)|"
    }
    
    init(label newLabel:String = "Unknown") {
        _label = newLabel
    }

    convenience init(for anyType:AnyClass) {
        self.init(label: "LoadingWaiter of \(anyType)")
    }

    deinit {
        if !self._didDeinit {
            callCompletionsAndClear()
            self._didDeinit = true
        }
         dlog?.info("\(logPrefix) deinit")
    }
    
    var isLoadingNow : Bool {
        get {
            var result = false
            self._loadingLock.lock {
                result = _isLoadingNow
            }
            return result
        }
    }
    
    var isLoaded : Bool {
        get {
            var result = false
            self._loadingLock.lock {
                if !isLoadingNow, let res = _loadResult {
                    switch res {
                    case .success:
                        result = true
                    default:
                        result = false
                    }
                }
            }
            return result
        }
    }
    
    var label : String {
        var result : String = ""
        _loadingLock.lock {
            result = _label
        }
        return result
    }
    
    func callCompletionsAndClear() {
        
        guard _isCallingCompletionsAndClearNow == false else {
            return
        }
        _isCallingCompletionsAndClearNow = true
        
        // Save info
        let lock = self._loadingLock // will be retined for the main queue if needed:
        let loadResult = _loadResult ?? .success(.noChanges)
        let comps = self._loadingCompletions ?? []
        
        // Call completions
        DispatchQueue.mainIfNeededSync { [self, lock, loadResult, comps] in
            lock.lock {
                for completion in comps {
                    completion(loadResult)
                }
                
                // Done
                self._loadingCompletions?.removeAll()
                self._loadingCompletions = nil
            }
            
            _isCallingCompletionsAndClearNow = false
        }
        // dlog?.info("\(logPrefix) callCompletionsAndClear DONE \(lock)")
    }
    
    func startLoadingIfNeeded(loadableEx:WhenLoadedableEx, onGlobalQueue : Bool = true, userInfo:Any? = nil) {
        self.startLoadingIfNeeded(loadableEx.isNeedsLoading,
                                  onGlobalQueue: onGlobalQueue,
                                  userInfo: userInfo,
                                  load: loadableEx.load)
    }
    
    func startLoadingIfNeeded(_ isNeedsLoading:()->Bool, onGlobalQueue : Bool = true, userInfo: Any?, load:@escaping (_ userInfo: Any?)->AppResultUpdated) {
        if isNeedsLoading() {
            self._loadingLock.lock {
                self._isLoadingNow = false
                
                if onGlobalQueue {
                    DispatchQueue.notMainIfNeeded {
                        let result = load(userInfo)
                        self._loadingLock.lock {
                            self._loadResult = result
                        }
                        self.callCompletionsAndClear()
                    }
                } else {
                    let result = load(userInfo)
                    self._loadingLock.lock {
                        self._loadResult = result
                    }
                    self.callCompletionsAndClear()
                }
            }
        } else {
            self._loadingLock.lock {
                self._isLoadingNow = false
                self._loadResult = .success(.noChanges)
            }
            self.callCompletionsAndClear()
        }
    }
    
    func whenLoaded(_ completion:@escaping AppResultUpdatedBlock) {
        self._loadingLock.lock {
            if let existingLoadResult/* is already loaded*/ = _loadResult {
                completion(existingLoadResult)
            } else {
                self._loadingCompletions?.append(completion)
            }
        }
    }
    
    
    /// Starts the loading process, accepting that the load proccess occurs externally, and completes the load when the test condition is true
    func startedLoading(waitForCondition test:@escaping ()->Bool, onMainThread:Bool = true, context:String, interval:TimeInterval = 0.02, timeout:TimeInterval = 1.0,
                        userInfo: Any?,
                        completed:@escaping (_ info : Any?, _ result:AppResultUpdated)->Void) {
        func finalize(waitResult:WaitResult) {
            var result : AppResultUpdated = .success(.noChanges)
            switch waitResult {
            case .success:
                result = .success(.newData)
            case .timeout:
                result = .failure(AppError(AppErrorCode.misc_failed_loading, detail: "LoadingHelper.startedLoading:waitForCondition failed on timeout after \(timeout) sec. label: .\(_label)"))
            }
            self._loadResult = result
            completed(userInfo, result)
            self.callCompletionsAndClear()
        }
        
        if onMainThread {
            waitFor(context, interval: interval, timeout: timeout, testOnMainThread: test, completion: { waitResult in
                DispatchQueue.mainIfNeeded {
                    finalize(waitResult: waitResult)
                }
            }, logType: .allAfterFirstTest)
        } else {
            waitFor(context, interval: interval, timeout: timeout, test: test, completion: { waitResult in
                finalize(waitResult: waitResult)
            }, logType: .allAfterFirstTest)
        }
    }
}
