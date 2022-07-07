//
//  BrickDoc+CmdReceiver.swift
//  Bricks
//
//  Created by Ido on 03/01/2022.
//
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDoc+Cmd")

extension BrickDoc : CommandReciever {
    
    enum isAllowedResult : Int {
        case unknown = -1
        case notAllowed = 0
        case allowed = 1
        
        var asOptionalBool : Bool? {
            switch self {
            case .notAllowed:
                return false
            case .allowed:
                return true
            case .unknown:
                fallthrough
            default:
                return nil
            }
        }
    }
    func enqueueCommand(_ command: DocCommand) {
        self.enqueueCommands([command])
    }
    
    func enqueueCommands(_ commands: [DocCommand]) {
        self.docCommandInvoker.addCommands(commands)
    }
    
    func isAllowed(commandType: Command.Type, method: CommandExecutionMethod = .execute, context: CommandContext) -> CommandAllowed {
        var aresult : CommandAllowed = .unhandled
        
        let layersCount = self.brick.layers.count
        let selLayersCount = self.brick.layers.selectedLayers.count
        
        DispatchQueue.main.safeSync {
            switch commandType.typeName {
            case CmdLayerAdd.typeName:          aresult = .allowed
            case CmdLayerEdit.typeName:         aresult = CommandAllowed(bool:selLayersCount == 1)
            case CmdLayerRemove.typeName:       aresult = CommandAllowed(bool:selLayersCount > 0)
            case CmdLayerEdit.typeName:         aresult = CommandAllowed(bool:selLayersCount == 1)
            case CmdLayerSetAccess.typeName:    aresult = CommandAllowed(bool:layersCount > 0)
            case CmdLayerSetVisiblity.typeName: aresult = CommandAllowed(bool:layersCount > 0)
            default:
                break
            }
        }
        
        // dlog?.info("isAllowed=\(result) command: \(commandType.typeName) for: \(method) context: \(context)")
        return aresult
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
    
    // MakeCommand // MakeCmd
    @discardableResult
    func createCommand( _ cmdType : DocCommand.Type, context:CommandContext, isEnqueue:Bool = true, setup:((_ cmd: DocCommand)->Void)? = nil)->DocCommand? {
        var result : DocCommand? = nil
        let selectedLyerUID : LayerUID? = self.brick.layers.selectedLayers.first?.id
        
        switch cmdType {
        // App menu
        // Layers menu
        case is CmdLayerAdd.Type:       result = CmdLayerAdd(context: context, receiver: self)
            
            // These will crash if there is no selected layer: should not have allowed the UI that triggers this if no layer is selected.
        case is CmdLayerEdit.Type:      result = CmdLayerEdit(context: context, receiver: self, layerID: selectedLyerUID!)
        case is CmdLayerRemove.Type:    result = CmdLayerRemove(context: context, receiver: self, layerID: selectedLyerUID!)
            
        // Misc
        case is CmdUITogglePopupForToolbarNameView.Type:    result = CmdUITogglePopupForToolbarNameView(context: context, receiver: self)
        case is CmdUITogglePopupForToolbarLogFileView.Type:    result = CmdUITogglePopupForToolbarLogFileView(context: context, receiver: self)
            
        default:
            dlog?.note("createCommand for [\(cmdType)] was not implemented!")
        }
        
        if let result = result {
            
            setup?(result)
            
            if Debug.IS_DEBUG && self.docCommandInvoker.state.isPaused {
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
