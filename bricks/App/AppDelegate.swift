//
//  AppDelegate.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import Cocoa

// TODO: check out usage and adding XcodeKit.
fileprivate let dlog : DSLogger? = DLog.forClass("AppDelegate")

fileprivate var instance : AppDelegate? = nil

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    weak var documentController : BrickDocController? = nil
    weak var mainMenu : MainMenu? = nil
    
    static var shared : AppDelegate {
        return instance ?? AppDelegate()
    }
    
    private override init() {
        super.init()
        dlog?.info("init")
        instance = self
    }
    
    deinit {
        dlog?.info("deinit")
    }
    
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
    private func presentSplashWindow(showsRecents:Bool)->Bool {
        let cmd = CmdSplashWindow(showsRecents: showsRecents)
        BrickDocController.shared.sendToInvoker(command: cmd)
        return false
    }
    
    private func loadAndPresentDocument(at url:URL) {
        
    }
    
    private func loadAndPresentDocument(info : BrickBasicInfo) {
        
    }
    
    private func presentFirstWindow() {
        AppDocumentHistory.shared.whenLoaded({ updated in
            let hasRecents = (AppDocumentHistory.shared.history.count > 0)
            if AppSettings.shared.general.showsSplashScreenOnInit &&
                self.presentSplashWindow(showsRecents: hasRecents) {
                    // Splash screen was presented
            } else {
                if let docInfo = AppDocumentHistory.shared.history.first {
                    dlog?.info("Should load recent document: \(docInfo)")
                    self.loadAndPresentDocument(info: docInfo)
                } else {
                    DispatchQueue.main.asyncAfter(delayFromNow: 0.5) {
                        if BricksApplication.shared.orderedWindows.count == 0 {
                            dlog?.note("No file loaded and no splash screen in settings")
                            
                            // Splash screen will be presented
                            self.presentSplashWindow(showsRecents: false)
                        }
                    }
                }
            }
        })
    }
    
    // MARK: NSApplicationDelegate
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        dlog?.info("Reopen - user clicked on app icon again")
        if BricksApplication.shared.orderedWindows.count == 0 {
            AppDocumentHistory.shared.whenLoaded { updated in
                let hasRecents = (AppDocumentHistory.shared.history.count > 0)
                
                // Splash screen will be presented
                self.presentSplashWindow(showsRecents: hasRecents)
            }
        }
        return true
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        dlog?.info("applicationShouldOpenUntitledFile")
        return false
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        // init for NSDocuemntController subclass MUST take place before app finishes launching
        dlog?.info("applicationWillFinishLaunching")
        documentController = BrickDocController.shared
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        dlog?.info("applicationDidFinishLaunching")
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
        dlog?.info("applicationWillTerminate")
        
        // Insert code here to tear down your application
        UserDefaults.standard.synchronize()
        
        BricksApplication.shared.mainMenu = nil
        instance = nil
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

