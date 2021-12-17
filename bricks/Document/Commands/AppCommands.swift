//
//  AppCommands.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import Foundation
import AppKit

class CmdSplashWindow : AppCommand {
    static let category: AppCommandCategory = .app
    
    static var keyboardShortcut = KeyboardShortcut.empty
    static let buttonTitle: String = AppStr.PRESENT_SPLASH_SCREEN.localized()
    static let buttonImageName: String? = nil
    static let menuTitle: String? = AppStr.PRESENT_SPLASH_SCREEN.localized()
    static let tooltipTitle: String? = AppStr.PRESENT_SPLASH_SCREEN.localized()
    static weak var menuRepresentation: MNMenuItem? = nil
    let showsRecents : Bool!
    
    
    init(showsRecents newShowsRecents:Bool) {
        showsRecents = newShowsRecents
    }
    
    func execute(compeltion: @escaping CommandResultBlock) {
        //BricksApplication.
        dlog?.info("execute")
        
        func saveFlags() {
            BrickDocController.shared.lastClosedWasOnSplashScreen = BrickDocController.shared.brickDocWindows.count == 0
        }
        
        if SplashVC.sharedWindowController != nil, let vc = SplashVC.sharedWindowController?.contentViewController {
            dlog?.note("Splash vc was already presented")
            compeltion(.success("existed: \(vc.basicDesc)"))
            SplashVC.sharedWindowController?.becomeFirstResponder()
            SplashVC.sharedWindowController?.window?.becomeKey()
            if BrickDocController.shared.documents.count == 0 || BrickDocController.shared.brickDocWindows.count == 0 {
                SplashVC.sharedWindowController?.window?.becomeMain()
            }
            SplashVC.sharedWindowController?.bringWindowToFront()
            saveFlags()
            
        } else {
            AppStoryboard.onboarding.instantiateWCAndPresent(from: nil, id: "SplashWCID", asMain: false, asKey: true) { wc in
                
                if let vc = wc.contentViewController as? SplashVC {
                    
                    wc.window?.forceWindowCornerRadius(12, setup: { window in
                        window?.isMovableByWindowBackground = true
                        window?.contentView?.layer?.border(color: NSColor.underPageBackgroundColor, width: 1)
                    })
                    vc.setHistoryTableHidden(self.showsRecents == false)
                    saveFlags()
                    
                    // call completion
                    compeltion(.success("created \(vc.basicDesc)>"))
                } else {
                    compeltion(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading splash screen.")))
                }
            }
        }
    }
    
    func undo(compeltion: @escaping CommandResultBlock) {
        dlog?.info("undo")
    }
}

class CmdAboutPanel : AppCommand {
    static let category: AppCommandCategory = .app
    
    static var keyboardShortcut = KeyboardShortcut.empty
    static let buttonTitle: String = AppStr.ABOUT_APP_FORMAT.formatLocalized(AppStr.PRODUCT_NAME.localized())
    static let buttonImageName: String? = nil
    static let menuTitle: String? = AppStr.ABOUT_APP_FORMAT.formatLocalized(AppStr.PRODUCT_NAME.localized())
    static let tooltipTitle: String? = AppStr.ABOUT.localized()
    static weak var menuRepresentation: MNMenuItem? = nil
    
    func execute(compeltion: @escaping CommandResultBlock) {
        
        dlog?.info("execute")
        AppStoryboard.onboarding.instantiateWCAndPresent(from: nil, id: "AboutWCID", asMain: true, asKey: true) { wc in
            if let vc = wc.contentViewController as? AboutVC {
                
                // call completion
                compeltion(.success("created \(vc.basicDesc)"))
            } else {
                compeltion(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading about screen.")))
            }
        }
    }
    
    func undo(compeltion: @escaping CommandResultBlock) {
        dlog?.info("undo")
    }
}

class CmdPreferencesPanel : AppCommand {
    static let category: AppCommandCategory = .app
    
    static var keyboardShortcut = KeyboardShortcut(modifiers: .command, chars: ",")
    static let buttonTitle: String = AppStr.PREFERENCES_DOT_DOT.localized()
    static let buttonImageName: String? = nil
    static let menuTitle: String? = AppStr.PREFERENCES_DOT_DOT.localized()
    static let tooltipTitle: String? = AppStr.PREFERENCES_DOT_DOT.localized()
    static weak var menuRepresentation: MNMenuItem? = nil
    
    func execute(compeltion: @escaping CommandResultBlock) {
        dlog?.info("execute")
        AppStoryboard.onboarding.instantiateWCAndPresent(from: nil, id: "PreferencesWCID", asMain: false, asKey: true) { wc in
            if let vc = wc.contentViewController as? PreferencesVC {
                
                // call completion
                compeltion(.success("created \(vc.basicDesc)>"))
            } else {
                compeltion(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading about screen.")))
            }
        }
    }
    
    func undo(compeltion: @escaping CommandResultBlock) {
        dlog?.info("undo")
    }
}
