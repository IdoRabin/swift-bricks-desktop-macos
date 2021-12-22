//
//  BrickDocController.swift
//  Bricks
//
//  Created by Ido Rabin on 08/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDocController")
fileprivate let dlogWindows : DSLogger? = nil // DLog.forClass("BrickDocController+W")

// NSWorkspace.shared.hideOtherApplications()

protocol BrickDocControllerObserver {
    func docController(didChangeCurWCFrom fromWC:DocWC?, toWC:DocWC?)
}

class BrickDocController: NSDocumentController {
    let MAX_OPEN_DOCUMENTS_LIMIT = 16
    
    // MARK: Singleton
    override class var shared: BrickDocController {
        return super.shared as! BrickDocController
    }
    
    var isKillingSelfAppWithNoDialogs : Bool = false
    
    // MARK: Properties
    private var _appIsTerminating = false
    var appIsTerminating : Bool {
        return _appIsTerminating
    }
    var observers = ObserversArray<BrickDocControllerObserver>()
    let commandInvoker = QueuedInvoker()
    var menu : MainMenu? {
        return AppDelegate.shared.mainMenu
    }
    
    var curDocWC: DocWC? = nil {
        didSet {
            if curDocWC != oldValue {
                observers.enumerateOnMainThread { observer in
                    observer.docController(didChangeCurWCFrom: oldValue, toWC: self.curDocWC)
                }
            }
        }
    }
    var curDocVC: DocVC? {
        return curDocWC?.contentViewController as? DocVC
    }
    
    var curDoc: BrickDoc? {
        return curDocWC?.document as? BrickDoc
    }
    
    private var _recentDocURL:URL? = nil
    @AppSettable(true,   name:"BrickDocController.lastClosedWasOnSplashScreen") var lastClosedWasOnSplashScreen : Bool {
        didSet {
            if self.lastClosedWasOnSplashScreen != oldValue {
                dlog?.info("lastClosedWasOnSplashScreen: \(self.lastClosedWasOnSplashScreen)")
            }
        }
    }
    
    var brickDocWindows : [NSWindow] {
        return BricksApplication.shared.windows.filter { window in
            return window.contentViewController is DocVC
        }
    }
    
    // MARK: Lifecycle
    override private init() {
        super.init()
        observeWorkspaceNotifications()
        observeAppDelegateNotifications()
        AppDelegate.shared.documentController = self
        dlog?.info("init \(basicDesc)")
        // NSFileCoordinator.addFilePresenter(BrickDoc.self)
    }
    
