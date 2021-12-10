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
        return true
    }
    
    func isAllowed(command: Command) -> Bool {
        guard self.isAllowed(commandType: Swift.type(of: command) ) else {
            return false
        }
        
        var result = true
        switch command {
        case let _ as CmdAboutPanel:
            result = false
        case let _ as CmdPreferencesPanel:
            result = false
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
