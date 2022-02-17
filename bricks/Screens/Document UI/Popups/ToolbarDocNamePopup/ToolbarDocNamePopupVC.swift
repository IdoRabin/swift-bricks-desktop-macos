//
//  ToolbarDocNamePopupVC.swift
//  Bricks
//
//  Created by Ido on 13/01/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("ToolbarDocNamePopupVC")

class ToolbarDocNamePopupVC: NSViewController {

    var docVC : DocVC? {
        return self.presentingViewController as? DocVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog?.info("init \(self.basicDesc)")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let presentingVC = self.presentingViewController {
            DispatchQueue.main.performOncePerInstance(self) {
                let maxHgt = max(presentingVC.view.bounds.height - self.view.frame.origin.y - 100, 60)
                self.view.heightAnchor.constraint(lessThanOrEqualToConstant: maxHgt).isActive = true
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        let wc = docVC?.docWC
        DispatchQueue.main.asyncAfter(delayFromNow: 0.2) {
            wc?.updateToolbarDocNameView()
        }
    }
    
    deinit {
        AppSettings.shared.saveIfNeeded()
        dlog?.info("deinit \(self.basicDesc)")
    }
    
}
