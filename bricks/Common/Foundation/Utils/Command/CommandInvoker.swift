//
//  CommandInvoker.swift
//  grafo
//
//  Created by Ido on 09/07/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("CommandInvoker")

enum InvokerState {
    case paused
    case active
    
    var isPaused : Bool {
        return self == .paused
    }
    
    var isActive : Bool {
        return self == .active
    }
}

protocol CommandInvokerObserver {
    func commandInvoker(_ invoker:CommandInvoker, didPerformCommand:Command, method: CommandExecutionMethod, result:CommandResult)
}

/// Based on GoF invoker pattern
protocol CommandInvoker {
    var state : InvokerState { get }
    func addCommands(_ commands: [Command])
    func addCommand(_ command: Command)
    func pause()->Bool
    func resume()->Bool
}

fileprivate class CommandWrapper {

    let command : Command
    var executionType : CommandExecutionMethod?
    var result : CommandResult? = nil
    var executionDate : Date? = nil
    
    init(command newCommand:Command,
         executionType newExecutionType:CommandExecutionMethod = .execute,
         result newResult:CommandResult? = nil,
         executionDate newExecutionDate:Date? = nil) {
        
        // init:
        command = newCommand
        executionType = newExecutionType
        result = newResult
        executionDate = newExecutionDate
    }
    
    var isSucces : Bool {
        if self.executionDate != nil, let result = result {
            switch result {
            case .success:
                return true
            case .failure:
                return false
            }
        }
        return false
    }
    
    private func perform(_ method:CommandExecutionMethod, compeltion: CommandResultBlock? = nil) {
        command.perform(method: method) {[self] aresult in
            executionType = method
            executionDate = Date()
            result = aresult
            compeltion?(aresult)
        }
    }
    
    func redo (compeltion: CommandResultBlock? = nil) {
        self.perform(.redo, compeltion: compeltion)
    }
    
    func execute(compeltion: CommandResultBlock? = nil) {
        self.perform(.execute, compeltion: compeltion)
    }
    
    func undo(compeltion: CommandResultBlock? = nil) {
        self.perform(.undo, compeltion: compeltion)
    }
}

/// Based on GoF invoker pattern
class QueuedInvoker : CommandInvoker {

    static let MAX_BATCH_SIZE = 127
    
    enum QueueType {
        case toExecute
        case finished
        case failed
        case undoed
        
        static var all : [QueueType] = [.toExecute, .finished, .failed, .undoed]
        
        fileprivate var asCommandExecutionMethod : CommandExecutionMethod {
            switch self {
            case .toExecute: return .execute
            case .finished:  return .undo
            case .failed:    return .redo
            case .undoed:    return .execute
            }
        }
    }
    
    // MARK: Vars
    public var observers = ObserversArray<CommandInvokerObserver>()
    private var queues : [QueueType:[CommandWrapper]] = [:]
    private var dispatchQueue : DispatchQueue
    
    // MARK: Properties
    private var _state : InvokerState = .paused
    var state: InvokerState {
        get {
            var result : InvokerState = .paused
            dispatchQueue.safeSync {[self] in
                result = _state
            }
            return result
        }
        set {
            dispatchQueue.safeSync {[self] in
                if _state != newValue {
                    _state = newValue
                }
            }
        }
    }
    private(set) var name : String  = ""
    
    fileprivate subscript(type: QueueType) -> [CommandWrapper] {
        get {
            // Return an appropriate subscript value here.
            var result : [CommandWrapper] = []
            dispatchQueue.safeSync {[self] in
                result = queues[type] ?? []
            }
            return result
        }
        set {
            // Perform a suitable setting action here.
            dispatchQueue.safeSync {[self] in
                queues[type] = newValue
            }
        }
    }
    
    // MARK: Private funcs
    private func invokeOnlyOne() {
        invoke(batchSize: 1)
    }
    
    private func invokeAll() {
        invoke(batchSize: nil)
    }
    
    private func addCommands(_ commands:[Command], atQueueTop:Bool = false) {
        dispatchQueue.asyncIfNeeded {[self] in
            var toBeExecuted = queues[.toExecute] ?? []
            
            let wrappers = commands.map { command in
                return CommandWrapper(command: command)
            }
            if atQueueTop {
                toBeExecuted.insert(contentsOf: wrappers, at: 0)
            } else {
                toBeExecuted.append(contentsOf: wrappers)
            }
            
            queues[.toExecute] = toBeExecuted
            
            invokeAll()
        }
    }
    
