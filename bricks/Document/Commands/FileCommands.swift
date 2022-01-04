//
//  FileCommands.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import AppKit

class CmdNewProject : AppCommand {
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .file
    static var keyboardShortcut : KeyboardShortcut = KeyboardShortcut(modifiers: .command, chars: "n")
    static var buttonTitle: String = AppStr.NEW_PROJECT_DOT_DOT.localized()
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.NEW_PROJECT_DOT_DOT.localized()
    static var tooltipTitle : String? = AppStr.START_A_NEW_PROJECT_DOT_DOT.localized()
    
    // MARK: Command properties
    weak var receiver: CommandReciever?
    var context: CommandContext
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        let result = [.execute, .redo].contains(method)
        return result // undo not allowed
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        
        // Test self allows command:
        guard Self.isAllowed(method, context: context, reciever: receiver) else {
            completion(.failure(AppError(AppErrorCode.cmd_not_available_now, detail: "method: \(method) context: \(context)")))
            return
        }
        
        // Test receiver allows command:
        if let receiver = receiver, receiver.isAllowed(commandType: Self.self, method: method, context: context) == false {
            completion(.failure(AppError(AppErrorCode.cmd_not_available_now, detail: "receiver: \(receiver) does not allow - method: \(method) context: \(context)")))
            return
        }
        
        DispatchQueue.mainIfNeeded {[self] in
            // Execute command:
            do {
                let doc = try BrickDocController.shared.openUntitledDocumentAndDisplay(true)
                
                // call completion
                completion(.success("created \(doc.basicDesc)"))
            } catch let error {
                dlog?.note("failed creating new document error:\(error.localizedDescription)")
                
                // call completion
                completion(.failure(AppError(AppErrorCode.doc_create_new_failed, detail: "openUntitledDocumentAndDisplay returned nil")))
            }
        }
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: CommandReciever?) {
        self.receiver = receiver
        self.context = context
    }
}

class CmdOpenProject : AppCommand {
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .file
    static var keyboardShortcut : KeyboardShortcut = KeyboardShortcut(modifiers: .command, chars: "n")
    static var buttonTitle: String = AppStr.OPEN_PROJECT_DOT_DOT.localized()
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.OPEN_PROJECT_DOT_DOT.localized()
    static var tooltipTitle : String? = AppStr.OPEN_AN_EXISTING_PROJECT_DOT_DOT.localized()
    
    // MARK: Command properties
    weak var receiver: CommandReciever?
    var context: CommandContext
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        let result = [.execute, .redo].contains(method)
        return result // undo not allowed
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        
        // Test self allows command:
        guard Self.isAllowed(method, context: context, reciever: receiver) else {
            completion(.failure(AppError(AppErrorCode.cmd_not_available_now, detail: "method: \(method) context: \(context)")))
            return
        }
        
        // Test receiver allows command:
        if let receiver = receiver, receiver.isAllowed(commandType: Self.self, method: method, context: context) == false {
            completion(.failure(AppError(AppErrorCode.cmd_not_available_now, detail: "receiver: \(receiver) does not allow - method: \(method) context: \(context)")))
            return
        }
        
        // Execute command:
        DispatchQueue.mainIfNeeded {
            BrickDocController.shared.beginOpenPanel { (urls) in
                self.dlog?.info("open panel closed with \(urls?.description ?? "< no urls>" )")
                if let urls = urls, urls.count > 0 {
                    completion(.success(urls))
                } else {
                    completion(.failure(AppError(AppErrorCode.misc_operation_canceled, detail: "beginOpenPanel canceled or failed")))
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
