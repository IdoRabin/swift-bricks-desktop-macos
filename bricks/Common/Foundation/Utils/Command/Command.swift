//
//  Command.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("Command")

typealias CommandContext = String
typealias CommandResult = Result<Any, AppError>
typealias CommandResultBlock = (CommandResult)->Void
typealias CommandPayload = AnyHashable
typealias CommandUndoInfo = AnyHashable

enum CommandPayloadKey : String {
    case layerId
}

extension CommandResult {
    var value : Any? {
        switch self {
        case .success(let val): return val
        case .failure: return nil
        }
    }
    var error : AppError? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}

public enum CommandAllowed : Int, CustomStringConvertible {
    case unhandled = -1
    case notAllowed = 0
    case allowed = 1
    
    init(bool:Bool) {
        self.init(rawValue: bool ? 1 : 0)!
    }
    
    public var description: String {
        switch self {
        case .unhandled: return "CommandAllowed.unhandled"
        case .notAllowed: return "CommandAllowed.notAllowed"
        case .allowed: return "CommandAllowed.allowed"
        }
    }
    
    var asOptionalBool : Bool? {
        switch self {
        case .unhandled: return nil
        case .notAllowed: return false
        case .allowed: return true
        }
    }
    
    var asBool : Bool {
        return self == .allowed
    }
}


enum CommandExecutionMethod : Int, Equatable, Hashable {
    case execute
    case redo
    case undo
    
    var isUndo : Bool {
        return self == .undo
    }
    
    var isExecute : Bool {
        return self == .execute
    }
    
    var isRedo : Bool {
        return self == .redo
    }
    
    var isNotUndo : Bool {
        return self != .undo
    }
}

protocol CommandReciever :AnyObject {
    
    /// Returns whether a command is allowed to be performed / the user iterface item should be enabled
    /// - Parameters:
    ///   - commandType: command to be performed
    ///   - method: command method about to be performed
    ///   - context: context for this test
    /// - Returns:allowed state of the result, use .asBool to get true / false value
    func isAllowed(commandType: Command.Type, method:CommandExecutionMethod /* = .execute*/, context:CommandContext)->CommandAllowed
    
    /// Returns whether an action is allowed to be performed / the user iterface item should be enabled
    /// - Parameters:
    ///   - sel: selector to test if is allowed to perform
    ///   - context: context for the test being made
    /// - Returns:allowed state of the result, use .asBool to get true / false value.
    func isAllowedNativeAction(_ sel:Selector?, context:CommandContext)->Bool?
}

/// Based on GoF Command pattern
protocol Command {

    static var typeName : String { get }
    var typeName : String { get }
    
    /* weak */ var receiver : CommandReciever? { get }
    var context : CommandContext { get }
    var payload : CommandPayload? { get }
    var undoInfo : CommandUndoInfo? { get }
    var result : CommandResult? { get set}
    
    static func isAllowed(_ method:CommandExecutionMethod /* = .execute*/, context:CommandContext, reciever:CommandReciever?)->Bool
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
    
    var payload : CommandPayload? {
        return nil
    }
    
    var undoInfo : CommandUndoInfo? {
        return nil
    }
    
    var result : CommandResult? {
        get {
            return nil
        }
        set {
            
        }
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