    required init?(coder: NSCoder) {
        dlog?.info("init coder")
        // listenToWorkspaceNotifications()
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func applicationWillTerminate(_ notif:Notification) {
        self.lastClosedWasOnSplashScreen = (SplashVC.sharedWindowController != nil)
        dlog?.info("applicationWillTerminate lastClosedWasOnSplashScreen: \(self.lastClosedWasOnSplashScreen)")
        _appIsTerminating = true
    }
    
    deinit {
        dlog?.info("deinit \(self.basicDesc)")
    }
    
    func closeSplashWindow(wasLastWindow:Bool) {
        if let wc = SplashVC.sharedWindowController, let window = wc.window {
            dlog?.info("will close the splash window")
            window.fadeHide {
                window.close()
                SplashVC.sharedWindowController = nil // dealloc sharedWindowController
                if !wasLastWindow {
                    self.lastClosedWasOnSplashScreen = false
                    self.menu?.updateWindowsMenuItems()
                }
            }
        }
    }
    
    // MARK: Public
    func updateSplashWindowIfNeeded() {
        guard self.appIsTerminating == false else {
            return
        }
        
        // We show the splahs screen by force
        // let forceShowSplash = self.lastClosedWasOnSplashScreen && (AppSettings.shared.stats.lastLaunchDate.timeIntervalSinceNow < 2.0)
        
        if self.documents.count == 0 { // } || forceShowSplash {
            
            if !isKillingSelfAppWithNoDialogs {
                // Show the splash window
                dlog?.info("will present the splash window")
                self.sendToInvoker(command: CmdSplashWindow(showsRecents: AppDocumentHistory.shared.history.count > 0))
            } else {
                dlog?.note("is killing app with no dialogs!")
            }
        } else {
            // Find and close the splash window
            closeSplashWindow(wasLastWindow: false)
        }
    }
    
    func didLoadViewControllersAfterInit() {
        if let curWC = self.curDocWC, let menu = curWC.mainMenu {
            menu.updateMenuItems([menu.viewShowToolbarMnuItem], inVC: BrickDocController.shared.curDocVC)
        }
    }
    
    // MARK: Overrides
    override func addDocument(_ document: NSDocument) {
        super.addDocument(document)
        self.closeSplashWindow(wasLastWindow:false)
        DispatchQueue.main.asyncAfter(delayFromNow: 0.5) {
            self.updateSplashWindowIfNeeded()
            self.menu?.updateWindowsMenuItems()
        }
    }

    override func removeDocument(_ document: NSDocument) {
        super.removeDocument(document)
        self.updateSplashWindowIfNeeded()
        self.menu?.updateWindowsMenuItems()
    }
    
    override func openUntitledDocumentAndDisplay(_ displayDocument: Bool) throws -> NSDocument {
        guard self.documents.count < MAX_OPEN_DOCUMENTS_LIMIT else {
            throw AppError(AppErrorCode.doc_create_new_failed, detail: "max documents count: \(MAX_OPEN_DOCUMENTS_LIMIT)")
        }
        return try super.openUntitledDocumentAndDisplay(displayDocument)
    }
    
    override func openDocument(withContentsOf url: URL, display displayDocument: Bool) async throws -> (NSDocument, Bool) {
        guard self.documents.count < MAX_OPEN_DOCUMENTS_LIMIT else {
            throw AppError(AppErrorCode.doc_create_new_failed, detail: "max documents count: \(MAX_OPEN_DOCUMENTS_LIMIT)")
        }
        return try await super.openDocument(withContentsOf: url, display: displayDocument)
    }
    
//    override class func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder) async throws -> NSWindow {
//        ret
//    }
    
    override func closeAllDocuments(withDelegate delegate: Any?, didCloseAllSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        if self.isKillingSelfAppWithNoDialogs {
            dlog?.note("closeAllDocuments : is killing app with no dialogs!")
            
            for doc in self.documents {
                doc.updateChangeCount(.changeDiscardable)
            }
        }
        
        super.closeAllDocuments(withDelegate: delegate, didCloseAllSelector: didCloseAllSelector, contextInfo: contextInfo)
    }
    
    override func clearRecentDocuments(_ sender: Any?) {
        super.clearRecentDocuments(sender)
        AppDocumentHistory.shared.clear()
    }
    
    override func noteNewRecentDocument(_ document: NSDocument) {
        _recentDocURL = nil
        super.noteNewRecentDocument(document)
        DispatchQueue.main.async {
            if let url = self._recentDocURL, let brickDocument = document as? BrickDoc {
                brickDocument.brick.info.displayName = document.displayName
                brickDocument.brick.info.filePath = url
                AppDocumentHistory.shared.updateBrickInfo(brickDocument.brick.info)
            }
            
            self._recentDocURL = nil
            self.menu?.updateWindowsMenuItems()
        }
    }
    
    override func noteNewRecentDocumentURL(_ url: URL) {
        super.noteNewRecentDocumentURL(url)
        _recentDocURL = url
        self.menu?.updateWindowsMenuItems()
    }
}

// Menu actions and validation
extension BrickDocController  /* Responder */ {
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
//        // dlog?.info("validateMenuItem \(menuItem)")
//        if let menuItem = menuItem as? MNMenuItem, let cmd = menuItem.associatedCommand {
//            return self.isAllowed(commandType: cmd)
//        }
        return super.validateMenuItem(menuItem)
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if let _ /*menuItem*/ = item as? NSMenuItem {
            // dlog?.info("validateUserInterfaceItem MENU: [\(menu.title)] action: \(menu.action.descOrNil)")
            //
        } else {
            dlog?.info("validateUserInterfaceItem \(item)")
        }
        
        return true
    }
    
    func invalidateMenu(context:String) {
        TimedEventFilter.shared.filterEvent(key: "invalidateMenu", threshold: 0.06, accumulating: context) { contexts in
            if let menu = self.menu {
                // dlog?.info("invalidateMenu \(menu.basicDesc) contexts: \(contexts?.descriptionsJoined ?? "<nil>" )")
                menu.determineState()
                menu.recalcLeafItems()
                for menuItem in menu.allLeafItems {
                    menuItem.isEnabled = self.validateMenuItem(menuItem)
                }
                
                if let wc = self.curDocWC {
                    wc.updateToolbarVisible()
                } else {
                    
                }
            }
        }
    }
    
    func invalidateWindows() {
        dlog?.info("invalidateWindows")
        BricksApplication.shared.windows.forEach({ window in
            window.invalidateShadow()
        })
    }
    
}

extension BrickDocController  /* Expected actions */ {
    
    // Command actions
    
    // App Menu
    @IBAction func showAboutPanel(_ sender: Any?) {
        dlog?.info("showAboutPanel")
        self.sendToInvoker(command: CmdAboutPanel())
    }
    
    @IBAction func showPreferencesMenuAction(_ sender :Any) {
        self.sendToInvoker(command: CmdPreferencesPanel())
    }
    
    // File Menu
    @IBAction override func newDocument(_ sender: Any?) {
        dlog?.info("responder newDocument")
        commandInvoker.addCommand(CmdNewProject())
    }
    
