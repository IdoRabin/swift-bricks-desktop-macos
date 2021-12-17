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

class BrickDocController: NSDocumentController {
    let MAX_OPEN_DOCUMENTS_LIMIT = 16
    
    // MARK: Singleton
    override class var shared: BrickDocController {
        return super.shared as! BrickDocController
    }
    
    // MARK: Properties
    private var _appIsTerminating = false
    var appIsTerminating : Bool {
        return _appIsTerminating
    }
    
    let commandInvoker = QueuedInvoker()
    var menu : MainMenu? {
        return AppDelegate.shared.mainMenu
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
            window.contentViewController is DocVC
        }
    }
    
    // MARK: Lifecycle
    override init() {
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
                }
            }
        }
    }
    
    func updateSplashWindowIfNeeded() {
        guard self.appIsTerminating == false else {
            return
        }
        
        // We show the splahs screen by force
        // let forceShowSplash = self.lastClosedWasOnSplashScreen && (AppSettings.shared.stats.lastLaunchDate.timeIntervalSinceNow < 2.0)
        
        if self.documents.count == 0 { // } || forceShowSplash {
            // Show the splash window
            dlog?.info("will present the splash window")
            self.sendToInvoker(command: CmdSplashWindow(showsRecents: AppDocumentHistory.shared.history.count > 0))
        } else {
            // Find and close the splash window
            closeSplashWindow(wasLastWindow: false)
        }
    }
    
    // MARK: Overrides
    override func addDocument(_ document: NSDocument) {
        super.addDocument(document)
        self.closeSplashWindow(wasLastWindow:false)
        DispatchQueue.main.asyncAfter(delayFromNow: 0.5) {
            self.updateSplashWindowIfNeeded()
        }
    }

    override func removeDocument(_ document: NSDocument) {
        super.removeDocument(document)
        self.updateSplashWindowIfNeeded()
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
        }
    }
    
    override func noteNewRecentDocumentURL(_ url: URL) {
        super.noteNewRecentDocumentURL(url)
        _recentDocURL = url
    }
}

// Menu actions and validation
extension BrickDocController  /* Responder */ {
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // dlog?.info("validateMenuItem \(menuItem)")
        if let menuItem = menuItem as? MNMenuItem, let cmd = menuItem.associatedCommand {
            return self.isAllowed(commandType: cmd)
        }
        return super.validateMenuItem(menuItem)
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item is NSMenuItem || item is MNMenuItem {
            
        } else {
            dlog?.info("validateUserInterfaceItem \(item)")
        }
        
        return true
    }
    
    func invalidateMenu() {
        TimedEventFilter.shared.filterEvent(key: "invalidateMenu", threshold: 0.05) {[self] in
            if let menu = self.menu {
                // dlog?.info("invalidateMenu \(menu.basicDesc)")
                menu.determineState()
                menu.recalcLeafItems()
                for menuItem in menu.allLeafItems {
                    menuItem.isEnabled = self.validateMenuItem(menuItem)
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
    
    // Help Menu
    
}

extension BrickDocController : NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        dlogWindows?.info("windowWillClose \(notification.object.descOrNil)")
    }
    
    func windowDidExpose(_ notification: Notification) {
        dlogWindows?.info("windowDidExpose \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    // DO NOT implement windowDidUpdate(...) if no good reason: very rapid events..
    
    func windowDidResize(_ notification: Notification) {
        dlogWindows?.info("windowDidResize \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidResignMain(_ notification: Notification) {
        dlogWindows?.info("windowDidResignMain \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        dlogWindows?.info("windowDidBecomeMain \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidChangeScreen(_ notification: Notification) {
        dlogWindows?.info("windowDidChangeScreen \(notification.object.descOrNil)")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        dlogWindows?.info("windowDidBecomeKey \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidResignKey(_ notification: Notification) {
        dlogWindows?.info("windowDidResignKey \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowWillBeginSheet(_ notification: Notification) {
        dlogWindows?.info("windowWillBeginSheet \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidEndSheet(_ notification: Notification) {
        dlogWindows?.info("windowDidEndSheet \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidChangeOcclusionState(_ notification: Notification) {
        dlogWindows?.info("windowDidChangeOcclusionState \(notification.object.descOrNil)")
        invalidateMenu()
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
    
    func observeWorkspaceNotifications() {
        let pairs : [(selector:Selector, name:NSNotification.Name)] = [
            (#selector(willLaunchApplicationNotification(_:)), NSWorkspace.willLaunchApplicationNotification),
            (#selector(didHideApplicationNotification(_:)), NSWorkspace.didHideApplicationNotification),
            (#selector(didUnhideApplicationNotification(_:)), NSWorkspace.didUnhideApplicationNotification),
            (#selector(didActivateApplicationNotification(_:)), NSWorkspace.didActivateApplicationNotification),
            (#selector(didDeactivateApplicationNotification(_:)), NSWorkspace.didDeactivateApplicationNotification),
        ]
        for pair in pairs {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: pair.selector, name: pair.name, object:  nil)
        }
    }
    
    func willLaunchApplicationNotification(_ notification:NSNotification) {
        //dlog?.info("willLaunchApplicationNotification")
    }
    
    func didHideApplicationNotification(_ notification:NSNotification) {
        //dlog?.info("didHideApplicationNotification")
        DispatchQueue.main.asyncAfter(delayFromNow: 0.03) {
            self.invalidateMenu()
        }
    }
    
    func didUnhideApplicationNotification(_ notification:NSNotification) {
        //dlog?.info("didUnhideApplicationNotification")
        DispatchQueue.main.asyncAfter(delayFromNow: 0.03) {
            self.invalidateMenu()
        }
    }
    
    func didActivateApplicationNotification(_ notification:NSNotification) {
        //dlog?.info("didActivateApplicationNotification")
        DispatchQueue.main.asyncAfter(delayFromNow: 0.03) {
            self.invalidateMenu()
        }
    }
    
    func didDeactivateApplicationNotification(_ notification:NSNotification) {
        //dlog?.info("didDeactivateApplicationNotification")
        DispatchQueue.main.asyncAfter(delayFromNow: 0.03) {
            self.invalidateMenu()
        }
    }
}
