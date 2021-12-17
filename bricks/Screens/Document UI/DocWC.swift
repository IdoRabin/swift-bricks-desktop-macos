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
    
    @IBOutlet weak var docToolbar: DocToolbar!

    
    static var current :DocWC? {
        for window in BricksApplication.shared.orderedWindows {
            if let wc = window.windowController as? DocWC {
                return wc
            }
        }
        return nil
    }
    
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
    
    private func setupToolbar() {
        waitFor("toolbar", interval: 0.02, timeout: 0.2, testOnMainThread: {
            return self.docToolbar != nil
        }, completion: {[self] waitResult in
            dlog?.successOrFail(condition: waitResult.isSuccess, items: "setupToolbar toolbar")
            
            // Found toolbar
            if let toolbar = docToolbar {
                toolbar.setup(windowController: self)
            }
        }, counter: 1)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.setupToolbar()
        
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

class DocWindow : NSWindow {
    override func mouseUp(with event: NSEvent) {
        if event.clickCount >= 2 && isPointInTitleBar(point: event.locationInWindow) { // double-click in title bar
            // Double click on title bar
            self.performZoom(nil)
        }
        super.mouseUp(with: event)
    }
    
    fileprivate func isPointInTitleBar(point: CGPoint) -> Bool {
        if let _ = self.contentView?.frame {
            let toolbarHgt = DocToolbar.TOOLBAR_HEIGHT
            let titleBarRect = NSRect(x: self.contentLayoutRect.origin.x,
                                      y: self.contentLayoutRect.origin.y + self.contentLayoutRect.height,
                                      width: self.contentLayoutRect.width,
                                      height: toolbarHgt)
            return titleBarRect.contains(point)
        }
        return false
    }
}
