//
//  BrickDocController + CmdReceiver.swift
//  Bricks
//
//  Created by Ido on 10/12/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDocController+Cmd")

extension BrickDocController : CommandReciever {
    
    func enqueueCommand(_ command: AppCommand) {
        self.enqueueCommands([command])
    }
    
    func enqueueCommands(_ commands: [AppCommand]) {
        self.commandInvoker.addCommands(commands)
    }
    
    func isAllowed(commandType: Command.Type, method: CommandExecutionMethod = .execute, context: CommandContext) -> CommandAllowed {
        var result : CommandAllowed = .unhandled
        let doc = self.curDoc
        let hasDoc = doc != nil
        
        var isNeedsSaving = doc?.brick.isNeedsSaving ?? false
        if isNeedsSaving == false, let doc = doc, doc.isDraft == false, doc.isDocumentEdited || doc.hasUnautosavedChanges {
            isNeedsSaving = true
        }
        
        DispatchQueue.main.safeSync {
            switch commandType.typeName {
                
            // All singly instanced VCs / Util vcs are always allowed because the implementation will just bring to front the single intance, and never create a new instance.
            
            // App menu
            case CmdSplashWindow.typeName:      result = .allowed // !BricksApplication.shared.isViewControllerExistsOfClass(SplashVC.self)
            case CmdAboutPanel.typeName:        result = .allowed // !BricksApplication.shared.isViewControllerExistsOfClass(AboutVC.self)
            case CmdPreferencesPanel.typeName:  result = .allowed // !BricksApplication.shared.isViewControllerExistsOfClass(PreferencesVC.self)
            
            // File menu
            case CmdNewProject.typeName:        result = .allowed
            case CmdOpenProject.typeName:       result = .allowed
            //case CmdSaveProject.typeName:       result = isNeedsSaving
            //case CmdSaveProjectAs.typeName:     result = isNeedsSaving
                
            // Layer menu: (only when we have a cur doc)
            case CmdLayerAdd.typeName:          result = CommandAllowed(bool: hasDoc)
            case CmdLayerEdit.typeName, CmdLayerRemove.typeName, CmdLayerSetAccess.typeName, CmdLayerSetVisiblity.typeName:
                result = doc?.isAllowed(commandType: commandType, method: method, context: context) ?? .notAllowed
            default:
                dlog?.note("did not handle command of type [\(commandType.typeName)]")
                break
            }
        }
        
        // dlog?.info("isAllowed=\(result) command: \(commandType.typeName) for: \(method) context: \(context)")
        return result
    }
    
    func isAllowedNativeAction(_ sel: Selector?, context: CommandContext) -> Bool? {
        guard let sel = sel else {
            dlog?.info("isAllowedNativeAction failed with a nil selector! context: \(context)")
            return false
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

extension BrickDocController /* command factory */ {
    
    @discardableResult
    func createCommand( _ cmdType : AppCommand.Type, context:CommandContext, isEnqueue:Bool = true, setup:((_ cmd: AppCommand)->Void)? = nil)->AppCommand? {
        var result : AppCommand? = nil
        switch cmdType {
        // App menu
        case is CmdSplashWindow.Type:       result = CmdSplashWindow(context: context, receiver: self, showsRecents: AppDocumentHistory.shared.hasRecents)
        case is CmdAboutPanel.Type:         result = CmdAboutPanel(context: context, receiver: self)
        case is CmdPreferencesPanel.Type:   result = CmdPreferencesPanel(context: context, receiver: self)
        
        // File menu
        case is CmdNewProject.Type:         result = CmdNewProject(context: context, receiver: self)
        case is CmdOpenProject.Type:        result = CmdOpenProject(context: context, receiver: self)
        
        // Layers menu
//        case is CmdLayerAdd.Type:
//        case is CmdLayerEdit.Type:
//        case is CmdLayerRemove.Type:
            
        default:
            dlog?.note("Controller createCommand for [\(cmdType)] was not implemented!")
        }
        
        if let result = result {
            
            setup?(result)
            
            if Debug.IS_DEBUG && self.commandInvoker.state.isPaused {
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

// Should typically respond and handle only App Commands:
extension BrickDocController : CommandInvokerObserver {
    func commandInvoker(_ invoker: CommandInvoker, didPerformCommand command: Command, method: CommandExecutionMethod, result: CommandResult) {
        
        // Should typically respond and handle only App Commands:
        guard let appCmd = command as? AppCommand else {
            return
        }
        
        let cmdType = Swift.type(of: appCmd)
        
        DispatchQueue.main.async {
            self.invalidateItemsForCommands([cmdType])
        }
    }
}
