//
//  AppAlertPresenter.swift
//  Bricks
//
//  Created by Ido on 29/04/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("AppAlertPresenter")

protocol AppAlertPresenter {
    
    func markWillPresent(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool)
    func markAsPresented(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool)
    func markWillDismiss(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool)
    func markAsDismissed(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool)
    
    func present(title:String, message:String?, titles:[String], hostVC:NSViewController?, presentationComplete:AlertEmptyCompletion?, completion:AlertCompletion?)
    
    func presentYesNo(title:String, message:String?, yesNoStyle:AppAlertBtnsStyle, hostVC:NSViewController?, presentationComplete:(()->Void)?, completion:((_ result: Bool)->Void)?)
    
    func presentYesNo(title:String, message:String?, yesTitle:String, noTitle:String, hostVC:NSViewController?,  presentationComplete:(()->Void)?, completion:((_ result: Bool)->Void)?)
    
    func presentOK(title:String, message:String?, okTitle:String, hostVC:NSViewController?, presentationComplete:(()->Void)?, completion:AlertEmptyCompletion?)
    
    func presentDestructOrCancel(title:String, message:String?, destructTitle:String, cancelTitle:String, hostVC:NSViewController?,  presentationComplete:(()->Void)?, completion:((_ result: Bool)->Void)?)
}

extension AppAlertPresenter /*default implementations */ {
    
    func presentOK(title:String, message:String?, okTitle:String, hostVC:NSViewController? = nil, presentationComplete:(()->Void)? = nil, completion:AlertEmptyCompletion? = nil) {
        
        self.present(title: title, message: message, titles: [okTitle], hostVC: hostVC, presentationComplete: presentationComplete, completion: {(index) in
            completion?()
        })
    }
    
    func presentYesNo(title:String, message:String?, yesTitle:String, noTitle:String, hostVC:NSViewController? = nil,  presentationComplete:(()->Void)? = nil, completion:((_ result: Bool)->Void)? = nil) {
        self.present(title: title, message: message, titles: [yesTitle, noTitle], hostVC: hostVC, presentationComplete: presentationComplete, completion: {(title) in
            completion?(title == yesTitle)
        })
    }
    
    func presentYesNo(title:String, message:String?, yesNoStyle:AppAlertBtnsStyle, hostVC:NSViewController?, presentationComplete:(()->Void)? = nil, completion:((_ result: Bool)->Void)? = nil) {
        self.presentYesNo(title: title, message: message, yesTitle: yesNoStyle.buttonTitles.yes, noTitle: yesNoStyle.buttonTitles.no, hostVC:hostVC, presentationComplete:presentationComplete, completion:completion)
    }
    
    func presentDestructOrCancel(title:String, message:String?, destructTitle:String, cancelTitle:String, hostVC:NSViewController? = nil,  presentationComplete:(()->Void)? = nil, completion:((_ result: Bool)->Void)? = nil) {
        self.present(title: title, message: message, titles: [destructTitle, cancelTitle], hostVC: hostVC, presentationComplete: presentationComplete, completion: {(title) in
            completion?(title == destructTitle)
        })
    }
    
    func markWillPresent(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool) {
        // default implementation
        AppAlert.markWillPresentAndNotify(sender: sender, in: vc, presenter: presenter, instance: instance, animated: animated)
        
//        if Debug.IS_DEBUG && (vc.presentedViewController is MNAlertViewController ||
//                        vc.presentedViewController is UIAlertController ||
//                        vc is MNAlertViewController ||
//                        vc is UIAlertController) {
//
//            // Warning:
//            dlog?.warning("Will attempt to present \(instance.debugDescription) in \(vc) when it is already presenting:\(vc.presentedViewController?.description ?? vc.description)")
//            dlog?.note("try to catch and prevent this")
//        }
    }
    
    func markAsPresented(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool) {
        // default implementation
        AppAlert.markAsPresentedAndNotify(sender: sender, in: vc, presenter: presenter, instance: instance, animated: animated)
    }
    func markWillDismiss(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool) {
        // default implementation
        AppAlert.markWillDismissAndNotify(sender: sender, in: vc, presenter: presenter, instance: instance, animated: animated)
    }
    func markAsDismissed(sender : Any, in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool) {
        // default implementation
        AppAlert.markAsDismissedAndNotify(sender: sender, in: vc, presenter: presenter, instance: instance, animated: animated)
    }
}
