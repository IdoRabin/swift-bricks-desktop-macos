//
//  DocWC.swift
//  Bricks
//
//  Created by Ido on 16/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocWC")

extension NSObject {
    var basicDesc : String {
        return "<\(type(of: self)) \(String(memoryAddressOf: self))>"
    }
}

class DocWC : NSWindowController {
    
    override init(window: NSWindow?) {
        super.init(window: window)
        dlog?.info("init \(basicDesc) window:\(window?.basicDesc ?? "<nil>" )")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        dlog?.info("init w/ coder \(basicDesc) window:\(window?.basicDesc ?? "<nil>" )")
    }
    
    deinit {
        dlog?.info("deinit \(basicDesc)")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        waitFor("document", interval: 0.05, timeout: 0.2, testOnMainThread: {
            self.document != nil
        }, completion: { waitResult in
            DispatchQueue.mainIfNeeded {
                switch waitResult {
                case .success:
                    dlog?.success("windowDidLoad document:\(self.document.descOrNil) toolbar: \(self.window?.toolbar?.basicDesc ?? "<nil>" ) window: \(self.window?.basicDesc ?? "<nil>" )")
                case .timeout:
                    dlog?.fail("windowDidLoad has no document after loading (waitFor(\"document\") timed out)")
                }
            }
        }, counter: 1)
    }
    
    
}
