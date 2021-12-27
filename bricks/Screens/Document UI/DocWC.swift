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
    let DEBUG_DRAWING = IS_DEBUG && false
    let TOOLBAR_MIN_SPACER_WIDTH : CGFloat = 1.0
    let TOOLBAR_ITEMS_HEIGHT : CGFloat = 32
    private var _lastToolbarVisible : Bool = true {
        didSet {
            if _lastToolbarVisible != oldValue {
                // dlog?.info("_lastToolbarVisible changed \(self._lastToolbarVisible)")
                if let menu = self.mainMenu,  BrickDocController.shared.curDocWC == self {
                    menu.updateMenuItems([menu.viewShowToolbarMnuItem], inVC: BrickDocController.shared.curDocVC)
                }
            }
        }
    }
    
    var docNameOrNil : String {
        return self.document?.displayName ?? "<nil>"
    }
    
    fileprivate func finalizeToolbar() {
        self.windowIfLoaded?.toolbar?.items.forEachIndex({ index, item in
            item.tag = index
            if DEBUG_DRAWING, let view = item.view {
                view.layer?.debugBorder(color: .cyan.withAlphaComponent(0.5), width: 1)
            }
        })
    }
    
    // MARK: Lifecycle
    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowIfLoaded?.delegate = BrickDocController.shared
        BrickDocController.shared.observers.add(observer: self)
        self.updateToolbarVisible()
        dlog?.info("windowDidLoad \(basicDesc) window:\(window?.basicDesc ?? "<nil>" )")
        
        waitFor("document", interval: 0.05, timeout: 0.2, testOnMainThread: {
            self.document != nil
        }, completion: { waitResult in
            DispatchQueue.mainIfNeeded {
                self.finalizeToolbar()
                
                switch waitResult {
                case .success:
                    //dlog?.success("windowDidLoad document: [\(self.docNameOrNil)]")
                    break
                case .timeout:
                    dlog?.fail("windowDidLoad has no document after loading (waitFor(\"document\") timed out)")
                }
            }
        }, counter: 1)
    }
    
    override init(window: NSWindow?) {
        super.init(window: window)
        // dlog?.info("init \(basicDesc) window:\(window?.basicDesc ?? "<nil>" )")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // dlog?.info("init w/ coder \(basicDesc) window:\(window?.basicDesc ?? "<nil>" )")
    }
    
    deinit {
        BrickDocController.shared.observers.remove(observer: self)
        dlog?.info("deinit \(basicDesc) \(self.docNameOrNil)")
    }
    
    // MARK: Public update calls
    @objc func didBecomeMain() {
        dlog?.info("didBecomeMain \(self.docNameOrNil)")
    }
    
    @objc func didResignMainKey() {
        dlog?.info("didResignMainKey \(self.docNameOrNil)")
    }
    
    @objc func didBecomeKey() {
        dlog?.info("didBecomeKey \(self.docNameOrNil)")
    }
    
    @objc func didResignKey() {
        dlog?.info("didResignKey \(self.docNameOrNil)")
    }
    
    func updateToolbarVisible() {
        self._lastToolbarVisible = self.windowIfLoaded?.toolbar?.isVisible ?? false
    }
}

extension DocWC : BrickDocControllerObserver {
    
    func docController(didChangeCurWCFrom fromWC: DocWC?, toWC: DocWC?) {
        if fromWC == self || toWC == self {
            // dlog?.info("didChangeCurWCFrom \(fromWC?.docNameOrNil ?? "<nil>" ) to:\(toWC?.docNameOrNil ?? "<nil>")")
            let fromVC = fromWC?.contentViewController as? DocVC
            let toVC = toWC?.contentViewController as? DocVC
            (self.contentViewController as? DocVC)?.docController(didChangeCurVCFrom: fromVC, toVC: toVC)
            self.updateToolbarMainPanelView()
            self.updateToolbarDocNameView()
            self.updateToolbarVisible()
        }
    }
}