    // MARK: Private actual execution of the commands.
    private func executeCommandWrapper(_ wrapper:CommandWrapper, queueType:QueueType, completion:@escaping CommandResultBlock) {
        
        var targetQueueType : QueueType = .finished
        let newWrapper = CommandWrapper(command: wrapper.command, executionType: queueType.asCommandExecutionMethod)
        
        func finalize(result:CommandResult) {
            // Result
            wrapper.executionDate = newWrapper.executionDate
            wrapper.result = newWrapper.result
            
            if newWrapper.result?.isFailed ?? true || result.isFailed {
                self[.failed].append(newWrapper)
            } else {
                self[targetQueueType].append(newWrapper)
            }
            
            // Notify observers
            self.observers.enumerateOnMainThread { observer in
                observer.commandInvoker(self, didPerformCommand: newWrapper.command, method: newWrapper.executionType ?? .execute, result: result)
            } completed: {
                // Call completion afte all observers
                completion(result)
            }
        }
        
        switch queueType {
        case .toExecute:
            // Execute command - items come from .toExecute array and behave like any other execute
            targetQueueType = .finished
            newWrapper.execute(compeltion: { result in
                finalize(result:result)
            })
            
        case .finished:
            // Undo command - items come from .finished array and behave like undo
            targetQueueType = .undoed
            newWrapper.undo(compeltion: { result in
                finalize(result:result)
            })
            
        case .failed:
            // Retry command - items come from .failed array and behave like any other execute
            targetQueueType = .finished
            newWrapper.execute(compeltion: { result in
                finalize(result:result)
            })
            
        case .undoed:
            // Redo command - items come from .undoed array and behave like any other execute
            targetQueueType = .finished
            newWrapper.redo(compeltion: { result in
                finalize(result:result)
            })
        }
    }
    
    private func internal_executeItems(queueType:QueueType, items:[CommandWrapper], depth:Int, total:Int, completion:@escaping ()->Void) {
        dispatchQueue.asyncIfNeeded {[self] in
            guard depth < Self.MAX_BATCH_SIZE else {
                dlog?.warning("internal_executeItems executed more than \(Self.MAX_BATCH_SIZE) commands in one batch!")
                completion()
                return
            }
            
            if let first = items.first {
                self.executeCommandWrapper(first, queueType: queueType) { result in
                    // Next command
                    if self._state.isActive {
                        self.internal_executeItems(queueType: queueType, items: items.removing(at: 0), depth: depth + 1, total: total, completion: completion)
                    } else {
                        dlog?.note("internal_executeItems cannot execute: state is not active.")
                    }
                }
            } else {
                completion()
            }
        }
    }
    
//    guard self.state.isActive else {
//        dlog?.note("internal_executeItems cannot execute: state is not active.")
//        completion()
//        return
//    }
    
    private func executeItems(queueType:QueueType, items:[CommandWrapper], completion:@escaping ()->Void) {
        internal_executeItems(queueType: queueType, items: items, depth: 0, total: items.count, completion: completion)
    }
    
    /*
    private func executeQueue(queueType:QueueType, amount:Int? = nil, completion:@escaping ()->Void) {
        guard amount ?? -99 < Self.MAX_BATCH_SIZE else {
            dlog?.warning("executeQueue trying to execute more than \(Self.MAX_BATCH_SIZE) commands in one batch!")
            completion()
            return
        }
        
        // FIFO
        var queueArr = self[queueType]
        if queueArr.count > 0 {
            var commandsToDo : [CommandWrapper] = []
            if let amount = amount {
                // will execute first amount items
                let amt = min(amount, queueArr.count)
                commandsToDo.append(contentsOf: queueArr.prefix(amt))
                queueArr.removeFirst(amt)
            } else {
                // empty the queue our, will execute all items
                commandsToDo = Array(queueArr)
                queueArr = []
            }
            
            // Setting the new queue array value to be witnout these commands
            self[queueType] = queueArr
            
            // Execute:
            if commandsToDo.count > 0 {
                self.executeItems(queueType: queueType, items: commandsToDo, completion: completion)
            } else {
                completion()
            }
        }
    }
    */
    
