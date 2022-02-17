//
//  AppCommands.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import Foundation
import AppKit

class CmdSplashWindow : AppCommand {
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .app
    static var keyboardShortcut : KeyboardShortcut = .empty
    static var buttonTitle: String = AppStr.PRESENT_SPLASH_SCREEN.localized()
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.PRESENT_SPLASH_SCREEN.localized()
    static var tooltipTitle : String? = AppStr.PRESENT_SPLASH_SCREEN.localized()
    
    // MARK: Command properties
    weak var receiver: CommandReciever?
    var context: CommandContext
    var showsRecents : Bool = false
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod = .execute, context: CommandContext, reciever: CommandReciever?) -> Bool {
        let result = [.execute, .redo].contains(method)
        return result // undo not allowed
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        // NOTE: Invoker / external caller is assumed to responsible to test isAllowed !
        
        DispatchQueue.mainIfNeeded {[self] in
            func saveFlags() {
                BrickDocController.shared.lastClosedWasOnSplashScreen = BrickDocController.shared.brickDocWindows.count == 0
            }
            
            if SplashVC.sharedWindowController != nil, let vc = SplashVC.sharedWindowController?.contentViewController {
                dlog?.note("Splash vc was already presented")
                completion(.success("existed: \(vc.basicDesc)"))
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
                            window?.contentView?.wantsLayer = true
                            window?.contentView?.layer?.border(color: NSColor.underPageBackgroundColor, width: 1)
                        })
                        vc.setHistoryTableHidden(self.showsRecents == false)
                        saveFlags()
                        
                        // call completion
                        completion(.success("created \(vc.basicDesc)>"))
                    } else {
                        completion(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading splash screen.")))
                    }
                }
            }
        }
    }
    
    // MARK: Lifecycle
    init(context: CommandContext, receiver: CommandReciever?, showsRecents:Bool) {
        self.receiver = receiver
        self.context = context
        self.showsRecents = showsRecents
    }
}

class CmdAboutPanel : AppCommand {

    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .app
    static var keyboardShortcut : KeyboardShortcut = .empty
    static var buttonTitle: String = AppStr.ABOUT_APP_FORMAT.formatLocalized(AppStr.PRODUCT_NAME.localized())
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.ABOUT_APP_FORMAT.formatLocalized(AppStr.PRODUCT_NAME.localized())
    static var tooltipTitle : String? = AppStr.ABOUT.localized()
    
    // MARK: Command properties
    weak var receiver: CommandReciever?
    var context: CommandContext
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod = .execute, context: CommandContext, reciever: CommandReciever?) -> Bool {
        let result = [.execute, .redo].contains(method)
        return result // undo not allowed
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        // NOTE: Invoker / external caller is assumed to responsible to test isAllowed !
        
        // Execute command:
        DispatchQueue.mainIfNeeded {
            AppStoryboard.onboarding.instantiateWCAndPresent(from: nil, id: "AboutWCID", asMain: true, asKey: true) { wc in
                if let vc = wc.contentViewController as? AboutVC {
                    
                    // call completion
                    completion(.success("created \(vc.basicDesc)"))
                } else {
                    completion(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading about screen.")))
                }
            }
        }
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: CommandReciever?) {
        self.receiver = receiver
        self.context = context
    }
}

class CmdPreferencesPanel : AppCommand {
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .app
    static var keyboardShortcut : KeyboardShortcut = KeyboardShortcut(modifiers: .command, chars: ",")
    static var buttonTitle: String = AppStr.PREFERENCES_DOT_DOT.localized()
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.PREFERENCES_DOT_DOT.localized()
    static var tooltipTitle : String? = AppStr.PREFERENCES_DOT_DOT.localized()
    
    // MARK: Command properties
    weak var receiver: CommandReciever?
    var context: CommandContext
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod = .execute, context: CommandContext, reciever: CommandReciever?) -> Bool {
        let result = [.execute, .redo].contains(method)
        return result // undo not allowed
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        // NOTE: Invoker / external caller is assumed to responsible to test isAllowed !
        
        // Execute command:
        DispatchQueue.mainIfNeeded {
            AppStoryboard.onboarding.instantiateWCAndPresent(from: nil, id: "PreferencesWCID", asMain: false, asKey: true) { wc in
                if let vc = wc.contentViewController as? PreferencesVC {
                    
                    // call completion
                    completion(.success("created \(vc.basicDesc)>"))
                } else {
                    completion(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading about screen.")))
                }
            }
        }
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: CommandReciever?) {
        self.receiver = receiver
        self.context = context
    }
}
