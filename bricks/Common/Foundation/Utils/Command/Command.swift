//
//  Command.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import Foundation

typealias CommandContext = String
typealias CommandPayload = (reciever:Any, context:String)
typealias CommandResult = Result<Any, AppError>
typealias CommandResultBlock = (CommandResult)->Void

enum CommandExecutionMethod : Int, Equatable, Hashable {
    case execute
    case redo
    case undo
}

protocol CommandReciever :AnyObject {
    
    /// Returns whether a command is allowed to be performed / the user iterface item should be enabled
    /// - Parameters:
    ///   - commandType: command to be performed
    ///   - method: command method about to be performed
    ///   - context: context for this test
    /// - Returns: true if command is allowed to execute, or false if currently prohibited.
    func isAllowed(commandType: Command.Type, method:CommandExecutionMethod /* = .execute*/, context:CommandContext)->Bool
    
    /// Returns whether an action is allowed to be performed / the user iterface item should be enabled
    /// - Parameters:
    ///   - sel: selector to test if is allowed to perform
    ///   - context: context for the test being made
    /// - Returns: true or false if the test for this action is handled here, otherwise, nil
    func isAllowedNativeAction(_ sel:Selector?, context:CommandContext)->Bool?
}

/// Based on GoF Command pattern
protocol Command {

    static var typeName : String { get }
    var typeName : String { get }
    
    /* weak */ var receiver : CommandReciever? { get }
    var context : CommandContext { get }
    
    static func isAllowed(_ method:CommandExecutionMethod /* = .execute*/ , context:CommandContext, reciever:CommandReciever?)->Bool
    func perform(method:CommandExecutionMethod, completion:@escaping CommandResultBlock)
    
    func execute(completion:@escaping CommandResultBlock)
    func redo(completion:@escaping CommandResultBlock)
    func undo(completion:@escaping CommandResultBlock)
}

extension Command {
    static var typeName : String {
        return "\(self)"
    }
    
    var typeName : String {
        return Self.typeName
    }
    
    func execute(completion:@escaping CommandResultBlock) {
        self.perform(method: .execute, completion: completion)
    }
    
    func redo(completion:@escaping CommandResultBlock) {
        self.perform(method: .redo, completion: completion)
    }
    
    func undo(completion:@escaping CommandResultBlock) {
        self.perform(method: .undo, completion: completion)
    }
    
    static func isAllowed(_ method:CommandExecutionMethod /* = .execute*/ , context:CommandContext, reciever:CommandReciever?)->Bool {
        return [.execute, .redo].contains(method)
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
