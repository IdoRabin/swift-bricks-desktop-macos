//
//  AppAlert.swift
//  Bricks
//
//  Created by Ido on 29/04/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("AppAlert")

typealias AlertEmptyCompletion = ()->Void
typealias AlertCompletion = (_ title:String)->Void

/// Wrapper class for all dialogs and alerts presented in the app
final class AppAlert {
    private static var _presentedCountLock = NSRecursiveLock()
    private static var _presentedCount : Int = 0
    static var presentedCount : Int {
        get {
            var result : Int = 0
            self._presentedCountLock.lock {
                result = self._presentedCount
            }
            return result
        }
    }
    
    
    static var observers = ObserversArray<AppAlertsObserver>()
    
    // Allows external multiple observers without using KVO.
    static var presentedCountBox = Box<Int>(0)
    
    // static let alert = AppAlertAlert()
    static let macOSDialog = AppAlertMacOSDialog()
    
    static func addToPresentedCount(amount:Int, instance:Any?, context:String) {
        var ptrStr = "Unknown.\(Date().timeIntervalSince1970)"
        if let instz = (instance as? AnyObject) { // NOTE: Ingore warning
            ptrStr = String(memoryAddressOf: instz)
        }
        
        // Prevent duplicate additions or subtractions for the same intance (caused by multiple calls to dismissed? didDismiss etc.)
        TimedEventFilter.shared.filterEvent(key: "AppAlert.addToPresentedCount.\(amount).\(ptrStr)", threshold: 0.05) {
            DispatchQueue.mainIfNeeded {
                self._presentedCountLock.lock {
                    let newValue = self._presentedCount + amount
                    if IS_DEBUG && newValue < 0 {
                        dlog?.warning("newValue < 0! context:\(context)")
                        // assert(false, "AppAlert.presentedCount is set to become negative! context:\(context)") // we catch the reason for this unexpected behavior
                    }
                    self._presentedCount = max(newValue, 0) // we make sure the member is in the expected range in any case
                    self.presentedCountBox.value = self._presentedCount
                }
            }
        }
    }
    
    static func removeFromPresentedCount(amount:Int, instance:Any?, context:String) {
        self.addToPresentedCount(amount: -amount, instance: instance, context:context)
    }
    
    static func getTopViewControllerForAlert()->NSViewController? {
        return BrickDocController.shared.curDocWC?.contentViewController
    }
    
    static func markWillPresentAndNotify(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool) {
        observers.enumerateOnMainThread { observer in
            observer.appAlertWillAppear(in: vc, presenter: presenter, instance: instance, animated: animated)
        }
    }
    
    static func markAsPresentedAndNotify(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool) {
        AppAlert._presentedCountLock.lock {
            AppAlert.addToPresentedCount(amount: 1, instance: sender, context: "AppAlet.markAsPresentedAndNotify")
            dlog?.info("presented \(sender) total:\(AppAlert._presentedCount)")
        }
        
        observers.enumerateOnMainThread { observer in
            observer.appAlertDidAppear(in: vc, presenter: presenter, instance: instance, animated: animated)
        }
    }
    
    static func markWillDismissAndNotify(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool) {
        observers.enumerateOnMainThread { observer in
            observer.appAlertWillDisppear(revealing: vc, presenter: presenter, instance: instance, animated: animated)
        }
    }
    
    static func markAsDismissedAndNotify(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool) {
        AppAlert._presentedCountLock.lock {
            AppAlert.removeFromPresentedCount(amount: 1, instance: sender, context: "AppAlet.markAsDismissedAndNotify")
            if (AppAlert._presentedCount < 0) {
                dlog?.warning("dismissed \(sender) total:\(AppAlert._presentedCount) total number should not be < 0!")
            } else {
                dlog?.info("dismissed \(sender) total:\(AppAlert._presentedCount)")
            }
        }
        
        observers.enumerateOnMainThread { observer in
            observer.appAlertDidDisppear(revealing: vc, presenter: presenter, instance: instance, animated: animated)
        }
    }
    
    static func waitForAndMarkAsDismissed(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool) {
        guard let instance = instance as? NSViewController else {
            dlog?.warning("waitForAndMarkAsDismissed cannot wait for an unknown instance type")
            self.markAsDismissedAndNotify(sender: sender, in: vc, presenter: presenter, instance: instance, animated: animated)
            return
        }
        
        func test()->Bool {
            instance.view.window == nil && instance.presentingViewController == nil && instance.parent == nil
        }
        
        guard test() == false else {
            dlog?.warning("waitForAndMarkAsDismissed instance seems to already be dismissed! \(instance)")
            self.markAsDismissedAndNotify(sender: sender, in: vc, presenter: presenter, instance: instance, animated: animated)
            return
        }
        
        waitFor("alert instance to dismiss", interval: 0.1, timeout: 0.55, testOnMainThread: {
            return test()
        }, completion: { waitResult in
            self.markAsDismissedAndNotify(sender: sender, in: vc, presenter: presenter, instance: instance, animated: animated)
        }, counter: 0)
        
    }
}

// Wrapper exposing AppAlert to ObjC
/*
@objc final class AppAlertObjCBridge : NSObject {
    @objc class func presentErrorAlert(title:String,
                                        message:String,
                                        error:NSError,
                                        hostVC:UIViewController?,
                                        actionTitle:String,
                                        completion:@escaping ()->Void) {
        // Wrapped call:
        AppAlert.alert.presentForError(error,
                                       title: title,
                                       message: message,
                                       hostVC: hostVC,
                                       buttonTitle: actionTitle,
                                       presentationComplete: nil,
                                       completion: completion)
    }
}
*/
