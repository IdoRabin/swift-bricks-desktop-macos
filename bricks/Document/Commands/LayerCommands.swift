//
//  LayerCommands.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import Foundation

protocol LayerCommand : DocCommand {
    var layerID:LayerUID? { get }
    func getLayerId(fromPayload:Bool, fromUndoInfo:Bool)->LayerUID?
}
extension LayerCommand /* default implementations */ {
    
    func getLayerId(fromPayload:Bool, fromUndoInfo:Bool)->LayerUID? {
        var result : LayerUID? = self.layerID
        if result == nil && fromPayload {
            if let payload = payload as? [String:AnyCodable] {
                result = payload["LayerId"] as? LayerUID
            } else if let layerId = payload as? LayerUID {
                result = layerId
            }
        }
        if result == nil && fromUndoInfo {
            if let undoInfo = undoInfo as? [String:AnyCodable] {
                result = undoInfo["LayerId"] as? LayerUID
            } else if let layerId = payload as? LayerUID {
                result = layerId
            }
        }
        return result
    }
}

class CmdLayerAdd : LayerCommand {
    
    
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
    var layerID:LayerUID? // saved after being created for undo
    var layerName:String? // saved after being created for undo
    var payload : [String:AnyCodable]? {
        var result : [String:AnyCodable] = [:]
        if let id = self.layerID {
            result["layerID"] = id
        }
        if let name = self.layerName {
            result["layerName"] = name
        }
        if result.count == 0 {
            return nil
        }
        return result
    }
    
    var undoInfo : CommandUndoInfo? {
        return self.payload
    }
    
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
        result = result && (doc.brick.layers.count < BrickLayers.MAX_LAYERS_ALLOWED)
        return result
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        guard let doc = doc else {
            completion(.failure(AppError(AppErrorCode.doc_layer_insert_failed, detail: "doc not found")))
            return
        }

        // NOTE: Invoker / external caller is assumed to be responsible to test isAllowed!
        
        // Execute command: CmdLayerAdd
        // Peform on receiver
        switch method {
        case .execute, .redo:
            let layerResult = doc.brick.layers.addLayer(id: self.layerID, name: self.layerName) // Will add a layer with "Untitled #" as title
            if let layer = layerResult.layers?.first {
                if self.layerID == nil {
                    self.layerID = layer.id
                }
                if self.layerName == nil {
                    self.layerName = layer.name
                }
                
                // Test / Log warning is needed.
                if IS_DEBUG {
                    if self.layerID == nil { dlog?.warning("addLayer perform:\(method) but did not get a layerID!") }
                }
            }
            
            let result = layerResult.asCommandResult
            
            if result.isSuccess == true {
                doc.setNeedsSaving(sender: self, context: "Add layer", propsAndVals: ["LayerID":layerResult.layers?.ids.descriptionsJoined ?? ""])
            }
            dlog?.info("Add layer result: \(result) payload:\(self.payload.descOrNil)")
            completion(result)
            
        case .undo:
            guard let layerId = layerID else {
                completion(.failure(AppError(AppErrorCode.doc_layer_insert_failed, detail: "layer id is nil")))
                return
            }
            
            // Perform undo if possible?
            let result = doc.brick.layers.removeLayers(ids: [layerId]).asCommandResult
            dlog?.info("Add layer (UNDO) result: \(result)")
            completion(result)
        }
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
        self.layerID = nil
    }
}


class CmdLayerEdit : LayerCommand {
    
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
    var layerID:LayerUID?
    var payload : [String:AnyCodable] = [:]
    var undoInfo : [String:AnyCodable] = [:]
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        guard let doc = reciever as? BrickDoc else {
            DLog.command["\(self)"]?.note("DocCommand not allowed for a non-doc reciever")
            return false
        }
        
        var result = [.execute, .redo, .undo].contains(method)
        result = result && (doc.brick.layers.selectedLayers.count == 1)
        return result
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        // NOTE: Invoker / external caller is assumed to be responsible to test isAllowed !

        guard let layerID = layerID else {
            completion(.failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "layer id not found")))
            return
        }
        guard let layers = doc?.brick.layers else {
            completion(.failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "layers container missing")))
            return
        }
        
        let dic : [String:AnyCodable] = method.isUndo ? self.undoInfo : self.payload
        
        guard dic.count > 0 else {
            completion(.failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "changes map is empty")))
            return
        }

        // Execute command: CmdLayerEdit
        // Execute or Undo info:
        
        // Chck if allowed, and apply edit
        var result = layers.isAllowedEdit(dic, layerID: layerID)
        if result.isSuccess {
            result = layers.applyEdit(dic, layerID: layerID)
        }
        
        completion(result)
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc, layerID:LayerUID) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
        self.layerID = layerID
    }
}


class CmdLayerRemove : LayerCommand {
    
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
    var layerID:LayerUID?
    /* from protocol */ var undoInfo : BrickLayer? = nil
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        guard let doc = reciever as? BrickDoc else {
            DLog.command["\(self)"]?.note("DocCommand not allowed for a non-doc reciever")
            return false
        }
        
