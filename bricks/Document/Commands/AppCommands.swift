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
    let showsRecents : Bool!
    
    init(showsRecents newShowsRecents:Bool) {
        showsRecents = newShowsRecents
    }
    
    func execute(compeltion: @escaping CommandResultBlock) {
        //BricksApplication.
        dlog?.info("execute")
        AppStoryboard.onboarding.instantiateWCAndPresent(from: nil, id: "SplashWCID", asMain: false, asKey: true) { wc in
            
            if let vc = wc.contentViewController as? SplashVC {
                
                wc.window?.forceWindowCornerRadius(12, setup: { window in
                    window?.isMovableByWindowBackground = true
                    window?.contentView?.layer?.border(color: NSColor.underPageBackgroundColor, width: 1)
                })
                vc.setHistoryTableHidden(self.showsRecents == false)
                
                // call completion
                compeltion(.success("<SplashVC \(String(memoryAddressOf: vc))>"))
            } else {
                compeltion(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading splash screen.")))
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
    
    func execute(compeltion: @escaping CommandResultBlock) {
        
        dlog?.info("execute")
        AppStoryboard.onboarding.instantiateWCAndPresent(from: nil, id: "AboutWCID", asMain: true, asKey: true) { wc in
            if let vc = wc.contentViewController as? AboutVC {
                
                // call completion
                compeltion(.success("<AboutVC \(String(memoryAddressOf: vc))>"))
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
    
    func execute(compeltion: @escaping CommandResultBlock) {
        dlog?.info("execute")
        AppStoryboard.onboarding.instantiateWCAndPresent(from: nil, id: "PreferencesWCID", asMain: false, asKey: true) { wc in
            if let vc = wc.contentViewController as? PreferencesVC {
                
                // call completion
                compeltion(.success("<PreferencesVC \(String(memoryAddressOf: vc))>"))
            } else {
                compeltion(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading about screen.")))
            }
        }
    }
    
    func undo(compeltion: @escaping CommandResultBlock) {
        dlog?.info("undo")
    }
}
