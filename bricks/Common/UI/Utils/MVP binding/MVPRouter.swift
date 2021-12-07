//  MVPRouter.swift
//  
//
//  Created by Ido Rabin on 22/05/2021.
//  Copyright © 2018 . All rights reserved.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.ui["MVPRouter"]

typealias RouterPresentationBlock = (_ instance:View, _ presenter:Presenter?)->Void

class RouterConfig {
    
    var isAnimated : Bool
    var isFullscreen : Bool
    var isModal : Bool
    var isDissolve : Bool
    var isAddAppNavBar : Bool
    var isReplaceRootVC : Bool
    
    private var _replacePushed : Bool = false
    var replacePushed : Bool {
        return _replacePushed
    }
    
    init(isAnimated : Bool = true,
        isFullscreen : Bool = false,
        isModal : Bool = true,
        isDissolve : Bool = false,
        isAddAppNavBar : Bool = false,
        isReplaceRootVC: Bool = false) {
        
        self.isAnimated = isAnimated
        self.isFullscreen = isFullscreen
        self.isModal = isModal
        self.isDissolve = isDissolve
        self.isAddAppNavBar = isAddAppNavBar
        self.isReplaceRootVC = isReplaceRootVC

        self._replacePushed = false
        if isDissolve {
            if isModal == false {
                self._replacePushed = true
            }
            self.isModal = true
        }
    }
    
    
    static var `default` : RouterConfig {
        return RouterConfig(isAnimated: true,
                            isFullscreen: false,
                            isModal: true,
                            isDissolve: false,
                            isAddAppNavBar: false,
                            isReplaceRootVC: false)
    }
}

// Route between presenters
// This is effectively a factory that instaniates the actual view instance for each presenter type
protocol Router {
    
    func route(from: Presenter, to: Presenter.Type, config: RouterConfig?, userInfo: Any?, setup:RouterPresentationBlock?, presented:RouterPresentationBlock?)
}

// Wrapper allowing all routing between presenters to be changed/diverted to a new routing "method"
class MVPRouter : Router {
    
    
    
    // MARK: Singleton
    /// Singleton instance of the SAManager
    static let shared = MVPRouter()
    
    // MARK: Memebrs:
    
    // The actual router - this way we can plug in here other router implementors, (not neccasarily dependant on view controllers)
    private let router : Router = StoryboardMacOSRouter()
    
    func route(from: Presenter, to: Presenter.Type, config: RouterConfig?, userInfo: Any?, setup:RouterPresentationBlock?, presented:RouterPresentationBlock?) {
        DispatchQueue.mainIfNeeded {
            self.router.route(from: from, to: to, config: config, userInfo: userInfo, setup:setup, presented: presented)
        }
    }
}

typealias MVRoutingTriplet = (vc:NSViewController.Type, view:Any, presenter:Presenter.Type)

