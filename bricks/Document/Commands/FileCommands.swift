//
//  FileCommands.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import Foundation

class CmdAboutPanel : AppCommand {
    static let category: AppCommandCategory = .app
    
    static var keyboardShortcut = KeyboardShortcut.empty
    static let buttonTitle: String = AppStr.ABOUT_APP_FORMAT.formatLocalized(AppStr.PRODUCT_NAME.localized())
    static let buttonImageName: String? = nil
    static let menuTitle: String? = AppStr.ABOUT_APP_FORMAT.formatLocalized(AppStr.PRODUCT_NAME.localized())
    static let tooltipTitle: String? = AppStr.ABOUT.localized()
    
    func execute(compeltion: @escaping CommandResultBlock) {
        dlog?.info("execute")
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
    }
    
    func undo(compeltion: @escaping CommandResultBlock) {
        dlog?.info("undo")
    }
}

class CmdNewProject : AppCommand {
    static let category: AppCommandCategory = .file
    
    static var keyboardShortcut = KeyboardShortcut(modifiers: .command, chars: "n")
    static let buttonTitle: String = AppStr.NEW_PROJECT_DOT_DOT.localized()
    static let buttonImageName: String? = nil
    static let menuTitle: String? = AppStr.NEW_PROJECT_DOT_DOT.localized()
    static let tooltipTitle: String? = AppStr.START_A_NEW_PROJECT_DOT_DOT.localized()
    
    func execute(compeltion: @escaping CommandResultBlock) {
        dlog?.info("execute")
    }
    
    func undo(compeltion: @escaping CommandResultBlock) {
        dlog?.info("undo")
    }
}

class CmdOpenProject : AppCommand {
    static let category: AppCommandCategory = .file
    
    static var keyboardShortcut = KeyboardShortcut(modifiers: .command, chars: "n")
    static let buttonTitle: String = AppStr.OPEN_PROJECT_DOT_DOT.localized()
    static let buttonImageName: String? = nil
    static let menuTitle: String? = AppStr.OPEN_PROJECT_DOT_DOT.localized()
    static let tooltipTitle: String? = AppStr.OPEN_AN_EXISTING_PROJECT_DOT_DOT.localized()
    
    func execute(compeltion: @escaping CommandResultBlock) {
        
        BrickDocController.shared.beginOpenPanel { (urls) in
            self.dlog?.info("open panel closed with \(urls?.description ?? "< no urls>" )")
            if let urls = urls, urls.count > 0 {
                compeltion(.success(urls))
            } else {
                compeltion(.failure(AppError(AppErrorCode.misc_operation_canceled, detail: "beginOpenPanel canceled or failed")))
            }
            
        }
    }
    
    func undo(compeltion: @escaping CommandResultBlock) {
        
    }
}