    @IBAction override func openDocument(_ sender: Any?) {
        dlog?.info("responder openDocument")
        commandInvoker.addCommand(CmdOpenProject())
    }

    @IBAction func cancel(_ sender: Any?) {
        if let topWindow = BricksApplication.shared.orderedWindows.first,let topVC = topWindow.contentViewController {
            
            dlog?.info("cancel action for sender: \(sender.descOrNil) topVC:\(topVC)")
            
            var isClose = false
            switch topVC {
            case is SplashVC:
                isClose = AppSettings.shared.general.splashScreenCloseBtnWillCloseApp == false
                if !isClose {
                    topWindow.shake()
                }
            case is AboutVC: isClose = true
            case is PreferencesVC: isClose = true
            default:
                break
            }
            
            if isClose {
                topWindow.fadeHide {
                    topWindow.close()
                }
            }
        }
    }
    
    //    override func openDocument(withContentsOf url: URL, display displayDocument: Bool, completionHandler: @escaping (NSDocument?, Bool, Error?) -> Void) {
    //        dlog?.info("openDocument \(url)")
    //    }
    
    // Edit Menu
    
    // Layer Menu
    
    // Window Menu
    func bringAllWindowsToFront(_ sender: Any?){
        // Convenience semantics method
        self.arrangeInFront(sender)
    }
    
    @IBAction func arrangeInFront(_ sender: Any?) {
        // "arrangeInFront" is the default, cannonical Cocoa out-of-the-box function name for this action.
        
        BricksApplication.shared.arrangeInFront(sender)
    }
    
    // Help Menu
    
}

extension BrickDocController : NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        dlogWindows?.info("windowWillClose \(notification.object.descOrNil)")
    }
    
    func windowDidExpose(_ notification: Notification) {
        dlogWindows?.info("windowDidExpose \(notification.object.descOrNil)")
        invalidateMenu(context: "windowDidExpose")
    }
    
    // DO NOT implement windowDidUpdate(...) if no good reason: very rapid events..
    
    func windowDidResize(_ notification: Notification) {
        dlogWindows?.info("windowDidResize \(notification.object.descOrNil)")
        // invalidateMenu(context: "windowDidResize")
    }
    
    func windowWillStartLiveResize(_ notification: Notification) {
        dlog?.info("windowWillStartLiveResize")
        invalidateMenu(context: "windowWillStartLiveResize")
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        dlog?.info("windowDidEndLiveResize")
        invalidateMenu(context: "windowDidEndLiveResize")
    }
    
    func windowDidResignMain(_ notification: Notification) {
        dlogWindows?.info("windowDidResignMain \(notification.object.descOrNil)")
        invalidateMenu(context: "windowDidResignMain")
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        dlogWindows?.info("windowDidBecomeMain \(notification.object.descOrNil)")
        invalidateMenu(context: "windowDidBecomeMain")
        if let win = notification.object as? NSWindow {
            self.curDocWC = (win.windowController as? DocWC)
        }
    }
    
    func windowDidChangeScreen(_ notification: Notification) {
        dlogWindows?.info("windowDidChangeScreen \(notification.object.descOrNil)")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        dlogWindows?.info("windowDidBecomeKey \(notification.object.descOrNil)")
        invalidateMenu(context: "windowDidBecomeKey")
    }
    
    func windowDidResignKey(_ notification: Notification) {
        dlogWindows?.info("windowDidResignKey \(notification.object.descOrNil)")
        invalidateMenu(context: "windowDidResignKey")
    }
    
    func windowWillBeginSheet(_ notification: Notification) {
        dlogWindows?.info("windowWillBeginSheet \(notification.object.descOrNil)")
        invalidateMenu(context: "windowWillBeginSheet")
    }
    
    func windowDidEndSheet(_ notification: Notification) {
        dlogWindows?.info("windowDidEndSheet \(notification.object.descOrNil)")
        invalidateMenu(context: "windowDidEndSheet")
    }
    
    func windowDidChangeOcclusionState(_ notification: Notification) {
        dlogWindows?.info("windowDidChangeOcclusionState \(notification.object.descOrNil)")
        invalidateMenu(context: "windowDidChangeOcclusionState")
    }
    
    func windowDidUpdate(_ notification: Notification) {
        // dlog?.info("windowDidUpdate \(notification.object.descOrNil)")
    }
    
    //func windowWillUseStandardFrame(_ window: NSWindow, defaultFrame newFrame: NSRect) -> NSRect {
    //    return window.frame
    //}
}

@objc extension BrickDocController /* NSApplication observation */ {
    