    // MARK: Lifecycle
    init(name newName:String) {
        name = newName
        dispatchQueue = DispatchQueue(label:"invoker.\(newName.lowercased().replacingOccurrences(of: .whitespacesAndNewlines, with: "."))")
        self.state = .active
    }
    
    // MARK: Public funcs
    
    private func isCanExecute(_ command:Command)->Bool {
        // dispatchQueue.asyncIfNeeded {[self] in ??
        return true
    }
    
    // MARK: Invoker
    func addCommand(_ command:Command) {
        self.addCommands([command])
    }
    
    func addCommands(_ commands:[Command]) {
        self.addCommands(commands, atQueueTop: false)
    }
    
    func addCommandsToQueueTop(_ commands:[Command]) {
        self.addCommands(commands, atQueueTop: true)
    }
    
    @discardableResult
    func pause() -> Bool {
        if self.state == .active {
            self.state = .paused
            return true
        }
        return false
    }
    
    @discardableResult
    func resume() -> Bool {
        if self.state == .paused {
            self.state = .active
            return true
        }
        return false
    }
    
    func invoke(batchSize:Int? = 0) {
        dispatchQueue.asyncIfNeeded {[self] in
            if !self._state.isActive {
                dlog?.note("invoke cannot work: state is not active!")
                return
            }
            
            var toBeExecuted = queues[.toExecute] ?? []
            guard toBeExecuted.count > 0 else {
                return
            }

            var toBeExecutedCopy =  Array<CommandWrapper>()
            if let batchSize = batchSize {
                let amt = min(batchSize, toBeExecuted.count)
                toBeExecutedCopy.append(contentsOf: toBeExecuted.prefix(amt))
                toBeExecuted.removeFirst(amt)
            } else {
                toBeExecutedCopy.append(contentsOf: toBeExecuted)
                toBeExecuted.removeAll()
            }
            
            queues[.toExecute] = toBeExecuted
            
            // Execute
            self.executeItems(queueType: .toExecute, items: toBeExecutedCopy) {
                switch toBeExecutedCopy.count {
                case 1:
                    let item = toBeExecutedCopy.first!
                    
                    if item.executionType == .execute {
                        // dlog?.warning("TODO REIMPLEMENT THIS >> Invoker updateActionDescription")
                        //DocumentView.current?.updateActionDescription(item.command as? ActionDescriptionable,
    //                                                                  for: item.isSucces ? .success : .failed,
    //                                                                  animated: true)
                        dlog?.successOrFail(condition: item.isSucces, items: "invoke DONE for [\(type(of: item.command)))")
                    }
                default:
                    dlog?.info("invoke DONE for \(toBeExecutedCopy.count) items")
                }
                
            }
        }
    }

    func undoLast(amount:Int? = nil) {
        dispatchQueue.asyncIfNeeded {[self] in
            if !self._state.isActive {
                dlog?.note("undoLast cannot work: state is not active!")
                return
            }
            
            var finished = self.queues[.finished] ?? []
            guard finished.count > 0 else {
                return
            }
            
            var toBeUndoed = Array<CommandWrapper>()
            if let amount = amount {
                let amt = min(amount, finished.count)
                toBeUndoed.append(contentsOf: finished.prefix(amt))
                finished.removeFirst(amt)
            } else {
                toBeUndoed.append(contentsOf: finished)
                finished.removeAll()
            }

            queues[.finished] = finished
            
            // Execute
            self.executeItems(queueType: .finished, items: toBeUndoed) {
                dlog?.info("undo DONE for \(toBeUndoed.count) items")
            }
        }
    }
    
    func redoLast(amount:Int? = nil) {
        dispatchQueue.asyncIfNeeded {[self] in
            if !self._state.isActive {
                dlog?.note("redoLast cannot work: state is not active!")
                return
            }
            
            var undoed = queues[.undoed] ?? []
            guard undoed.count > 0 else {
                return
            }
            
            var toBeRedoed = Array<CommandWrapper>()
            if let amount = amount {
                let amt = min(amount, undoed.count)
                toBeRedoed.append(contentsOf: undoed.prefix(amt))
                undoed.removeFirst(amt)
            } else {
                toBeRedoed.append(contentsOf: undoed)
                undoed.removeAll()
            }
            
            queues[.undoed] = undoed
            
            // Execute
            self.executeItems(queueType: .undoed, items: toBeRedoed) {
                dlog?.info("redo DONE for \(toBeRedoed.count) items")
            }
        }
    }
}
