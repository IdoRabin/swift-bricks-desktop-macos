//
//  LayerCommands.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import Foundation

class CmdLayerAdd : DocCommand {
    
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .layer
    static var keyboardShortcut : KeyboardShortcut = .empty
    static var buttonTitle: String = AppStr.ADD_NEW.localized()
    static var buttonImageName: String? = "plus"
    static var menuTitle: String? = AppStr.ADD_NEW.localized()
    static var tooltipTitle : String? = AppStr.ADD_NEW_PLAN_LAYER_TOOLTIP.localized()
    
    // MARK: Command properties
    let docID : BrickDocUID
    weak var receiver: CommandReciever?
    var context: CommandContext
    var layerId:LayerUID? // saved after being created for undo
    
    var doc: BrickDoc? {
        if let receiver = receiver as? BrickDoc {
            return receiver
        } else {
            let doc = BrickDocController.shared.document(for: docID)
            receiver = doc
            return doc
        }
    }
    
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        guard let doc = reciever as? BrickDoc else {
            DLog.command["\(self)"]?.note("DocCommand not allowed for a non-doc reciever")
            return false
        }
        
        var result = [.execute, .redo, .undo].contains(method)
        result = result && (doc.brick.layers.orderedLayers.count < BrickLayers.MAX_LAYERS_ALLOWED)
        return result
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
//        switch method {
//        case .execute, .redo:
//            // Peform on receiver
//            // ... completion(...)
//        case .undo:
//            // Perform undo if possible?
//            // ... completion(...)
//        }
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
        self.layerId = nil
    }
}


class CmdLayerEdit : DocCommand {
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .layer
    static var keyboardShortcut : KeyboardShortcut = .empty
    static var buttonTitle: String =  AppStr.EDIT.localized()
    static var buttonImageName: String? = "pencil"
    static var menuTitle: String? = AppStr.EDIT.localized()
    static var tooltipTitle : String? = AppStr.EDIT_SELECTED_LAYER_TOOLTIP.localized()
    
    // MARK: Command properties
    let docID : BrickDocUID
    weak var receiver: CommandReciever?
    var context: CommandContext
    var layerId:LayerUID
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        guard let doc = reciever as? BrickDoc else {
            DLog.command["\(self)"]?.note("DocCommand not allowed for a non-doc reciever")
            return false
        }
        
        var result = [.execute, .redo, .undo].contains(method)
        result = result && doc.brick.layers.selectedLayer != nil
        return result
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
//        switch method {
//        case .execute, .redo:
//            // Peform on receiver
//            // ... completion(...)
//        case .undo:
//            // Perform undo if possible?
//            // ... completion(...)
//        }
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc, layerID:LayerUID) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
        self.layerId = layerID
    }
}


class CmdLayerRemove : DocCommand {
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .layer
    static var keyboardShortcut : KeyboardShortcut = .empty
    static var buttonTitle: String = AppStr.DELETE.localized()
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.DELETE.localized()
    static var tooltipTitle : String? = AppStr.DELETE_SELECTED_LAYER_FROM_PLAN_TOOLTIP.localized()
    
    // MARK: Command properties
    let docID : BrickDocUID
    weak var receiver: CommandReciever?
    var context: CommandContext
    var layerId:LayerUID
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        guard let doc = reciever as? BrickDoc else {
            DLog.command["\(self)"]?.note("DocCommand not allowed for a non-doc reciever")
            return false
        }
        
        var result = [.execute, .redo, .undo].contains(method)
        result = result && doc.brick.layers.selectedLayer != nil
        return result
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
//        switch method {
//        case .execute, .redo:
//            // Peform on receiver
//            // ... completion(...)
//        case .undo:
//            // Perform undo if possible?
//            // ... completion(...)
//        }
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc, layerID:LayerUID) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
        self.layerId = layerID
    }
}
//class CmdLayerRemove : DocCommand {

//    required init(docID: BrickDocUID, layerID:LayerUID) {
//        self.docID = docID
//        self.layerID = layerID
//    }
//
//    func execute(compeltion: @escaping CommandResultBlock) {
//        dlog?.todo("implement execute()")
//    }
//
//    func undo(compeltion: @escaping CommandResultBlock) {
//        dlog?.todo("implement undo()")
//    }
//}