        var result = [.execute, .redo, .undo].contains(method)
        result = result && (doc.brick.layers.selectedLayers.count == 1)
        return result
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        
        // Test self allows command:
        guard Self.isAllowed(method, context: context, reciever: receiver) else {
            completion(.failure(AppError(AppErrorCode.cmd_not_allowed_now, detail: "method: \(method) context: \(context)")))
            return
        }
        
        // Test receiver allows command:
        if let receiver = receiver, receiver.isAllowed(commandType: Self.self, method: method, context: context) == .notAllowed {
            completion(.failure(AppError(AppErrorCode.cmd_not_allowed_now, detail: "receiver: \(receiver) does not allow - method: \(method) context: \(context)")))
            return
        }
        guard let doc = doc else {
            completion(.failure(AppError(AppErrorCode.doc_layer_delete_failed, detail: "Failed removing layer with an unknwon doc")))
            return
        }
        
        guard let layerID = layerID else {
            completion(.failure(AppError(AppErrorCode.doc_layer_delete_failed, detail: "Failed removing layer because layerID is nil")))
            return
        }

        //  Execute command: CmdLayerRemove
        var cmdResult : CommandResult = .failure(AppError(AppErrorCode.doc_layer_delete_failed, detail: "Failed removing layer \(layerID) for an unknown reason"))
        switch method {
        case .execute, .redo:
            // Peform on receiver
            self.undoInfo = doc.brick.layers.layer(byId: layerID)
            cmdResult = doc.brick.layers.removeLayers(ids: [layerID]).asCommandResult
        case .undo:
            // Perform undo if possible?
            if let deletedLayer = self.undoInfo {
                cmdResult = doc.brick.layers.addLayers(layers: [deletedLayer]).asCommandResult
            } else {
                cmdResult = .failure(AppError(AppErrorCode.doc_layer_delete_failed, detail: "Failed restoring (undo for a remove) layer \(layerID). Undo info is missing."))
            }
        }
        
        if cmdResult.isSuccess {
            doc.setNeedsSaving(sender: self, context: context, propsAndVals: ["bricks.layers.layer":layerID.uuidString,
                                                                              "removed":"\(method)"], executionMehod: method)
        }
        
        completion(cmdResult)
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc, layerID:LayerUID) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
        self.layerID = layerID
    }
}

class CmdLayerSetAccess : LayerCommand {
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .layer
    static var keyboardShortcut : KeyboardShortcut = .empty
    static var buttonTitle: String = AppStr.LOCK.localized() // _UNLOCK_
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.LOCK.localized() // _UNLOCK_
    static var tooltipTitle : String? = AppStr.LOCK_SELECTED_LAYER_TOOLTIP.localized()
    
    // MARK: Command properties
    let docID : BrickDocUID
    weak var receiver: CommandReciever?
    var context: CommandContext
    var layerID:LayerUID?
    var lockStateToSet : BrickLayer.Access = .unlocked
    /* from protocol */ var undoInfo : BrickLayer.Access? = nil
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        guard let doc = reciever as? BrickDoc else {
            DLog.command["\(self)"]?.note("DocCommand not allowed for a non-doc reciever")
            return false
        }
        
        var result = [.execute, .redo, .undo].contains(method)
        result = result && (doc.brick.layers.selectedLayers.count > 0)
        return result
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        
        // Test self allows command:
        guard Self.isAllowed(method, context: context, reciever: receiver) else {
            completion(.failure(AppError(AppErrorCode.cmd_not_allowed_now, detail: "method: \(method) context: \(context)")))
            return
        }
        
        // Test receiver allows command:
        if let receiver = receiver, receiver.isAllowed(commandType: Self.self, method: method, context: context).asBool == false {
            completion(.failure(AppError(AppErrorCode.cmd_not_allowed_now, detail: "receiver: \(receiver) does not allow - method: \(method) context: \(context)")))
            return
        }
        
        guard let doc = doc else {
            completion(.failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "\(self): failed finding doc: \(self.docID)")))
            return
        }
        
        
        guard let layerID = layerID, let layer = doc.brick.layers.orderedLayers.first(id: layerID) else {
            completion(.failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "\(self): failed finding layer id:\(layerID.descOrNil) method: \(method) context: \(context)")))
            return
        }
        
        dlog?.info("set access: \(method) to:\(lockStateToSet)")
        var cmdResult : CommandResult = .failure(AppError(AppErrorCode.doc_layer_change_failed, detail:"\(self): failed for unknown reason"))
        
        // Execute command: CmdLayerSetAccess
        switch method {
        case .execute, .redo:
            // Peform on receiver
            undoInfo = layer.access
            cmdResult = doc.brick.layers.setLayersAccess(ids: [layerID], newAccessState: lockStateToSet).asCommandResult
        case .undo:
            // Perform undo if possible?
            if let prevState = (undoInfo ?? result?.value) as? BrickLayer.Access {
                cmdResult = doc.brick.layers.setLayersAccess(ids: [layerID], newAccessState: prevState).asCommandResult
            } else {
                cmdResult = .failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "\(self): failed finding previous state for UNDO id:\(layerID) method: \(method) context: \(context)"))
            }
        }
        
        // Set changed:
        if cmdResult.isSuccess {
            doc.setNeedsSaving(sender: self, context: context, propsAndVals: ["bricks.layers.layer":layerID.uuidString,
                                                                              "access":"\(layer.access)"], executionMehod: method)
        }
        completion(cmdResult)
        
        // Debugging: make sure change was applied to layer:
        //DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
        //    self.dlog?.info("newAccessState: \(layer.access) [\(layer.name ?? layer.id.uuidString)] result:\(self.result.descOrNil)")
        //}
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc, layerID:LayerUID, lockStateToSet newLockStt:BrickLayer.Access) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
        self.layerID = layerID
        self.lockStateToSet = newLockStt
        self.undoInfo = receiver.brick.layers.orderedLayers.first(id: layerID)?.access // current state
    }
}