// StoryboardRouter is a factory / router that instantiates and pushed ViewControllers
fileprivate class StoryboardMacOSRouter : Router {
    
    
    private func transitionRootVC(window:NSWindow?, to vc:NSViewController, completion:(()->Void)? = nil) {
//        if let window = window {
//            let prev = window.rootViewController
//
//            dlog?.info("transitionRootVC from: \(prev.self?.description ?? "<nil>" ) to:\(vc.self)")
//            vc.view.frame = prev?.view.frame ?? UIScreen.main.bounds
//            vc.view.layoutIfNeeded()
//            vc.view.updateConstraintsIfNeeded()
//
//
//            // A mask of options indicating how you want to perform the animations.
//            let options: UIView.AnimationOptions = .transitionCrossDissolve
//
//            // Set the new rootViewController of the window.
//            // Calling "UIView.transition" below will animate the swap.
//            window.rootViewController = vc
//
//            // The duration of the transition animation, measured in seconds.
//            let duration: TimeInterval = 0.24
//
//            // Creates a transition animation.
//            // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
//            UIView.transition(with: window, duration: duration, options: options, animations: {}, completion:
//            { completed in
//                // completion here
//                prev?.navigationController?.popToRootViewController(animated: false)
//                completion?()
//            })
//        } else {
//            dlog?.note("window was not found!!")
//        }
    }
    
    
    func route(from: Presenter, to: Presenter.Type, config: RouterConfig?, userInfo: Any?, setup:RouterPresentationBlock?, presented:RouterPresentationBlock?) {
        var result : View? = nil
        
        let fromStr = String(describing: type(of: from))
        let toStr =  String(describing: to)
        
        let conf = config ?? RouterConfig.default

        var fromVC : NSViewController? = from.viewController
        var toVC : NSViewController? = nil
        var presenter : Presenter? = nil
        
        // A big switch case to route all presentors into all other presentors:
        func loadVC<T:NSViewController>()->T? {
            
            // Attempt load from xib file:
            var vc = T.safeLoadFromNib()
            
            
            // Attempt load from srotyboard (if failed) with identifier "\(T.self)ID"
//            if vc == nil { vc = AppStoryboard.main.instantiate(id: "\(T.self)ID") as? T }
//            if vc == nil {
//                dlog?.note("Failed loading ViewController for \(T.self) from xib and from stroyboard with id:\(T.self)ID")
//            }
            return vc
        }
        
        // MARK: Registration
        switch (from, toStr) {
//        case (is RootPresenter, String(describing: RegisterPresenter.self)):
//            fromVC = (from as! RootPresenter).view as? NSViewController
//            if let vc : RegisterVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//
//        case (is RegisterPresenter, String(describing: WelcomePresenter.self)):
//            fromVC = (from as! RegisterPresenter).view as? NSViewController
//            if let vc : WelcomeVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//
//        case (is RegisterPresenter, String(describing: PermissionsPresenter.self)):
//            fromVC = (from as! RegisterPresenter).view as? NSViewController
//            if let vc : PermissionsVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//        case (_, String(describing: PermissionsPresenter.self)):
//            // From Any VC!
//            if let vc : PermissionsVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//
//        case (is RegisterPresenter, String(describing: RegisterPhonePresenter.self)):
//            fromVC = (from as! RegisterPresenter).view as? NSViewController
//            if let vc : RegisterPhoneVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//
//        case (is RegisterPresenter, String(describing: RegisterValidationPresenter.self)):
//            fromVC = (from as! RegisterPresenter).view as? NSViewController
//            if let vc : RegisterValidationVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//
//        // Transition from registration to main root regular view:
//        case (is RegisterPresenter, String(describing: MainRootPresenter.self)):
//            fromVC = (from as! RegisterPresenter).view as? NSViewController
//            if let vc : MainRootTabBarVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//
//        // Transition from init to main root regular view:
//        case (is RootPresenter, String(describing: MainRootPresenter.self)):
//            fromVC = (from as! RootPresenter).view as? NSViewController
//            if let vc : MainRootTabBarVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//
//        // User got kicked out: (from main root to regitration:)
//        case (is MainRootPresenter, String(describing: RegisterPresenter.self)):
//            fromVC = (from as! MainRootPresenter).view as? NSViewController
//            if let vc : RegisterVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//
//        // Caller id found a result contact
//        case (is SearchPresenter, String(describing: ContactDetailPresenter.self)):
//            fromVC = (from as! SearchPresenter).view as? NSViewController
//            if let vc : ContactDetailVC = loadVC() {
//                toVC = vc; presenter = vc.presenter
//            }
//
            /*
 
        case (is SUWelcomePresenter, String(describing: SUContactsPermissionPresenter.self)):
            fromVC = (from as! SUWelcomePresenter).view as? NSViewController
            if fromVC != nil, let vc = AppStoryboard.regsitration.instantiate(id: "SUContactsPermissionViewControllerID") as? SUContactsPermissionViewController {
                // Setup goes here
                toVC = vc
            }

             ...

        // MARK: SideMenu
        case (is MNSideMenuPresenter, String(describing: MNContactInfoPresenter.self)):
            fromVC = (from as! MNSideMenuPresenter).view as? NSViewController
            if fromVC != nil, let vc = AppStoryboard.main.instantiate(id: "MNContactInfoViewControllerID") as? MNContactInfoViewController {
                // Setup goes here
                vc.hidesBottomBarWhenPushed = true
                toVC = vc
            }*/

            
        default:
            dlog?.warning("StoryboardRouter no implementation for routing from: \(fromStr) to: \(toStr)")
        }
        
        if let fromVC = fromVC, var toVC = toVC {
            
//            if conf.isAddAppNavBar && (toVC is NSNavigationController) == false {
//                dlog?.info("Adding an app nav bar toVC:\(toVC)")
//                result = toVC as? View
//                toVC = createAppNavBar(for: toVC)
//            }
//
//            if toVC is View {
//                result = toVC as? View  // Assuming all to view controllers conform to View protocol
//            } else if let nav = toVC as? UINavigationController {
//                if nav.viewControllers.first is View {
//                    result = nav.viewControllers.first as? View
//                }
//            }
//
//            // iOS 13 override card presentation
//            if conf.isFullscreen {
//                toVC.modalPresentationStyle = .fullScreen
//            }
//
//            // Setup before presentation:
//            if result != nil {
//                setup?(result!, presenter)
//            }
//
//            // Will replace toVC which was modally presented with a dissolve transition to a "pushed" vc with a "back" navigation bar, when the user set "push" and "dissolve" in the context
//            func replaceIfNeeded(completion:@escaping ()->Void) {
//                if conf.replacePushed {
//                    if let navigationConroller = fromVC.navigationController {
//                        toVC.dismiss(animated: false) {
//                            navigationConroller.pushViewController(toVC, animated: false)
//
//                            // Fade navigation bar from 0.0 to the alpha set in loadview / etc.. this will show the nav bar appearing in aa fade and not abruptly as in a regular push without animation.
//                            let prevNavBarAlpha = navigationConroller.navigationBar.alpha
//                            navigationConroller.navigationBar.alpha = 0.0
//                            if prevNavBarAlpha != 0.0 {
//                                UIView.animate(withDuration: 0.17, animations: {
//                                    navigationConroller.navigationBar.alpha = prevNavBarAlpha
//                                })
//                            }
//                            DispatchQueue.main.async {
//                                completion()
//                            }
//                        }
//                    } else {
//                        completion()
//                    }
//                } else {
//                    completion()
//                }
//            }
//
//            if conf.isDissolve {
//                toVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext;
//                toVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
//            }
//
//            // Presentation
//            if conf.isReplaceRootVC {
//
//                // Replace the window's root controller
//                var window = fromVC.view.window
//                if window == nil, let nav = fromVC.navigationController {
//                    window = nav.view.window
//                }
//                if window == nil, let pres = fromVC.presentingViewController {
//                    window = pres.view.window
//                }
//
//                self.transitionRootVC(window: window, to: toVC)
//
//                presented?(result!, presenter)// Assuming all to view controllers conform to View protocol
//
//            } else if conf.isModal {
//
//                // Present modally
//                fromVC.present(toVC, animated: conf.isAnimated) {
//                        replaceIfNeeded {
//                        presented?(result!, presenter)// Assuming all to view controllers conform to View protocol
//                    }
//                }
//            } else {
//
//                // Present as push in navigationController, or modally if nav controller could not be found
//                if let navigationConroller = fromVC.navigationController {
//
//                    let duration : TimeInterval = 0.25
//
//                    navigationConroller.pushViewController(toVC, animated: conf.isAnimated)
//
//                    if let presented = presented {
//                        DispatchQueue.main.asyncAfter(delayFromNow: duration) {
//                            replaceIfNeeded {
//                                presented(result!, presenter)// Assuming all to view controllers conform to View protocol
//                            }
//                        }
//                    }
//                } else {
//                    dlog?.warning("StoryboardRouter had param \'modally\" as false, but found no navigation controller to push. Using modal presentation. from:\(fromStr) to:\(toStr)")
//
//                    fromVC.present(toVC, animated: conf.isAnimated) {
//                        replaceIfNeeded {
//                            presented?(result!, presenter)// Assuming all to view controllers conform to View protocol
//                        }
//                    }
//                }
//            }
//
        }
    }
}
