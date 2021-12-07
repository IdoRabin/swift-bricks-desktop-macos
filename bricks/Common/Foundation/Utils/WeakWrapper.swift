//
//  WeakWrapper.swift
//  Bricks
//
//  Created by Ido Rabin for Bricks on 30/10/2017.
//  Copyright © 2017 Bricks. All rights reserved.
//

import Foundation


/// A wrapper for weakly referenced objects, for use in observers arrays and other lists that require pointers to objects without retaining them
public class WeakWrapper {
    weak var value: AnyObject?
    
    
    /// Initializer
    ///
    /// - Parameter value: Any object that is retainable will be wrapped by this instance, as a weak reference
    init(value: AnyObject) {
        self.value = value
    }
}


/// A wrapper for weakly binded objects, for use in observers arrays and other lists that require pointers to objects without retaining them
/// This class is Hashable, and therefore can be used in dictionaries and two-way dictionaries
public class WeakWrapperHashable<T:HashableObject> :Hashable
{
    weak var value: T?
    
    
    /// Initializer
    ///
    /// - Parameter value: Any object that is retainable will be wrapped by this instance, as a weak reference
    init(value: T) {
        self.value = value
    }
    
    /// Initializer
    ///
    /// - Parameter value: Any object that is retainable will be wrapped by this instance, as a weak reference
    init(_ value: T) {
        self.value = value
    }
    
    /// Returns the hash value for the weakly retained object
    public func hash(into hasher: inout Hasher) {
        if let val = value {
            hasher.combine(val.hashValue)
        }
    }
    
    /// Equate
    ///
    /// - Parameters:
    ///   - lhs: left hand side parameter
    ///   - rhs: right hand side parameter
    /// - Returns: Will return true when both parameters are "equal" by comparing their hash values
    public static func ==(lhs: WeakWrapperHashable, rhs: WeakWrapperHashable) -> Bool {
        if let l = lhs.value, let r = rhs.value {
            return l == r
        }
        
        return false
    }
}
