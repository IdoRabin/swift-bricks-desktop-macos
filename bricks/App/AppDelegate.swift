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
        dlog?.info("init \(basicDesc)")
        instance = self
        _ = AppSettings.shared
    }
    
    deinit {
        dlog?.info("deinit \(self.basicDesc)")
    }
    
    // MARK: Private
    private func onLaunchActions(completion:@escaping AppResultBlock) {
        // Init singletons
        _ = AppDocumentHistory.shared
        AppSandboxer.loadBookmarks()
        
        AppSettings.shared.stats.launchCount += 1
        AppSettings.shared.stats.lastLaunchDate = Date()
        let version = Bundle.main.fullVersionAsDisplayString
        dlog?.info("-- App Launched version: [\(version)] launch count: \(AppSettings.shared.stats.launchCount) --")
        completion(.success(version))
    }

    @discardableResult
    private func presentSplashWindow(showsRecents:Bool, context:CommandContext)->Bool {
        if BrickDocController.shared.documents.count == 0 {
            return BrickDocController.shared.createCommand(CmdSplashWindow.self, context: context, isEnqueue:true) != nil
        }
        return false
    }
    
    private func hideSplashWindowIfPossible(animated:Bool = true, waitTime:TimeInterval = 0.01, depth:Int = 0) {
        guard depth < 15 else {
            return
        }
        
        waitFor("SplashVC instance", interval: min(0.02, waitTime), timeout: max(waitTime, 0.02), testOnMainThread: {
            NSApplication.shared.windows.contains { window in
                window.contentViewController is SplashVC
            }
        }, completion: { waitResult in
            DispatchQueue.mainIfNeeded {
                switch waitResult {
                case .success:
                    if let window = NSApplication.shared.windows.first(where: { window in
                        window.contentViewController is SplashVC
                    }) {
                        if window.isVisible, let splashVC = window.contentViewController as? SplashVC {
                            dlog?.info("hideSplashWindowIfPossible:(animated:Bool) START")
                            splashVC.hideAndCloseSelf(animated: animated) {(wasClosed) in
                                dlog?.info("hideSplashWindowIfPossible wasClosed:\(wasClosed) END")
                            }
                        }
                    }
                case .timeout:
                    break
                }
            }
        }, logType: .never)
    }
    
    private func loadAndPresentDocument(at url:URL) {
        dlog?.todo("Chdck if doc is not already loaded, if not, then load..")
    }
    
    private func loadAndPresentDocument(info : BrickBasicInfo) {
        dlog?.todo("Chdck if doc is not already loaded, if not, then load..")
    }
    
    private func isShouldShowSplashWindowOnInit()->Bool {
        guard BrickDocController.shared.brickDocWindows.count == 0 else {
            return false
        }
        
        let aDocNeedsRestoringOnInit = AppDocumentHistory.shared.history.contains { info in
            info.shouldRestoreOnInit
        }
        return BrickDocController.shared.lastClosedWasOnSplashScreen || (aDocNeedsRestoringOnInit == false)
    }
    
    func presentFirstWindow() {
        guard abs(AppSettings.shared.stats.lastLaunchDate.timeIntervalSinceNow) < 2.0 else {
            dlog?.note("presentFirstWindow cannot be called after app launch")
            return
        }
        
        AppDocumentHistory.shared.whenLoaded({ updated in
            let hasRecents = (AppDocumentHistory.shared.history.count > 0)
            if self.isShouldShowSplashWindowOnInit() {
                self.presentSplashWindow(showsRecents: hasRecents, context: "presentFirstWindow_1")
                // Splash screen was presented
                DispatchQueue.main.async {
                    // We hide splash screen if any document was loaded during init / autoloaded / restored
                    if BrickDocController.shared.brickDocWindows.count > 0 {
                        dlog?.todo("Should hide splash screen")
                        self.hideSplashWindowIfPossible(animated: false)
                    }
                }
            } else {
                if let docInfo = AppDocumentHistory.shared.history.first {
                    dlog?.info("Should load recent document: \(docInfo)")
                    self.loadAndPresentDocument(info: docInfo)
                } else {
                    DispatchQueue.main.asyncAfter(delayFromNow: 0.5) {
                        if BricksApplication.shared.orderedWindows.count == 0 {
                            dlog?.note("No file loaded and no splash screen in settings")
                            
                            // Splash screen will be presented
                            self.presentSplashWindow(showsRecents: false, context: "presentFirstWindow_2")
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
                self.presentSplashWindow(showsRecents: hasRecents, context: "applicationShouldHandleReopen")
            }
        } else {
            // Bring all to front
            BricksApplication.shared.arrangeInFront(sender)
        }
        return true
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        let result = BrickDocController.shared.lastClosedWasOnSplashScreen == false
        dlog?.info("applicationShouldOpenUntitledFile: \(result)")
        return result
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
        dlog?.info("applicationWillTerminate START")
        
        // Insert code here to tear down your application
        AppSettings.shared.saveIfNeeded()
        BricksApplication.shared.mainMenu = nil
        instance = nil
        
        dlog?.info("applicationWillTerminate END")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
