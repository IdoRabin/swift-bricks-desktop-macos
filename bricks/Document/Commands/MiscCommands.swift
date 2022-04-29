//
//  MiscCommands.swift
//  Bricks
//
//  Created by Ido on 13/01/2022.
//

import AppKit


class CmdUITogglePopupForToolbarNameView : DocCommand {

    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .misc
    static var keyboardShortcut : KeyboardShortcut = .empty
    static var buttonTitle: String = AppStr.SHOW_DOCNAME_POPUP.localized()
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.SHOW_DOCNAME_POPUP.localized()
    static var tooltipTitle : String? = AppStr.SHOW_DOCNAME_POPUP_TOOLTIP.localized()
    
    // MARK: Command properties
    let docID : BrickDocUID
    weak var receiver: CommandReciever?
    var context: CommandContext
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        guard let _ = reciever as? BrickDoc else {
            DLog.command["\(self)"]?.note("DocCommand not allowed for a non-doc reciever")
            return false
        }
        
        let result = [.execute, .redo, .undo].contains(method)
        return result
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        // NOTE: Invoker / external caller is assumed to be responsible to test isAllowed !
        
        // Execute command:
        DispatchQueue.mainIfNeeded {
            
            if let presentingVC = self.docWC?.docVC, self.docWC?.isCurentDocWC ?? false == true {
                
                func existingPopup()->ToolbarDocNamePopupVC? {
                    // Find existing window potpup:
                    return presentingVC.presentedViewControllers?.first(where: { vc in
                        vc is ToolbarDocNamePopupVC
                    }) as? ToolbarDocNamePopupVC
                }
                
                if let vc = existingPopup() {
                     // Hide popup
                    presentingVC.dismiss(vc)
                    DispatchQueue.main.asyncAfter(delayFromNow: 0.35) {
                        completion(.success(true))
                        self.docWC?.updateToolbarDocNameViewChevron()
                    }
                    
                } else if let vc = ToolbarDocNamePopupVC.safeLoadFromNib(name: "\(ToolbarDocNamePopupVC.self)"), let view = self.docWC?.docNameToolbarView {
                    
                    // Create and present popup
                    presentingVC.present(vc, asPopoverRelativeTo: view.frame, of: view, preferredEdge: NSRectEdge.maxY, behavior: .transient)
                    DispatchQueue.main.asyncAfter(delayFromNow: 0.25) {
                        completion(.success(true))
                        self.docWC?.updateToolbarDocNameViewChevron()
                    }
                } else {
                    self.dlog?.note("Failed loading ToolbarDocNamePopupVC from xib")
                    completion(.failure(AppError(AppErrorCode.cmd_failed_execute, detail: "Failed finding ToolbarDocNamePopupVC xib")))
                }
            } else {
                self.dlog?.note("Failed loading ToolbarDocNamePopupVC from xib")
                completion(.failure(AppError(AppErrorCode.cmd_failed_execute, detail: "Failed finding presentingVC")))
            }
        }
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
    }
}

class CmdUITogglePopupForToolbarLogFileView : DocCommand {
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .misc
    static var keyboardShortcut : KeyboardShortcut = .empty
    static var buttonTitle: String = AppStr.SHOW_LOG_FILE_POPUP.localized()
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.SHOW_LOG_FILE_POPUP.localized()
    static var tooltipTitle : String? = AppStr.SHOW_LOG_FILE_POPUP_TOOLTIP.localized()
    
    // MARK: Command properties
    let docID : BrickDocUID
    weak var receiver: CommandReciever?
    var context: CommandContext
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        guard let _ = reciever as? BrickDoc else {
            DLog.command["\(self)"]?.note("DocCommand not allowed for a non-doc reciever")
            return false
        }
        
        let result = [.execute, .redo, .undo].contains(method)
        return result
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        // NOTE: Invoker / external caller is assumed to be responsible to test isAllowed !
        
        // Execute command:
        DispatchQueue.mainIfNeeded {
            
            if let presentingVC = self.docWC?.docVC, self.docWC?.isCurentDocWC ?? false == true, let doc = self.doc {
                
                func existingPopup()->FileLogViewerVC? {
                    // Find existing window potpup:
                    return presentingVC.presentedViewControllers?.first(where: { vc in
                        vc is FileLogViewerVC
                    }) as? FileLogViewerVC
                }
                
                if let vc = existingPopup() {
                     // Hide popup
                    presentingVC.dismiss(vc)
                    DispatchQueue.main.asyncAfter(delayFromNow: 0.35) {
                        completion(.success(true))
                    }
                    
                } else if let vc = FileLogViewerVC.safeLoadFromNib(name: "\(FileLogViewerVC.self)"), let view = self.docWC?.mainPanelToolbarView {
                    
                    // Create and present popup
                    vc.findPreferredLoadWidthIfNeeded(window: self.docWC?.window)
                    vc.fileLog = doc.commandLog
                    presentingVC.present(vc, asPopoverRelativeTo: view.frame, of: view, preferredEdge: NSRectEdge.maxY, behavior: .transient)
                    DispatchQueue.main.asyncAfter(delayFromNow: 0.25) {
                        completion(.success(true))
                    }
                } else {
                    self.dlog?.note("Failed loading FileLogViewerVC from xib")
                    completion(.failure(AppError(AppErrorCode.cmd_failed_execute, detail: "Failed finding FileLogViewerVC xib")))
                }
            } else {
                self.dlog?.note("Failed loading FileLogViewerVC from xib")
                completion(.failure(AppError(AppErrorCode.cmd_failed_execute, detail: "Failed finding presentingVC")))
            }
        }
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
    }
}

