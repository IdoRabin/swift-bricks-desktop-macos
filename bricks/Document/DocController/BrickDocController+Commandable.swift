//
//  BrickDocController + Commandable.swift
//  Bricks
//
//  Created by Ido on 10/12/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDocController+Cmd")

extension BrickDocController : Commandable {
    func isAllowed(commandType: Command.Type) -> Bool {
        var result = true
        
        switch commandType as AnyObject {
        case is CmdAboutPanel.Type:
            result = !BricksApplication.shared.isViewControllerExistsOfClass(AboutVC.self)
        case is CmdPreferencesPanel.Type:
            result = true // !BricksApplication.shared.isViewControllerExistsOfClass(prefERENCESvc.self)
        default:
            result = true
        }
        return result
    }
    
    func isAllowed(command: Command) -> Bool {
        guard self.isAllowed(commandType: Swift.type(of: command) ) else {
            return false
        }
        
        var result = true
        
        switch command {
        case let _ as CmdAboutPanel:
            result = true
        case let _ as CmdPreferencesPanel:
            result = true
        default:
            result = true
        }
        return result
    }
    
    func sendToInvoker(command: Command, invoker: Invoker? = nil) {
        if self.isAllowed(command: command) {
            (invoker ?? self.commandInvoker).addCommand(command)
        } else {
            dlog?.warning("sendToInvoker \(Swift.type(of: command)) not allowed!")
        }
    }
    
    
}
