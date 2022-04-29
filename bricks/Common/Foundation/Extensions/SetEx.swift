//
//  SetEx.swift
//  
//
//  Created by Ido Rabin on 17/05/2021.
//  Copyright © 2021 . All rights reserved.
//

import Foundation

extension Set {
    
    
    /// Get all elements in the set as an array / sequence of the same type. Convenience, equivalent to let myArray = Array<Element>(mySet)
    ///
    /// - Returns: an array of the elements in the given set
    func allElements()->[Element] {
        return Array<Element>(self)
    }
}

extension IndexSet {
    /// Get all elements in the set as an array / sequence of the same type. Convenience, equivalent to let myArray = Array<Element>(mySet)
    ///
    /// - Returns: an array of the elements in the given set
    func allElements()->[Element] {
        return Array<Element>(self)
    }
}