class CmdLayerSetVisiblity : LayerCommand {
    
    // MARK: AppCommand required properties
    static var category : AppCommandCategory = .layer
    static var keyboardShortcut : KeyboardShortcut = .empty
    static var buttonTitle: String = AppStr.HIDE.localized()
    static var buttonImageName: String? = nil
    static var menuTitle: String? = AppStr.HIDE.localized()
    static var tooltipTitle : String? = AppStr.HIDE_SELECTED_LAYER_TOOLTIP.localized()
    
    // MARK: Command properties
    let docID : BrickDocUID
    weak var receiver: CommandReciever?
    var context: CommandContext
    var layerID:LayerUID?
    var visibilityStateToSet : BrickLayer.Visiblity = .hidden
    /* from protocol */ var undoInfo : BrickLayer.Visiblity? = nil
    
    // MARK: Command funcs
    static func isAllowed(_ method: CommandExecutionMethod, context: CommandContext, reciever: CommandReciever?) -> Bool {
        guard let doc = reciever as? BrickDoc else {
            DLog.command["\(self)"]?.note("DocCommand not allowed for a non-doc reciever")
            return false
        }
        
        var result = [.execute, .redo, .undo].contains(method)
        result = result && (doc.brick.layers.selectedLayers.count > 0)
        return result
    }
    
    func perform(method: CommandExecutionMethod, completion: @escaping CommandResultBlock) {
        
        // Test self allows command:
        guard Self.isAllowed(method, context: context, reciever: receiver) else {
            completion(.failure(AppError(AppErrorCode.cmd_not_allowed_now, detail: "method: \(method) context: \(context)")))
            return
        }
        
        // Test receiver allows command:
        if let receiver = receiver, receiver.isAllowed(commandType: Self.self, method: method, context: context).asBool == false {
            completion(.failure(AppError(AppErrorCode.cmd_not_allowed_now, detail: "receiver: \(receiver) does not allow - method: \(method) context: \(context)")))
            return
        }
        
        guard let doc = doc else {
            completion(.failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "\(self): failed finding doc: \(self.docID)")))
            return
        }
        
        guard let layerID = layerID, let layer = doc.brick.layers.orderedLayers.first(id: layerID) else {
            completion(.failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "\(self): failed finding layer id:\(layerID.descOrNil) method: \(method) context: \(context)")))
            return
        }
        
        dlog?.info("set visiblity: \(method) to: \(visibilityStateToSet)")
        var cmdResult : CommandResult = .failure(AppError(AppErrorCode.doc_layer_change_failed, detail:"\(self): failed for unknown reason"))
        
        // Execute command: CmdLayerSetVisibility
        switch method {
        case .execute, .redo:
            // Peform on receiver
            self.undoInfo = layer.visiblity
            cmdResult = doc.brick.layers.setLayersVisibility(ids: [layerID], newVisibilityState: visibilityStateToSet).asCommandResult
            
        case .undo:
            // Perform undo if possible?
            if let prevState = (self.undoInfo ?? result?.value) as? BrickLayer.Visiblity {
                cmdResult = doc.brick.layers.setLayersVisibility(ids: [layerID], newVisibilityState: prevState).asCommandResult
            } else {
                
                cmdResult = .failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "\(self): failed finding previous state for UNDO id:\(layerID) method: \(method) context: \(context)"))
            }
        }
        
        if cmdResult.isSuccess {
            doc.setNeedsSaving(sender: self, context: context, propsAndVals: ["bricks.layers.layer":layerID.uuidString,
                                                                              "visibility":"\(layer.visiblity)"], executionMehod: method)
        }
        completion(cmdResult)
        
        // Debugging: make sure change was applied to layer:
        //DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
        //    self.dlog?.info("newVisibilityState: \(layer.visiblity) [\(layer.name ?? layer.id.uuidString)] result:\(self.result.descOrNil)")
        //}
    }
    
    // MARK: Lifecycle
    required init(context: CommandContext, receiver: BrickDoc, layerID:LayerUID, visibilityStateToSet newVisStt:BrickLayer.Visiblity) {
        self.receiver = receiver
        self.docID = receiver.id
        self.context = context
        self.layerID = layerID
        self.visibilityStateToSet = newVisStt
        self.undoInfo = receiver.brick.layers.orderedLayers.first(id: layerID)?.visiblity // current state
    }
}