    func observeAppDelegateNotifications() {
        let pairs : [(selector:Selector, name:NSNotification.Name)] = [
            (#selector(applicationWillTerminate(_:)), NSApplication.willTerminateNotification),
        ]
        for pair in pairs {
            NotificationCenter.default.addObserver(self, selector: pair.selector, name: pair.name, object:  nil)
        }
    }
    
}

@objc extension BrickDocController /* NSWorkspace observation */ {
    private func checkForOtherAppInstancesRunning() {
        // Prevent another instance from loading?
        for app in NSWorkspace.shared.runningApplications {
            if app != NSRunningApplication.current, let bid = app.bundleIdentifier, bid == NSRunningApplication.current.bundleIdentifier {
                
                // App
                if self.isKillingSelfAppWithNoDialogs == false {
                    dlog?.warning("OS is launching another instance of this app!!")
                    
                    self.isKillingSelfAppWithNoDialogs = true
                    BrickDocController.shared.closeAllDocuments(withDelegate: self, didCloseAllSelector: nil, contextInfo: nil)
                    // will change how the document func canClose(withDelegate:shouldClose:contextInfo).. closes the docs
                    
                    // TODO: Test this situation of two app intances intalled in two different paths, prevent dupliate instances running.
                    // Kill current
                    let curApp = NSRunningApplication.current
                    dlog?.warning("Intentionally killing this app")
                    curApp.terminate()
                    
                    // Activate the previous instance
                    app.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
                    return
                }
            }
        }
    }
    
    func observeWorkspaceNotifications() {
        let pairs : [(selector:Selector, name:NSNotification.Name)] = [
            (#selector(willLaunchApplicationNotification(_:)), NSWorkspace.willLaunchApplicationNotification),
            (#selector(didLaunchApplicationNotification(_:)), NSWorkspace.didLaunchApplicationNotification),
            (#selector(didHideApplicationNotification(_:)), NSWorkspace.didHideApplicationNotification),
            (#selector(didUnhideApplicationNotification(_:)), NSWorkspace.didUnhideApplicationNotification),
            (#selector(didActivateApplicationNotification(_:)), NSWorkspace.didActivateApplicationNotification),
            (#selector(didDeactivateApplicationNotification(_:)), NSWorkspace.didDeactivateApplicationNotification),
        ]
        for pair in pairs {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: pair.selector, name: pair.name, object:  nil)
        }
    }
    
    func didLaunchApplicationNotification(_ notification:NSNotification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard let app = app else {
            return
        }
        
        if app == NSRunningApplication.current  {
            dlog?.info("didLaunchApplicationNotification [\(app.localizedName ?? app.description)]")
        } else {
            // Prevent another instance from loading?
            self.checkForOtherAppInstancesRunning()
        }
    }
    
    func willLaunchApplicationNotification(_ notification:NSNotification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard let app = app else {
            return
        }
        
        if app == NSRunningApplication.current  {
            dlog?.info("willLaunchApplicationNotification [\(app.localizedName ?? app.description)]")
        } else {
            // Prevent another instance from loading?
            self.checkForOtherAppInstancesRunning()
        }
    }
    
    func didHideApplicationNotification(_ notification:NSNotification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard let app = app, app == NSRunningApplication.current else {
            return
        }
        
        dlog?.info("didHideApplicationNotification [\(app.localizedName ?? app.description)]")
        DispatchQueue.main.asyncAfter(delayFromNow: 0.03) {
            self.invalidateMenu(context: "didHideApplicationNotification")
        }
    }
    
    func didUnhideApplicationNotification(_ notification:NSNotification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard let app = app, app == NSRunningApplication.current else {
            return
        }
        
        dlog?.info("didUnhideApplicationNotification [\(app.debugName)]")
        DispatchQueue.main.asyncAfter(delayFromNow: 0.03) {
            self.invalidateMenu(context: "didUnhideApplicationNotification")
        }
    }
    
    func didActivateApplicationNotification(_ notification:NSNotification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard let app = app else {
            return
        }
        
        if app == NSRunningApplication.current {
            dlog?.info("didActivateApplicationNotification \(app.debugName)")
            DispatchQueue.main.asyncAfter(delayFromNow: 0.03) {
                self.invalidateMenu(context: "didActivateApplicationNotification")
            }
        } else {
            self.checkForOtherAppInstancesRunning()
        }
    }
    
    func didDeactivateApplicationNotification(_ notification:NSNotification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard let app = app, app == NSRunningApplication.current else {
            return
        }
        
        dlog?.info("didDeactivateApplicationNotification \(app.debugName)")
        DispatchQueue.main.asyncAfter(delayFromNow: 0.03) {
            self.invalidateMenu(context: "didDeactivateApplicationNotification")
        }
    }
}

fileprivate extension NSRunningApplication {
    
    var debugName : String {
        return "[" + (self.localizedName ?? self.bundleIdentifier ?? "Unknown") + "]"
    }
}
