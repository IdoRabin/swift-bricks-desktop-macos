//
//  FileCommands.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import AppKit

class CmdNewProject : AppCommand {
    static let category: AppCommandCategory = .file
    
    static var keyboardShortcut = KeyboardShortcut(modifiers: .command, chars: "n")
    static let buttonTitle: String = AppStr.NEW_PROJECT_DOT_DOT.localized()
    static let buttonImageName: String? = nil
    static let menuTitle: String? = AppStr.NEW_PROJECT_DOT_DOT.localized()
    static let tooltipTitle: String? = AppStr.START_A_NEW_PROJECT_DOT_DOT.localized()
    
    func execute(compeltion: @escaping CommandResultBlock) {
        dlog?.info("execute")
        AppStoryboard.document.instantiateWCAndPresent(from: nil, id: "DocumentWCID", asMain: true, asKey: true) { wc in
            if let vc = wc.contentViewController as? DocumentVC {
                // new document
                if let screen = wc.window?.screen {
                    let rect = screen.frame.boundsRect().insetBy(dx: screen.frame.width * 0.15, dy: screen.frame.height * 0.15).rounded()
                    wc.window?.setFrame(rect, display: false, animate: false)
                }
                
                // call completion
                compeltion(.success("<DocumentVC \(String(memoryAddressOf: vc))>"))
            } else {
                compeltion(.failure(AppError(AppErrorCode.misc_failed_loading, detail: "Failed loading about screen.")))
            }
        }
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
        dlog?.info("execute")
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
        dlog?.info("undo")
    }
}
