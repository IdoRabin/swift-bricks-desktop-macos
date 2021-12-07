//
//  UIMVPSegue.swift
//  
//
//  Created by Ido Rabin on 11/01/2019.
//  Copyright © 2018 . All rights reserved.
//

import Foundation
import AppKit

extension Mirror {
    static func reflectProperties<T>(
        of target: Any,
        matchingType type: T.Type = T.self,
        using closure: (T) -> Void
    ) {
        let mirror = Mirror(reflecting: target)

        for child in mirror.children {
            (child.value as? T).map(closure)
        }
    }
}

@objc protocol MVPBindable : class {
    func isMVPBindable()->Bool
    func mvpBindableSetup()
}

extension MVPBindable {
    func isMVPBindable()->Bool{
        return true
    }
    
    func mvpBindableSetup() {
        dlog?.info("\(type(of: self)) requires implementing mvpBindableSetup on init")
    }
}

fileprivate let dlog : DSLogger? = DLog.ui["MVP"]
//typealias MVPindingTriple = (vc:UIViewController.Type, view:Any, presenter:Presenter.Type)

/// The class is a "factory" of mvp bindings betweeen UIViewControllers, Views and Presenters
/// For more info, see MVP.swift
class MVPVCBinder /*routing*/ {
    
    /// The class will initialize and bind a designated presenter to a newly allowcated viewController that implements a custom View protocol, and can act as a Presenter / View pair.
    ///
    /// - Parameter viewController: view controller to bind, must conform to Presenter and have a View sub-protocol defiend for it
    static func bindOnInitIfPossible(viewController:UIViewController) {
        
        // Hard coded list of corresponding vcs, Views and Presenters
        if let bindableVC = viewController as? MVPBindable, let viewVC = viewController as? View, bindableVC.isMVPBindable() {
            
            guard let _ = viewController as? View else {
                dlog?.info("MVP binding prevented: \(viewController) is not an implementor of protocol View")
                return
            }
           
            let boundPresenter : Presenter? = viewVC.bindMVP()
            if boundPresenter == nil {
                
                // Hard coded bindings:
                switch viewController {
                    
                    /*
                case let vc as MNCaptureVC:
                    vc.presenter = MNCapturePresenter.init(view: vc as MNCaptureView)
                    boundPresenter = vc.presenter
                */
                
                default:
                    break
                }
            }
            
            if let boundPresenter = boundPresenter {
                dlog?.success("did bind \(type(of: viewController)) with \(boundPresenter)")
            } else {
                dlog?.fail("failed to bind \(type(of: viewController)) with a Presenter")
            }
            
        } else if let bindableVC = viewController as? MVPBindable, bindableVC.isMVPBindable() == false {
            dlog?.fail("Class \(type(of: viewController)) is not MVP bindable")
        }
    }
    
    static func loadVCForId(storyboard:AppStoryboard, id:String)->UIViewController? {
        return storyboard.instantiate(id: id)
    }
}
