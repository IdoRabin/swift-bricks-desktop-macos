//
//  DispatchQueueEx.swift
//
//
//  Created by Ido Rabin on 17/05/2021.
//  Copyright © 2021 . All rights reserved.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("DispatchQueueEx")
fileprivate let waitForLog : DSLogger? = DLog.forClass("waitFor")

/// Wait until the test block returns anything but nil, and then call the completion block
/// NOTE: Will take place on main thread only
///
/// - Parameters:
///   - test: test to be taken periodically
///   - completion: completion when test returns non-nil results
///   - interval: interval for testing
enum WaitResult
{
    case success
    case timeout
    
    var isTimeout : Bool {
        return self == .timeout
    }
    
    var isSuccess : Bool {
        return self == .success
    }
}


extension DispatchQueue {
    
    static var currentLabel : String {
        let name = __dispatch_queue_get_label(nil)
        if let str = String(cString: name, encoding: .utf8)
        {
            if (str == "com.apple.main-thread")
            {
                return "mainThread"
            }
            else if (str == "com.apple.root.default-qos")
            {
                return "defaultQueue"
            }
            return str
        }
        
        return "Unknown"
    }
    
    static var isMainQueue : Bool {
        return currentLabel == DispatchQueue.main.label
    }
    
    var isMainQueue : Bool {
        return self.label == DispatchQueue.main.label
    }
    /// Dispatch on main queue if not already on the main queue, in which case we continue blocking
    ///
    /// - Parameter completion: the block to be performed on the main queue
    static func mainIfNeeded(_ completion: @escaping ()->Void) {
        if Thread.current.isMainThread {
            completion()
        } else {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    static func mainIfNeededSync(_ completion: @escaping ()->Void) {
        if Thread.current.isMainThread {
            completion()
        } else {
            DispatchQueue.main.sync {
                completion()
            }
        }
    }
    
    ///
    ///
    /// - Parameter completion:
    
    
    /// Dispatch on global() if we are in main queue, otherwise will dispatch on current thread and queue
    /// - Parameters:
    ///   - prefer: optional. if provided and we are on the mainThread, the completion block will run async on this queue, otherwise, async on DispatchQueue.global()
    ///   - completion: the block to be performed NOT on the main queue
    static func notMainIfNeeded(prefer:DispatchQueue? = nil, _ completion: @escaping ()->Void) {
        if Thread.current.isMainThread == false {
            completion()
        } else {
            (prefer ?? DispatchQueue.global()).async {
                completion()
            }
        }
    }
    
    /// Will perform asynchrnioously on the queue after the given delay
    ///
    /// - Parameters:
    ///   - delayFromNow: delay time interval from now, in seconds (Double/TimeInterval)
    ///   - block: block to perform after the delay on this quque
    public func asyncAfter(delayFromNow: TimeInterval, block: @escaping @convention(block) () -> Swift.Void) {
        if delayFromNow == 0.0 {
            self.async {
                block()
            }
            return
        }
        self.asyncAfter(deadline:  DispatchTime.now() + delayFromNow, execute: block)
    }

    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    private static var _onceTracker : [String] = []
    private static let _onceTrackerLock = NSLock()
    private static var _uniqueCounter : Int64 = 0
    
    @discardableResult
    public func performOnce(uniqueToken: String, block:()->Void)->Bool {
        var contained = false

        DispatchQueue._onceTrackerLock.lock {
            contained = DispatchQueue._onceTracker.contains(uniqueToken)
        }
        if contained {
            // Already executed once
            return false
        }
        
        DispatchQueue._onceTrackerLock.lock {
            DispatchQueue._onceTracker.append(uniqueToken)
        }
        
        if IS_DEBUG {
            DispatchQueue._onceTrackerLock.lock {
                if DispatchQueue._onceTracker.count > 200 {
                    DLog.misc["DispatchQueue"]?.warning("onceTracker tokens count > 200! Should not be used with a often created instances / classes!")
                }
            }
        }
        
        block()
        return true
    }
    
    /// Will perform the call once for this instance from this location in the code
    /// NOTE: The block will be perfoemed once per instance and is to be called from multiple instances for an "init" of some sort
    /// - Parameter block: block to perform if not performed already on this instance
    /// - Returns: true if the block was performed
    @discardableResult
    public func performOncePerInstance(_ instance:AnyObject, block:()->Void)->Bool {
        var token : String = String(memoryAddressOf: instance)
        let symbs = Thread.callStackSymbols
        if symbs.count > 1 {
            // stack trace of the calling function+line - is the "unique token" we need - we assentially don't need to traverse twice in the same line of code that says "performOnce {...}"
            token += "_" + symbs[1].condenseWhitespaces()
        }
        
        return self.performOnce(uniqueToken: token, block: block)
    }
    
    /// Will perform the call once for the whole run of the app - similar to a singleton or a static.
    /// NOTE: This is not to be called from within instances of an object, becasue only the first instance will have perfomed the block
    /// - Parameter block: block to perform if not performed already this session
    /// - Returns: true if the block was performed
    @discardableResult
    public func performOncePerSession(block:()->Void)->Bool {
        
        var token : String = ""
        let symbs = Thread.callStackSymbols
        if symbs.count > 1 {
            // stack trace of the calling function+line - is the "unique token" we need - we assentially don't need to traverse twice in the same line of code that says "performOnce {...}"
            token = symbs[1].condenseWhitespaces()
        } else {
            var count : Int64 = 0
            DispatchQueue._onceTrackerLock.lock {
                DispatchQueue._uniqueCounter += 1
                count = DispatchQueue._uniqueCounter
            }
            token = String(Date().timeIntervalSince1970) + "_\(count)"
        }
        
        return self.performOnce(uniqueToken: token, block: block)
    }
    
    
    /// Will perform the call once for the whole install of the app - from install time to uninstall time.
    /// NOTE: This function is dependent on UserDefaults and persists the called functions that way.
    /// - Parameters:
    ///   - associateWith: type to associate the call with, so that subclasses etc may be diffrentiated in the class. Default nil.
    ///   - token - unique string token to associate with. try to make the string unique by itself or consider it unique when in combination with the associateWith type. Recommended using #function as a token name and associate with the currect instance
    ///   - forAnyQueue: will call this only once regardless of the queue calling this. When false, we can call this block once (per queue x per install). To work correctly, this depends on the queue labels having persistent labels between sessions. Default true
    ///   - legacyKey: key used by previous versions of the app, such that set any object value to the given legacy key in user defaults
    ///   - isDebugIgnore: allows an easy mechanism to ignore the "once" condition and always call the block, from the implementing side. Requires IS_DEBUG global var to be true as well. (&&)  Default false
    ///   - block: block to perform
    /// - Returns: true if the block was performed
    @discardableResult
    public func performOncePerInstall(associateWith:AnyObject? = nil, token atk:String, forAnyQueue:Bool = true, legacyKey:String? = nil, isDebugIgnore:Bool = false, block:()->Void)->Bool {
        
        var token : String = atk
        if !forAnyQueue {
            token = token + "_\(DispatchQueue.currentLabel)" // current dispatch queue label, to diffrentiate
        }

        if let associateWith = associateWith {
            token = "\(type(of: associateWith))_\(token)"
        }
        if token.count > 0 {
            let xtoken = "perform_once_" + token
            if let legacyKey = legacyKey {
                if UserDefaults.standard.object(forKey: legacyKey) != nil {
                    // Save new key
                    UserDefaults.standard.setValue(true, forKeyPath: xtoken)
                }
            }
            if UserDefaults.standard.object(forKey: xtoken) == nil || (isDebugIgnore && IS_DEBUG) {
                UserDefaults.standard.setValue(true, forKeyPath: xtoken)
                dlog?.success("performOncePerInstall performed: \(token)")
                return self.performOnce(uniqueToken: xtoken, block: block)
            } else {
                dlog?.note("PerformOncePerInstall already performed for token: \(token)")
            }
        } else {
            dlog?.warning("Stack is of depth 1! cannot performOncePerInstall!")
        }
        return false
    }
    
    /// Will check if the currently running queue is the self queue (check requires unique queue label), or otherwise, dispatches synchroneously self.sync {...}
    public func safeSync(_ block:@escaping ()->Void) {
        if DispatchQueue.currentLabel == self.label {
            block()
        } else if Thread.current.isMainThread {
            // dlog?.note("safeSync tried to sync the mainThread to another thread! will call it async!")
            block()
            //callers depend on this being Synced.  so we cannot call self.async(execute: block)
        } else {
            // TODO:
            self.sync(execute: block)
        }
    }
    
    /// If we are already on this queue, will run this synchroneously. If we are on another thread, will runc the block on the queu asynchronenously
    public func asyncIfNeeded(_ block:@escaping ()->Void) {
        if DispatchQueue.currentLabel == self.label {
            block()
        } else {
            self.async(execute: block)
        }
    }
    
    internal func waitFor(_ context:String?/*description*/, interval:TimeInterval = 0.1, timeout:TimeInterval = 3.0, blocking : Bool, test: @escaping ()->Bool, completion: @escaping (_ waitResult : WaitResult)->Void, counter:Int = 0) {
        // optimization
        var isShouldBlock = blocking
        if isShouldBlock && (self.isMainQueue || (self == waitForQueue)) {
            dlog?.warning("waitFor with blocking queue: \(self.label) is not supported!! WILL NOT BLOCK!")
            isShouldBlock = false
        }
        
        let logStr = IS_DEBUG ? "{\(context ?? "*" )} #\(counter)" : ""
        // - waitForLog?.info("waitFor \(logStr)")
        
        if (test()) {
            if (counter == 0)
            {
                waitForLog?.info("\(logStr) completed immediately")
            }
            completion(.success)
            return
        }
        // Will wait until we have an instance of the document to observe
        var result : WaitResult = .timeout
        var threadWaitLock : ThreadWaitLock? = nil
        var lockWasCreated = false
        
        // Get // create lock
        if isShouldBlock {
            waitForQueue.sync {
                threadWaitLock = waitLocks[self.label]
                if threadWaitLock == nil {
                    let lock = ThreadWaitLock()
                    waitLocks[self.label] = lock
                    threadWaitLock = lock
                    lockWasCreated = true
                }
            }
        }
        
        waitForQueue.async {
            if test() == false {
                let elapsedTime : TimeInterval = TimeInterval(counter) * interval
                if elapsedTime > timeout {
                    waitForLog?.info("\(logStr) stopping wait (timeout)")
                    if isShouldBlock {
                        result = .timeout
                        threadWaitLock?.signal()
                    } else {
                        completion(.timeout)
                    }
                }
                else
                {
                    waitForQueue.asyncAfter(delayFromNow: interval, block: {
                        waitForLog?.info("\(logStr) elapsed time:\(round(elapsedTime * 1000.0)/1000.0)")
                        waitForQueue.waitFor(context, interval: interval, timeout: timeout, blocking: false, test: test, completion: { (waitResult) in
                            result = waitResult
                            if isShouldBlock {
                                threadWaitLock?.signal()
                            } else {
                                DispatchQueue.main.async {
                                    completion(result)
                                }
                            }
                        }, counter: counter + 1)
                    })
                }
            } else {
                if isShouldBlock {
                    result = .success
                    threadWaitLock?.signal()
                } else {
                    completion(.success)
                }
            }
        }
        
        if isShouldBlock && lockWasCreated {
            threadWaitLock?.waitForSignal()
            completion(result)
        }
    }
}

fileprivate let waitForQueue = DispatchQueue(label: "waitFor")
fileprivate var waitLocks : [String:ThreadWaitLock] = [:]
func waitFor(_ context:String?/*description*/, interval:TimeInterval = 0.1, timeout:TimeInterval = 3.0, test: @escaping ()->Bool, completion: @escaping (_ waitResult : WaitResult)->Void, counter:Int = 0) {
    waitForQueue.waitFor(context, interval: interval, timeout: timeout, blocking: false, test: test, completion: completion, counter: counter)
}

func waitFor(_ context:String?/*description*/, interval:TimeInterval = 0.1, timeout:TimeInterval = 3.0, testOnMainThread: @escaping ()->Bool, completion: @escaping (_ waitResult : WaitResult)->Void, counter:Int = 0) {
    waitForQueue.waitFor(context, interval: interval, timeout: timeout, blocking: false, test: { () -> Bool in
        var result = false
        DispatchQueue.mainIfNeededSync {
            result = testOnMainThread()
        }
        return result
    }, completion: completion, counter: counter)
}
