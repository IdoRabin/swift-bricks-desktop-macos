//
//  OnboardingVC.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import Cocoa


fileprivate let dlog : DSLogger? = DLog.forClass("OnboardingVC")

class OnboardingVC: NSPageController {
 
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog?.info("viewDidLoad")
    }
    
    deinit {
        dlog?.info("deinit \(self.basicDesc)")
    }
}
