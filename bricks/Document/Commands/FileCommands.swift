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
    static weak var menuRepresentation: MNMenuItem? = nil
    
    func execute(compeltion: @escaping CommandResultBlock) {
        dlog?.info("execute")
        do {
            let doc = try BrickDocController.shared.openUntitledDocumentAndDisplay(true)
            
            // call completion
            compeltion(.success("created \(doc.basicDesc)"))
        } catch let error {
            dlog?.note("failed creating new document error:\(error.localizedDescription)")
            
            // call completion
            compeltion(.failure(AppError(AppErrorCode.doc_create_new_failed, detail: "openUntitledDocumentAndDisplay returned nil")))
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
    static weak var menuRepresentation: MNMenuItem? = nil
    
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
