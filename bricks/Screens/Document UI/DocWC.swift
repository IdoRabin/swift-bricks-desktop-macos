//
//  DocWC.swift
//  Bricks
//
//  Created by Ido on 16/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocWC")
typealias BrickDocIDsTriplet = (BrickDocUID, /* display name */ String, NSWindow.TabbingIdentifier?)

extension NSViewController : HashableObject {
    
}

@objc extension NSObject : BasicDescable {
    @objc var basicDesc : String {
        return "<\(type(of: self)) \(String(memoryAddressOf: self))>"
    }
}

class DocWC : NSWindowController, WhenLoadedable {
    let DEBUG_DRAWING = Debug.IS_DEBUG && false
        
    let TOOLBAR_MAIN_PANEL_VIEW_MIN_WIDTH_Pixel : CGFloat = 400
    let TOOLBAR_MAIN_PANEL_VIEW_MIN_WIDTH_fraction : CGFloat = 0.2
    @objc let TOOLBAR_MAIN_PANEL_VIEW_PREFERRED_WIDTH_fraction : CGFloat = 0.35
    let TOOLBAR_MAIN_PANEL_VIEW_MAX_WIDTH_fraction : CGFloat = 0.5
    
    let TOOLBAR_MIN_SPACER_WIDTH : CGFloat = 1.0
    let TOOLBAR_HEIGHT : CGFloat = 38.0 // total external height
    let TOOLBAR_ITEMS_HEIGHT : CGFloat = 32
    
    private(set) var loadingHelper = LoadingHelper(label: "DocWC")
    internal var _tabObservation: NSKeyValueObservation? = nil
    internal var _selectedTabObservation: NSKeyValueObservation? = nil
    
    private(set) var _lastMainPanelScreenW : CGFloat = 0.0
    private var _lastToolbarVisible : Bool = true {
        didSet {
            if _lastToolbarVisible != oldValue {
                // dlog?.info("_lastToolbarVisible changed \(self._lastToolbarVisible)")
                if let menu = self.mainMenu,  BrickDocController.shared.curDocWC == self {
                    menu.updateMenuItems([menu.viewShowToolbarMnuItem], context: "lastToolbarVisible")
                }
            }
        }
    }
    
    // MARK: TabGroups (see extension)
    static var appTabGroups : [NSWindow.TabbingIdentifier:[BrickDocUID : String]] = [:]
    static var appTabGroupSelections : [NSWindow.TabbingIdentifier:(BrickDocUID , String)] = [:]
    private var subVCs:[String:WeakWrapperHashable<NSViewController>] = [:]
    
    func registerSubVC(_ vc:NSViewController?) {
        guard let vc = vc, self.contentViewController != nil else {
            return
        }
        subVCs[type(of: vc).description()] = WeakWrapperHashable(value: vc)
    }
    
    func getSubVC<T:NSViewController>(ofType:T.Type)->T? {
        guard self.contentViewController != nil else {
            return nil
        }
        return subVCs[ofType.description()]?.value as? T
    }
    
    var docVC : DocVC? {
        return self.contentViewController as? DocVC
    }
    
    var brickDoc : BrickDoc? {
        return self.document as? BrickDoc
    }
    
    var isCurentDocWC : Bool {
        return BrickDocController.shared.curDocWC == self
    }
    
    var docNameOrNil : String {
        return self.document?.displayName ?? "<nil>"
    }
    
    fileprivate func perpareToolbarForLoad(depth:Int = 0) {
        guard depth < 20 else {
            return
        }
        
        guard self.windowIfLoaded != nil else {
            DispatchQueue.main.asyncAfter(delayFromNow: 0.02) {
                self.perpareToolbarForLoad(depth: depth + 1)
            }
            return
        }
        
        self.windowIfLoaded?.toolbar?.items.forEachIndex({ index, item in
            item.tag = index
            if self.DEBUG_DRAWING, let view = item.view {
                view.layer?.debugBorder(color: .cyan.withAlphaComponent(0.5), width: 1)
            }
        })
        
        self.updateToolbarAction(state: .inProgress,
                                 title: AppStr.LOADING_DOT_DOT.localized(),
                                 subtitle: AppStr.PLEASE_WAIT_DOT_DOT.localized(),
                                 progress: 0.01)
    }
    
    fileprivate func finalizeToolbarAfterLoad() {
        self.updateToolbarAction(state: .success,
                                 title: AppStr.READY.localized(),
                                 subtitle: "",
                                 progress: 1.0) {
            self.mainPanelBoxView?.clearUnitsTitle(animated:true)
        }
    }
    
    // MARK: Lifecycle
    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowIfLoaded?.delegate = BrickDocController.shared
        BrickDocController.shared.observers.add(observer: self)
        self.updateToolbarVisible()
        
        // dlog?.info("windowDidLoad \(basicDesc) window:\(window?.basicDesc ?? "<nil>" )")
        let loadTime = Date()
        self.setupTabGroupObserving()
        
        self.perpareToolbarForLoad()
        
        self.loadingHelper.startedLoading(waitForCondition: {
            self.document != nil
        }, onMainThread: true, context: "DocWC.waitFordocument", interval: 0.05, timeout: 0.5, userInfo: nil) { info, result in
            DispatchQueue.mainIfNeeded {
                
                switch result {
                case .success:
                    let duration = abs(loadTime.timeIntervalSinceNow)
                    if let doc = self.brickDoc {
                        if doc.isDraft && doc.brick.stats.modificationsCount == 0 && doc.brick.stats.loadsCount == 0 {
                            // Was never changed:
                            dlog?.success("windowDidLoad with empty document: [\(self.docNameOrNil)] time:\( duration.rounded(dec: 2)) sec.")
                        } else {
                            dlog?.success("windowDidLoad with document: [\(self.docNameOrNil)] time:\( duration.rounded(dec: 2)) sec. avg:\( doc.brick.stats.loadsTimings.average.rounded(dec: 2)) sec.")
                        }
                        self.finalizeToolbarAfterLoad()
                    } else {
                        dlog?.warning("windowDidLoad brick doc not created / loaded!")
                    }
                case .failure(let error):
                    dlog?.fail("windowDidLoad has no document after loader timed out. Error:\(error.desc)")
                }
            }
        }
    }
    
    override init(window: NSWindow?) {
        super.init(window: window)
        // loadingHelper.isLoadingNow = true
        // dlog?.info("init \(basicDesc) window:\(window?.basicDesc ?? "<nil>" )")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // loadingHelper.isLoadingNow = true
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
        // loadingHelper.isLoadingNow = true
    }
    
    deinit {
        loadingHelper.callCompletionsAndClear()
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
            self.updateWindowState()
            self.updateToolbarVisible()
        }
    }
}
