//
//  AppDelegate.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import Cocoa

// TODO: check out usage and adding XcodeKit.
fileprivate let dlog : DSLogger? = DLog.forClass("AppDelegate")

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Private
    private func onLaunchActions(completion:@escaping AppResultBlock) {
        // Init singletons
        _ = AppSettings.shared
        _ = AppDocumentHistory.shared
        AppSandboxer.loadBookmarks()
        
        AppSettings.shared.stats.launchCount += 1
        AppSettings.shared.stats.lastLaunchDate = Date()
        let version = Bundle.main.fullVersionAsDisplayString
        dlog?.info("-- App Launched version: [\(version)] launch count: \(AppSettings.shared.stats.launchCount) --")
        completion(.success(version))
    }

    @discardableResult
    private func presentSplashWindow()->Bool {
        if let windowController = AppStoryboard.splashscreen.instantiateWindowController(id: "SplashWCID") {
            windowController.window?.makeKeyAndOrderFront(self)
            return true
        }
        return false
    }
    
    private func loadAndPresentDocument(at url:URL) {
        
    }
    
    private func loadAndPresentDocument(info : BrickBasicInfo) {
        
    }
    
    private func presentFirstWindow() {
        if AppSettings.shared.general.showsSplashScreenOnInit &&
            self.presentSplashWindow() {
            // Shows splash screen
        } else {
            AppDocumentHistory.shared.whenLoaded({ updated in
                if let docInfo = AppDocumentHistory.shared.history.first {
                    dlog?.info("Should load recent document: \(docInfo)")
                    self.loadAndPresentDocument(info: docInfo)
                } else {
                    DispatchQueue.main.asyncAfter(delayFromNow: 0.5) {
                        if NSApplication.shared.windows.count == 0 {
                            dlog?.note("No file loaded and no splash screen in settings")
                            self.presentSplashWindow()
                        }
                    }
                }
            })
        }
    }
    
    // MARK: NSApplicationDelegate
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        dlog?.info("Reopen - user clicked on app icon again")
        if sender.windows.count == 0 {
            self.presentSplashWindow()
        }
        return true
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        // init for NSDocuemntController subclass MUST take place before app finishes launching
        let _ /*brickController*/ = BrickDocumentController()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        self.onLaunchActions { result in
            switch result {
            case .success:
                self.presentFirstWindow()
            case .failure(let error):
                // Show alert
                let appErr = AppError(error: error)
                dlog?.warning("applicationDidFinishLaunching failed launching: \(appErr)")
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        UserDefaults.standard.synchronize()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: Menu actions
    @IBAction func showPreferencesMenuAction(_ sender :Any) {
        if let windowController = AppStoryboard.preferences.instantiateWindowController(id: "PreferencesWCID") {
            windowController.window?.makeKeyAndOrderFront(self)
        }
    }
}

