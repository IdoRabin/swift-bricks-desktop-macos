//
//  Box.swift
//  Bricks
//
//  Created by Ido on 17/06/2021.
//  Copyright © 2021 Bricks Ltd. All rights reserved.
//

import Foundation


fileprivate let dlog : DSLogger? = DLog.forClass("Box")

/// Boxes propery - will add observers / Listeners to the property so that any change to the property notifies all its listeners.
/// This seems to be better practice than KVO listening, notification center or delegates in many cases
// @propertyWrapper
class Box<T:Any> {
    
    enum Operation : Int, Hashable {
        // All set operations
        case whenSet = 1 // any time the value changes

        // Equatables
        case whenChanged// equatable new value != oldValue
        
        case equals  // equatable new value != someValue
    
        // Comperables
        case greaterThan // comperables new value > someValue
        case lessThan    // comperables new value < someValue
    
        // Sequence w/ Equatable elements
        case contains // when the observed sequence contains the specified element someValue
        case whenAnyElementPasses // whenever the observed sequence contains at least one element passing a given test
        case whenAllElementPass // when all the elements in the observed sequence satify the given test
        case intersects // when the observed sequence contains at least one element in the specified sequence someValue(s) (also a sequence)
        
        // ArraySlice (countable)
        case whenCountEquals  // when the observed sequence has exactly "count" elements in it
        case whenCountGreaterThan // when the observed sequence has more than "count" elements in it
        case whenCountLessThan // when the observed sequence has less than "count" elements in it
        case whenEmptied // when the observed sequence has become or is empty
        
        // Sequence, Numerical
        
        
        // Sequence
        var description : String {
            return "\(self)"
        }
    
        static var all : [Operation] {
            get {
                return [.whenSet, .whenChanged, .equals, .greaterThan, .lessThan,
                        .contains, .whenAnyElementPasses, .whenAllElementPass, .intersects,
                        .whenCountEquals, .whenCountGreaterThan, .whenCountLessThan, .whenEmptied]
            }
        }
        
        static var allDescriptions : [String] {
            get {
                return self.all.compactMap { (operation) -> String in
                    return operation.description
                }
            }
        }
    }
    
    // MARK: members
    typealias ListenerBlock = (T,T)-> Void
    typealias ListenerTest = (T,T)-> Bool
    typealias ListenerID = String
    typealias OperationID = String
    private var willChangeListeners : [ListenerID:[Operation:ListenerBlock]] = [:]
    private var didChangeListeners : [ListenerID:[Operation:ListenerBlock]] = [:]
    private var possibleOperations = Set<Operation>(arrayLiteral: .whenSet)
    
    // MARK: properties
    private var _value : T
    var value : T {
        get {
            return _value
        }
        set {
            let oldValue = _value
            let newValue = newValue
            let operationsArr = possibleOperations.allElements().sorted { (o1, o2) -> Bool in
                o1.rawValue < o2.rawValue
            }
            if willChangeListeners.count > 0 {
                notifyWillChange(oldValue: oldValue, newValue: newValue, operations: operationsArr)
            }
            _value = newValue
            if didChangeListeners.count > 0 {
                notifyDidChange(oldValue: oldValue, newValue: newValue, operations: operationsArr)
            }
        }
    }
    
    // MARK: Private
    private func notifyWillChange(oldValue:T, newValue:T, operations:[Operation]) {
        for (listenerId, _ /*listener*/) in willChangeListeners {
            for operation in operations {
                if let listenerBlock = willChangeListeners[listenerId]?[operation] {
                    listenerBlock(oldValue, newValue)
                }
            }
        }
    }
    
    private func notifyDidChange(oldValue:T, newValue:T, operations:[Operation]) {
        for (listenerId, _ /*listener*/) in didChangeListeners {
            for operation in operations {
                if let listenersDic = didChangeListeners[listenerId] {
                    if let listenerBlock = listenersDic[operation] {
                        listenerBlock(oldValue, newValue)
                    }
                }
            }
        }
    }
    
    // MARK: Lifecycle
    init(_ newValue : T) {
        _value = newValue
    }
    
    deinit {
        // Clear all values
        willChangeListeners.removeAll()
        didChangeListeners.removeAll()
    }
    
    fileprivate func newId(descOfTest:Any? = nil, listener : AnyObject)->ListenerID {
        var result = ("\(type(of: listener))_") + String(memoryAddressOf: listener)
        
        if let tst = descOfTest {
            if let tstStr = tst as? String {
                if tstStr.count < 10 {
                    result += "_" + tstStr
                } else {
                    result += "_\(tstStr.hash)"
                }
            } else if let has = tst as? AnyHashable {
                result += "_\(has.hashValue)"
            } else {
                result += "_\(tst)"
            }
        }
        
        return result
    }

