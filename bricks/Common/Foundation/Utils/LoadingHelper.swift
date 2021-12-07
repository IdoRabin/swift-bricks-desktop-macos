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
    private var _loadResult : AppResultUpdated? = nil
    private var _loadingCompletions : [AppResultUpdatedBlock]? = []

    func creatingLoadingError()->AppError {
        return AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading in \(self.label))")
    }
    
    init(label newLabel:String = "Unknown") {
        _label = newLabel
    }

    convenience init(for anyType:AnyClass) {
        self.init(label: "LoadingWaiter of \(anyType)")
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
    
    private func callCompletionsAndClear() {
        // Call completions
        DispatchQueue.mainIfNeeded {
            self._loadingLock.lock {
                for completion in self._loadingCompletions ?? [] {
                    completion(self._loadResult!)
                }
                
                // Done
                self._loadingCompletions?.removeAll()
                self._loadingCompletions = nil
            }
        }
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
}
