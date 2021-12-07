//
//  OptionalEx.swift
//  XPlan
//
//  Created by Ido on 16/11/2021.
//

import Foundation

fileprivate func formattedValue(_ any: Any) -> String {
    
    switch any {
    case let any as CustomStringConvertible:
        return any.description
    case let any as CustomDebugStringConvertible:
        return any.debugDescription
    default:
        return "\(any)"
    }
}

func descOrNil(_ any : Any?)->String {
    guard let any = any else {
        return "<nil>"
    }
    
    return formattedValue(any)
}

extension Optional /*: CustomDebugStringConvertible */ {
    
    var debugDescription : String {
        return descOrNil
    }
    
    var descOrNil: String {
        
        if let value = self {
            
            return formattedValue(value)
        }
        return "<nil>"
    }
}
