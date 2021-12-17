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
    
    var typeName : String { get }
    static var typeName : String { get }
}

extension Command {
    static var typeName : String {
        return "\(self)"
    }
    var typeName : String {
        return "\(type(of: self))"
    }
}

extension Array where Element : Command {
    var typeNames : [String] {
        return self.map { cmd in
            return cmd.typeName
        }
    }
}

extension Array where Element == Command.Type {
    var typeNames : [String] {
        return self.map { cmd in
            return cmd.typeName
        }
    }
}