    private func remove(listener : AnyObject) {
        let id = newId(listener: listener)
        for prefix in /*prefixes*/ ["any_", "equ_", "gt_", "lt"] {
            let tid = prefix + id
            if willChangeListeners[tid] != nil {
                willChangeListeners[tid] = nil
            }
            if didChangeListeners[tid] != nil {
                didChangeListeners[tid] = nil
            }
        }
    }

    fileprivate func removeNullified(id : String) {
        dlog?.note("listener \(id) was released. removing from the box")
        for var listeners in [willChangeListeners, didChangeListeners] {
            listeners[id] = nil
            
            let partial = id.components(separatedBy: "_").removing(at: -1).joined(separator: "_")
            if partial.count > 0 {
                for operation in Operation.allDescriptions {
                    let tid = partial + "_" + operation
                    if tid != id && listeners[tid] != nil {
                        listeners[tid] = nil
                    }
                }
            }
        }
    }
    
    fileprivate func addListener(_ listener : AnyObject, onInit:Bool = false, operation:Operation, test:@escaping ListenerTest, perform: @escaping ListenerBlock){
        let id = newId(descOfTest: operation.description, listener: listener)
        possibleOperations.update(with: operation)
        
        // Add listener to operaiton with this id
        if id.count > 1 {
            var blocksByOperation = didChangeListeners[id] ?? [:]
            blocksByOperation[operation] = {[weak listener, weak self] (oldVal, newVal) in
                if let _ = listener {
                    if test(oldVal, newVal) {
                        perform(oldVal, newVal)
                    }
                } else {
                    self?.removeNullified(id: id)
                }
            }
            didChangeListeners[id] = blocksByOperation
        }
        
        // notify on "init" if asked to, which is "when added": (now)
        if onInit {
            //if test(_value, _value) {
                perform(_value, _value)
            //}
        }
    }

    // MARK: Public
    
    /// Will notify the current value to all listerens - this is good for init situations
    func notitySetSameValue() {
        // Wil lre-set value
        self.value = _value
    }

    func removeAllListeners() {
        for id in Array(willChangeListeners.keys).union(with: Array(didChangeListeners.keys)) {
            self.removeNullified(id: id)
        }

        willChangeListeners.removeAll()
        didChangeListeners.removeAll()
    }
    
    var willChangeListenersCount : Int {
        return willChangeListeners.count
    }
    
    var didChangeListenersCount : Int {
        return didChangeListeners.count
    }
    
    var allListenerIds : [String] {
        return Array(willChangeListeners.keys).intersection(with: Array(didChangeListeners.keys))
    }
    
    var totalListenersCount : Int {
        return allListenerIds.count
    }
    
    
    func whenSet(broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .whenSet, test: {[weak self] (old, new) -> Bool in
            return (self != nil)
        }, perform: perform)
    }
}

extension Box where T : Equatable {
    func whenChanged(broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .whenChanged, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return (old != new)
            }
            return false
        }, perform: perform)
    }
    
    func whenEquals(to value:T, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .equals, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return (new == value)
            }
            return false
        }, perform: perform)
    }
}

extension  Box where T : Comparable {
    func whenGreaterThan(_ value:T, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .greaterThan, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return (new > value)
            }
            return false
        }, perform: perform)
    }
    
    func whenLessThan(_ value:T, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .lessThan, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return (new < value)
            }
            return false
        }, perform: perform)
    }
}


extension  Box where T : Sequence {
    
    func whenAnyElementPasses(test:@escaping (T.Element)->Bool, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .whenAnyElementPasses, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return (new.first(where: test) ?? nil) != nil
            }
            return false
        }, perform: perform)
    }
}


extension  Box where T : Sequence, T.Element : Equatable {
    
    func whenContains(_ element:T.Element, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .contains, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return new.contains(element)
            }
            return false
        }, perform: perform)
    }
    
    func whenIntersects(other:T, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .intersects, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return new.filter { (element) -> Bool in
                    return other.contains(element)
                }.count > 0
            }
            return false
        }, perform: perform)
    }
}

extension  Box where T : Collection {
    
    func whenAllElementPass(test:@escaping (T.Element)->Bool, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .whenAllElementPass, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return new.filter(test).count == new.count
            }
            return false
        }, perform: perform)
    }
    
    func whenCountEquals(_ count:Int, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .whenCountEquals, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return new.count == count
            }
            return false
        }, perform: perform)
    }

    func whenCountGreaterThan(_ count:Int, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .whenCountGreaterThan, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return new.count > count
            }
            return false
        }, perform: perform)
    }
    
    func whenCountLessThan(_ count:Int, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .whenCountLessThan, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return new.count < count
            }
            return false
        }, perform: perform)
    }
    
    func whenEmptied(_ count:Int, broadcastTo listener:AnyObject, onInit:Bool = false, perform: @escaping ListenerBlock) {
        addListener(listener, onInit:onInit, operation: .whenEmptied, test: {[weak self] (old, new) -> Bool in
            if let _ = self {
                return new.count == 0
            }
            return false
        }, perform: perform)
    }
}
