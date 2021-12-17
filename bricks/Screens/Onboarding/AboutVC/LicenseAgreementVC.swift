//
//  LicenseAgreementVC.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("LicenseAgreementVC")

class LicenseAgreementVC: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog?.info("viewDidLoad")
    }
    
    deinit {
        dlog?.info("deinit \(self.basicDesc)")
    }
}
