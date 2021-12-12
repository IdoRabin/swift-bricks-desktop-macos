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
    
    override class var shared: BrickDocController {
        return super.shared as! BrickDocController
    }
    
    let commandInvoker = QueuedInvoker()
    
    var menu : MainMenu? {
        return AppDelegate.shared.mainMenu
    }
    
    private var _recentDocURL:URL? = nil
    
    override init() {
        super.init()
        listenToWorkspaceNotifications()
        AppDelegate.shared.documentController = self
        dlog?.info("init")
    }
    
    required init?(coder: NSCoder) {
        dlog?.info("init coder")
        // listenToWorkspaceNotifications()
        fatalError("init(coder:) has not been implemented")
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
        }
    }
    
    override func noteNewRecentDocumentURL(_ url: URL) {
        super.noteNewRecentDocumentURL(url)
        _recentDocURL = url
    }
    
    deinit {
        dlog?.info("deinit")
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

@objc extension BrickDocController /* NSWorkspace observation */ {
    
    func listenToWorkspaceNotifications() {
        let pairs : [(selector:Selector, name:NSNotification.Name)] = [
            (#selector(willLaunchApplicationNotification(_:)), NSWorkspace.willLaunchApplicationNotification),
            (#selector(didHideApplicationNotification(_:)), NSWorkspace.didHideApplicationNotification),
            (#selector(didUnhideApplicationNotification(_:)), NSWorkspace.didUnhideApplicationNotification),
            (#selector(didActivateApplicationNotification(_:)), NSWorkspace.didActivateApplicationNotification),
            (#selector(didDeactivateApplicationNotification(_:)), NSWorkspace.didDeactivateApplicationNotification)
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
