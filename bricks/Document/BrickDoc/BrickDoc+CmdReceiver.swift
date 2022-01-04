//
//  BrickDoc+CmdReceiver.swift
//  Bricks
//
//  Created by Ido on 03/01/2022.
//
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDoc+Cmd")

extension BrickDoc : CommandReciever {
    
    func enqueueCommand(_ command: DocCommand) {
        self.enqueueCommands([command])
    }
    
    func enqueueCommands(_ commands: [DocCommand]) {
        self.commandInvoker.addCommands(commands)
    }
    
    func isAllowed(commandType: Command.Type, method: CommandExecutionMethod = .execute, context: CommandContext) -> Bool {
        var result = false
        
        DispatchQueue.main.safeSync {
            switch commandType.typeName {
            case CmdLayerAdd.typeName:        result = true
            case CmdLayerEdit.typeName:       result = self.brick.layers.selectedLayer != nil
            case CmdLayerRemove.typeName:     result = self.brick.layers.selectedLayer != nil
            default:
                break
            }
        }
        
        // dlog?.info("isAllowed=\(result) command: \(commandType.typeName) for: \(method) context: \(context)")
        return false
    }
    
    func isAllowedNativeAction(_ sel: Selector?, context: CommandContext) -> Bool? {
        guard let sel = sel else {
            dlog?.info("isAllowedNativeAction failed with a nil selector! context: \(context)")
            return nil
        }
        
        var result : Bool? = nil
        let seelctorStr = "\(sel)"
        switch seelctorStr {
        case "toggleSidebarAction:": result = true
        default:
            result = nil
        }
        
        /*
        if let res = result {
            dlog?.successOrFail(condition: res, items: "isAllowedNativeAction: \(sel) context: \(context)")
        } else {
            dlog?.note("isAllowedNativeAction not implemented for: \(seelctorStr)")
        }*/
        
        return result
    }
}

extension BrickDoc /* command factory */ {
    
    @discardableResult
    func createCommand( _ cmdType : DocCommand.Type, context:CommandContext, isEnqueue:Bool = true, setup:((_ cmd: DocCommand)->Void)? = nil)->DocCommand? {
        var result : DocCommand? = nil
        let selectedLyerUID : LayerUID? = nil
        
        switch cmdType {
        // App menu
        // Layers menu
        case is CmdLayerAdd.Type:       result = CmdLayerAdd(context: context, receiver: self)
        case is CmdLayerEdit.Type:      result = CmdLayerEdit(context: context, receiver: self, layerID: selectedLyerUID!)
        case is CmdLayerRemove.Type:    result = CmdLayerRemove(context: context, receiver: self, layerID: selectedLyerUID!)
            
        default:
            dlog?.note("createCommand for [\(cmdType)] was not implemented!")
        }
        
        if let result = result {
            
            setup?(result)
            
            if IS_DEBUG && self.commandInvoker.state.isPaused {
                dlog?.info("createCommand: Note that the invoker is paused!")
            }
        } else {
            dlog?.note("createCommand failed creating or enqueueing command \(cmdType)")
        }
        
        if isEnqueue, let cmd = result {
            self.enqueueCommand(cmd)
        }
        return result
    }
}
