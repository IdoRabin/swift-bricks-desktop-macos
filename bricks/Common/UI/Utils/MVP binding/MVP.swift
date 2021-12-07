//
//  Presenter.swift
//  testAbstractUI
//
//  Created by Ido Rabin on 10/01/2021.
//  Copyright © 2018 . All rights reserved.
//

import AppKit


/// MVP View protocol: This should be sub-protocoled to allow Views to talk to Presenters
/// The view should require the implementor to hold a *strong* reference to the presenter
/// The enhanced protocol should be implemented by a NSViewController
protocol View : AnyObject {
    var presenter : Presenter? {get set}
    
    /// Create an instance of the presenter to be retained in the instance of the view
    /// - Returns: the presenter instance or nil
    func bindMVP()->Presenter?
}

extension View {
    func bindMVP()->Presenter? {
        return nil
    }
}
/// MVP View protocol: This should be sub-protocoled to allow Presenters to talk to Views
/// The sub-protocoled should be implemented by a class that does ONLY the Presenter logic behaind a view, and should not be aware, hold reference or manipulate ANY UI component that the viewController may hold. The View should pass only data.
/// The sub-protocol should expose all public calls
protocol Presenter : AnyObject {
    // var view : View {get set}
    
    // Events coming from the View:
    // func viewDidLoad(view:View)
    
    var viewController : NSViewController? {get}
}


/* Template for use:
 
 import Foundation
 import UIKit
 
/// MVP 'Clean code' View
/// Implementors are assumed to be NSViewControllers
protocol MyView : View {
    
    // MARK: MVP presenter pattern:
    /// This View holds a strong reference to the Presenter, so that when it deinits, the Presenter dies as well
    var presenter : MyPresenter? {get set}
    
    // MARK: public
    // The Presenter will call the View via the following functions:
}

/// MVP 'Clean code' Presenter
/// This class should contain the logic for the UI, without touching any UI component except allocating the VC:
class MyPresenter : Presenter {
    
    // MARK: MVP view pattern:
    /// This Presenter holds a weak reference to the View
    weak var view:MyView? = nil
    
    required init(view:MyView) {
        self.view = view
    }
 
    // MARK: public
    // The View will call the Presenter via the following functions:
 
    // Events coming from the View:
    func viewDidLoad(view:MyView) {
 
    }
 }
 */
