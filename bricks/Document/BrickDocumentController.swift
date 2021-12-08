//
//  BrickDocumentController.swift
//  Bricks
//
//  Created by Ido Rabin on 08/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDocumentController")

class BrickDocumentController: NSDocumentController {
    
    var menu : MainMenu? {
        return AppDelegate.shared.mainMenu
    }
    
    private var _recentDocURL:URL? = nil
    
    override init() {
        super.init()
        AppDelegate.shared.documentController = self
        dlog?.info("init")
    }
    
    required init?(coder: NSCoder) {
        dlog?.info("init coder")
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
            if let url = self._recentDocURL, let brickDocument = document as? BrickDocument {
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
extension BrickDocumentController  /* Responder */ {
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        dlog?.info("validateMenuItem \(menuItem)")
        return true
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        dlog?.info("validateUserInterfaceItem \(item)")
        return true
    }
    
    func invalidateMenu() {
        menu?.determineState()
        
//        let window = NSApplication.shared.orderedWindows.first
//        if window == nil {
//            menu?.items.forEach({ item in
//                item.isEnabled = false
//            })
//        }
//        dlog?.info("invalidateMenu for window:\(window.descOrNil)")
    }
    
    func invalidateWindows() {
        dlog?.info("invalidateWindows")
        NSApplication.shared.windows.forEach({ window in
            window.invalidateShadow()
        })
    }
}

extension BrickDocumentController  /* Expected actions */ {
    
    override func newDocument(_ sender: Any?) {
        dlog?.info("responder newDocument")
    }
    
}


extension BrickDocumentController : NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        dlog?.info("windowWillClose \(notification.object.descOrNil)")
    }
    
    func windowDidExpose(_ notification: Notification) {
        dlog?.info("windowDidExpose \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    // DO NOT implement windowDidUpdate(...) if no good reason: very rapid events..
    
    func windowDidResize(_ notification: Notification) {
        dlog?.info("windowDidResize \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidResignMain(_ notification: Notification) {
        dlog?.info("windowDidResignMain \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        dlog?.info("windowDidBecomeMain \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidChangeScreen(_ notification: Notification) {
        dlog?.info("windowDidChangeScreen \(notification.object.descOrNil)")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        dlog?.info("windowDidBecomeKey \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidResignKey(_ notification: Notification) {
        dlog?.info("windowDidResignKey \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowWillBeginSheet(_ notification: Notification) {
        dlog?.info("windowWillBeginSheet \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidEndSheet(_ notification: Notification) {
        dlog?.info("windowDidEndSheet \(notification.object.descOrNil)")
        invalidateMenu()
    }
    
    func windowDidChangeOcclusionState(_ notification: Notification) {
        dlog?.info("windowDidChangeOcclusionState \(notification.object.descOrNil)")
        invalidateMenu()
    }
}
