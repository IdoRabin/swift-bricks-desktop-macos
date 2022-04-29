//
//  DocSubVC.swift
//  Bricks
//
//  Created by Ido on 10/04/2022.
//

import AppKit

// All ViewControllers that are "sub" view controllers of the DocWindow / Doc View controller - i.e their views are embedded as subviews in the window's view hierarchy.

protocol DocSubVC : NSViewController {
    var doc : BrickDoc? { get }
    var docWC : DocWC? { get }
    func registerToDocWC()
}

extension DocSubVC /* Default implementations */ {
    
    var doc : BrickDoc? {
        return docWC?.document as? BrickDoc
    }
    
    var docWC : DocWC? {
        return (self.view.window?.windowController as? DocWC)
    }
    
    
    /// Registers all sub-viewcontrollers to a registry of VC's by type (WeakWrapped) - this allows direct access to the VC's from the Document window / view controller level, without incurring retention cycles.
    func registerToDocWC() {
        waitFor("\(type(of: self)).registerToDocWC", interval: 0.05, timeout: 0.2, testOnMainThread: {
            self.docWC != nil
        }, completion: { waitResult in
            DispatchQueue.mainIfNeeded {
                if waitResult.isSuccess {
                    self.docWC?.registerSubVC(self)
                }
            }
        }, logType: .onlyOnTimeout)
    }
}
