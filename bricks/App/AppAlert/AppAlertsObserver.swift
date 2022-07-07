//
//  AppAlertsObserver.swift
//  Bricks
//
//  Created by Ido on 29/04/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("AppAlertsObserver")

// Wrapper for all alert types and presentations:
protocol AppAlertsObserver {
    func appAlertWillAppear(in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool)
    func appAlertDidAppear(in vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool)
    func appAlertWillDisppear(revealing vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool)
    func appAlertDidDisppear(revealing vc:NSViewController, presenter:AppAlertPresenter, instance:Any?, animated:Bool)
}
