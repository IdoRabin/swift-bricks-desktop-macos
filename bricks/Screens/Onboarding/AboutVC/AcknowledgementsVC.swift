//
//  AcknowledgementsVC.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("AcknowledgementsVC")

class AcknowledgementsVC: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog?.info("viewDidLoad")
    }
    
    deinit {
        dlog?.info("deinit")
    }
}
