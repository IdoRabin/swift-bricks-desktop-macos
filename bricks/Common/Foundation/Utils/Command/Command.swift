//
//  Command.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import Foundation

typealias CommandResult = Result<Any, AppError>
typealias CommandResultBlock = (CommandResult)->Void

protocol Commandable {
    func isAllowed(commandType: Command.Type) -> Bool
    func isAllowed(command:Command)->Bool
    func sendToInvoker(command:Command, invoker:Invoker?)
}

protocol Command {
    func execute(compeltion: @escaping CommandResultBlock)
    func undo(compeltion: @escaping CommandResultBlock)
}
