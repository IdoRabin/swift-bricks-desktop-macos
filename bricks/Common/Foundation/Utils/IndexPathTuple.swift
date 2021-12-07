//
//  IndexPathTuple.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import Foundation

struct IndexPathTuple<Element:Any> {
    let element : Element?
    let indexpath : IndexPath?
    var isEmpty : Bool { return element == nil && indexpath == nil }
}

extension Dictionary where Key == IndexPath {
    func toIIndexPathTuples()->[IndexPathTuple<Value>] {
        return self.map { key, val in
            return IndexPathTuple(element: val, indexpath: key)
        }
    }
}
