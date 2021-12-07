//
//  ArrayEx.swift
//  testSwift
//
//  Created by Ido Rabin for  on 30/10/2021.
//  Copyright © 2021 Ido Rabin. All rights reserved.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("ArrayEx")

extension Sequence {
    /// Iterate all elements while handling for each element its index and the element.
    public func forEachIndex(_ body: (Int, Element) throws -> Void) rethrows {
        try self.enumerated().forEach { index, element in
            try body(index, element)
        }
    }
}

extension Array {
    
    /// Iterate all elements and their preceeding elements (current, previous). Will call first block with items index 0 and nil, next will call items 1 and 0 and so on..
    /// (current, previous) is the order of elements in the completion block
    public func forEachAndPrevious(_ body: (Element, Element?) throws -> Void) rethrows {
        
        if self.count == 0 {return}
        var prev : Element? = nil
        for i in 0..<self.count {
            try body(self[i], prev)
            prev = self[i]
        }
    }
    
    /// Iterate all elements while handling for each element its index and the element.
    public func forEachIndex(_ body: (Int, Element) throws -> Void) rethrows {
        if self.count == 0 {return}
        
        // TODO: Compare efficiency between .enumerated().forEach and the "for i in ..." loop...
        // self.enumerated().forEach { index, element in
        //     try body(index, element)
        // }
        for i in 0..<self.count {
            try body(i, self[i])
        }
    }
    
    /// Iterate all elements while handling for each element its float (index / total amount) part and the element. Thus serving a float growing on each iteration between 0... to 1.0. Good for calulating progress etc.
    public func forEachPart(_ body: (Float, Element) throws -> Void) rethrows {
        if self.count == 0 {return}
        
        let lastIndex = self.count - 1
        for i in 0..<self.count {
            try body(Float(i)/Float(lastIndex), self[i])
        }
    }
    
    
    /// Iterate all elements while handling for each element its index and the element.
    /// - Parameter body: iteration bloc. Return True to stop iterating!
    public func forEachIndexOrStop(_ body: (Int, Element) throws -> Bool) rethrows {
        if self.count == 0 {return}
        
        for i in 0..<self.count {
            let stop = try body(i, self[i])
            if stop {
                break
            }
        }
    }
}

extension Array {
    
    func descriptions()-> [String] {
        return self.compactMap({ (element) -> String in
            if let element = element as? CustomStringConvertible {
                return element.description
            } else {
                return String(describing: element)
            }
        })
    }
    
    /// Will iterate all elements one by one and compare them with all other elements but themselves, in an eficcient manner
    /// The function will call block with distinct pairs of elements, each pair called only once. (i.e same pair will never appear twice)
    ///
    /// - Parameter block: block to perform when comparing tow different elements
    func iterateComparingAllElements(where block: (_ elementA:Element, _ elementB : Element)->Void) {
        if self.count > 1 {
            for i in 0..<self.count {
                for j in (i+1)..<self.count {
                    block(self[i], self[j])
                }
            }
        } else {
            print("ArrayEx.compareAllElements cannot compare when count < 2")
        }
    }
    
    func removing(at index:Int)->[Element] {
        var result : [Element] = Array(self)
        if (index < 0) {
            result.remove(at: self.count + index) // python style remove from the end when negative...
        } else {
            result.remove(at: index)
        }
        return result
    }
}

extension Array {

    /// Searches for the biggest slices that match the test
    /// Will attempt to expand each element in both direction until a match is reached. Note that without the stopSliceGrowing test, we will grow slices even if they fail the test, to see if bigger slices pass the test. I.E algo will iterate through [b,c,d] even if [b,c] or [c,d] or [b] or [c] or [d] were not matched as slices and we started growing from wither of those. This means this function may proce CPU intensive.
    /// This function will give an edge to elements at the beginning of the array over latter ones in case two slices could be owners of an item between them when expanding.
    /// This function will return slices so that each element appears only in one of the slices. That is, no "overlaps" are allowed.
    /// - Parameters:
    ///   - test: a test for being of the same "type" or "quality" to quality as "in the same slice"
    ///   - stopSliceGrowing: a seperate test that disqualifies a slice from further testing (or gorwing and then more testing). This allows for optimization, and tells the algo when not to grow a slice and test again. NOTE: When this block is nil, the algo will iterate through [b,c,d] even if [b,c] or [c,d] or [b] or [c] or [d] are not matched as slices.
    func searchForConsecutiveSlices(matching test:([Element])->Bool, stopSliceGrowing:(([Element])->Bool)?)->[([Element]/* slice */, NSRange /* range of slice*/)] {
        guard self.count > 0 else {
            return []
        }
        
        var result :[([Element], NSRange)] = []
        
        dlog?.info("\n\n---testing\n\n")
        var maxIdx = 0
        var activeRange : NSRange = NSRange(location: 0, length: 0)
        var lastFoundRange : NSRange = NSRange(location: 0, length: 0)
        var loopProtection = self.count * self.count
        var failedSlice = false
        var testsCount = 0
        var loopCount = 0
        
        while maxIdx < self.count && loopProtection > 0 {
            failedSlice = false
            activeRange = NSRange(location: maxIdx, length: 1)
            var biggestFoundSlice : [Element] = []
            var biggestFoundRange : NSRange = NSRange(location: 0, length: 0)
            
            while activeRange.upperBound <= self.count && !failedSlice {
                let sliceToTest = self[activeRange.lowerBound..<Swift.min(activeRange.upperBound, self.count)]
                dlog?.info("testing slice: \(sliceToTest.description)")
                
                testsCount += 1 // total tests count
                if test(Array(sliceToTest)) {
                    // Found
                    biggestFoundSlice = Array(sliceToTest)
                    biggestFoundRange = activeRange
                } else {
                    // Failed
                    if (biggestFoundSlice.count > 0)
                    {
                        failedSlice = true
                    }
                    
                    // Test to stop growing, go to next active range location:
                    if stopSliceGrowing?(Array(sliceToTest)) ?? false {
                        dlog?.info("Will stop growing for slice:\(sliceToTest)")
                        failedSlice = true
                    }
                }
                activeRange.length += 1
                loopCount += 1
            }
            
            if (biggestFoundSlice.count > 0)
            {
                dlog?.info("Found biggest slice in range:\(biggestFoundRange) :\(biggestFoundSlice)")
                if (biggestFoundRange.location > 0 &&
                    lastFoundRange.upperBound != 0 &&
                    biggestFoundRange.location > lastFoundRange.upperBound) {
                    // We should search backwards?
                    var anotherFoundRange = biggestFoundRange
                    failedSlice = false
                    
                    // Test backeards if possible
                    while anotherFoundRange.location > lastFoundRange.upperBound && !failedSlice {
                        anotherFoundRange.location -= 1
                        anotherFoundRange.length += 1
                        dlog?.info("will be testing backwards between prev slice and this slice")
                        if anotherFoundRange.location > -1 {
                            let sliceToTest = self[anotherFoundRange.lowerBound..<Swift.min(anotherFoundRange.upperBound, self.count)]
                            dlog?.info("testing backwards slice: \(sliceToTest.description)")
                            
                            testsCount += 1 // total tests count
                            if test(Array(sliceToTest)) {
                                // Found while adding from the leading edge ("going backwards")
                                biggestFoundSlice = Array(sliceToTest)
                                biggestFoundRange = activeRange
                            } else {
                                // Test to stop growing, go to next active range location:
                                if stopSliceGrowing?(Array(sliceToTest)) ?? false {
                                    dlog?.info("Will stop growing rewind for slice:\(sliceToTest)")
                                    failedSlice = true
                                }
                            }
                        }
                        
                        loopCount += 1
                    }
                }
                
                activeRange.location = biggestFoundRange.upperBound
                activeRange.length = 1
                maxIdx = activeRange.location
                lastFoundRange = biggestFoundRange
                dlog?.info("Adding slice to results:\(biggestFoundRange) :\(biggestFoundSlice)")
                result.append((biggestFoundSlice, biggestFoundRange))
                
            } else {
                dlog?.info("DNF slice in range \(activeRange)")
                maxIdx += 1
            }
            loopProtection -= 1
            loopCount += 1
        }
        
        dlog?.info("Found \(result.count) slices performing \(testsCount) tests and \(loopCount) loops")

        return result
    }
    
    
    /// Searches for the biggest slices that match the test
    /// Will attempt to expand each element in both direction until a match is reached. Note that without the stopSliceGrowing test in another version for this function, we will grow slices even if they fail the test, to see if bigger slices pass the test. I.E algo will iterate through [b,c,d] even if [b,c] or [c,d] or [b] or [c] or [d] were not matched as slices and we started growing from wither of those. This means this function may proce CPU intensive.
    /// This function will give an edge to elements at the beginning of the array over latter ones in case two slices could be owners of an item between them when expanding.
    /// This function will return slices so that each element appears only in one of the slices. That is, no "overlaps" are allowed.
    /// - Parameter test: a test for being of the same "type" or "quality" to quality as "in the same slice"
    func searchForConsecutiveSlicesMatching(_ test:([Element])->Bool)->[([Element]/* slice */, NSRange /* range of slice*/)] {
        return searchForConsecutiveSlices(matching: test, stopSliceGrowing: nil)
    }
    
    /// Searches for the biggest slices that match the test
    /// This function iterates all elements from left (index 0) to right and crates a "slice" each time the previous element does not pass the test the same way the next eleement does.
    /// This function will give an edge to elements at the beginning of the array over latter ones in case two slices could be owners of an item between them when expanding.
    /// This function will return slices so that each element appears only in one of the slices. That is, no "overlaps" are allowed.
    /// - Parameter test: a test for being of the same "type" or "quality" to quality as "in the same slice"
    func searchForConsecutiveSlicesWithElementsMatching(_ test:(Element)->Bool)->[([Element]/* slice */, NSRange /* range of slice*/)] {
        var result : [([Element]/* slice */, NSRange /* range of slice*/)] = []
        
        // self.split(maxSplits: Int.max, omittingEmptySubsequences: true, whereSeparator: {(element) in return !test(element)) })
        var biggestFoundSlice : [Element] = []
        var biggestFoundRange : NSRange = NSRange(location: 0, length: 0)
        
        for i in 0..<self.count {
            let element = self[i]
            if test(element) {
                biggestFoundSlice.append(element)
                biggestFoundRange.length += 1
            } else {
                if (biggestFoundSlice.count > 0) {
                    result.append((biggestFoundSlice, biggestFoundRange))
                }
                biggestFoundSlice = []
                biggestFoundRange = NSRange(location: i + 1, length: 0)
            }
        }
        
        // Last slice has the ending element
        if (biggestFoundSlice.count > 0) {
            result.append((biggestFoundSlice, biggestFoundRange))
        }
        
        return result
    }
    
    /// Searches for the biggest slices that match the test
    /// This function iterates all elements from left (index 0) to right and crates a "slice" each time the previous element does not pass the test the same way the next eleement does.
    /// This function will give an edge to elements at the beginning of the array over latter ones in case two slices could be owners of an item between them when expanding.
    /// This function will return slices so that each element appears only in one of the slices. That is, no "overlaps" are allowed.
    /// - Parameter test: a test for being of the same "type" or "quality" to quality as "in the same slice"
    func searchForConsecutiveSlicesWithElementsPairsMatching(_ test:(/*current*/Element, /*previous*/Element?)->Bool)->[([Element]/* slice */, NSRange /* range of slice*/)] {
        var result : [([Element]/* slice */, NSRange /* range of slice*/)] = []
        
        // self.split(maxSplits: Int.max, omittingEmptySubsequences: true, whereSeparator: {(element) in return !test(element)) })
        var biggestFoundSlice : [Element] = []
        var biggestFoundRange : NSRange = NSRange(location: 0, length: 0)
        
        for i in 0..<self.count {
            let element = self[i]
            let prev = (i > 0 ? self[i-1] : nil)
            if test(element, prev) {
                if let prev = prev {
                    biggestFoundSlice.append(prev)
                    biggestFoundRange.length += 1
                }
                if prev != nil {
                    biggestFoundSlice.append(element)
                    biggestFoundRange.length += 1
                }
            } else {
                if (biggestFoundSlice.count > 0) {
                    result.append((biggestFoundSlice, biggestFoundRange))
                }
                biggestFoundSlice = []
                biggestFoundRange = NSRange(location: i, length: 0)
            }
        }
        
        // Last slice has the ending element
        if (biggestFoundSlice.count > 0) {
            result.append((biggestFoundSlice, biggestFoundRange))
        }
        
        return result
    }
}

/// Extends the Array class to handle equatable objects, thus allowing remove by object, intersection and testing if elements are common (shared) between two arrays
extension Array where Element: Equatable {
    
    func find(where test:(_ object:Element)->Bool, found:(_ object:Element)->Void, notFound:()->Void) {
        for object in self {
            if (test(object))
            {
                found(object)
                return
            }
        }
        
        notFound()
    }
    
    /// Remove first collection element that is equal to the given `object`:
    ///
    /// - Parameter object: object to remove
    @discardableResult mutating func remove(elementsEqualTo: Element)->Int {
        var removedCount = 0
        while let index = firstIndex(of: elementsEqualTo) {
            remove(at: index)
            removedCount += 1
        }
        return removedCount
    }
    
    /// Remove elements that are equal to the given `object`:
    ///
    /// - Parameter objects: objects to remove
    @discardableResult mutating func remove(objects: [Element])->Int {
        var removedCount = 0
        for object in objects {
            while let index = firstIndex(of: object) {
                remove(at: index)
                removedCount += 1
            }
        }
        return removedCount
    }
    
    /// Remove all objects that match a test
    /// Note: the function will accumulate a temp array of objects before removing them all from the array in one call, so there is a memory penalty sized the amount of objects to be deleted for this function
    ///
    /// - Parameter block: return bool for elements that are to be removed
    mutating func remove(where block: (_ object:Element)->Bool) {
        var toRemove : [Element] = []
        for object in self {
            if block(object) {
                toRemove.append(object)
            }
        }
        self.remove(objects: toRemove)
    }
    
    func removing(elementsEqualTo: Element)->[Element] {
        var result : [Element] = Array(self)
        result.remove(elementsEqualTo: elementsEqualTo)
        return result
    }
    
    func removing(objects: [Element])->[Element] {
        var result : [Element] = Array(self)
        result.remove(objects: objects)
        return result
    }
    
    func removing(where block: (_ object:Element)->Bool)->[Element] {
        var result : [Element] = Array(self)
        result.remove(where: block)
        return result
    }
    
    /// Return a new array of all intersecting objectes between two arrays
    /// For this function, intersecting is tested by using index(of:object) on both arrays, assuming objects are Equatable
    ///
    /// - Parameter objects: another array to intersect with
    /// - Returns: an array with all elements common fo both arrays
    func intersection(with objects: [Element])->[Element] {

        if (objects.count == 0 || self.count == 0) {return []}
        
        let result = objects.filter { (item) -> Bool in
            return self.contains(item)
        }

        return result
    }
    
    /// Returns
    ///
    /// - Parameter objects: an array of objects to test commonality of objects with
    /// - Returns: all elements NOT shared with the given array (will return only elements from the operated upon array which are not in the objects array)
    func notShared(with objects: [Element])->[Element] {
        
        if (objects.count == 0) {return Array<Element>(self)}
        if (self.count == 0)    {return objects}
        
        let result = self.filter { (item) -> Bool in
            return objects.contains(item) == false
        }

        return result
    }
    
    /// Returns a union between the arrays, keeping previous order and adding only elements that were not contained by the original array. (left-side has priority)
    ///
    /// - Parameter objects: an array of objects to union with
    /// - Returns: all elements in the current aray, and all elements in the objects aray that are not already in the given array.
    func union(with objects: [Element])->[Element] {
        var result : [Element] = []
        result.append(contentsOf: self)
        if objects.count > 0 {
            result.append(contentsOf: objects.notShared(with: self))
        }
        return result
    }
    
    
    /// Will replace any occurance of Equatable elements equal to element with the given array of elements inserted in its place
    /// - Parameter element: element to replace
    /// - Parameter with: elements to instert is all locations where element appeared
    /// - Returns: count of replacements performed
    @discardableResult mutating func replace(_ element:Element, with others:[Element])->Int {
        guard others.contains(element) == false else {
            print("WARNING ❌ ArrayEX (Equatable) replace:element:with:[] failed replacing \(element) with array:\(others.description) - this array contains the same (or equatably same) item we are replacing..")
            return 0
        }
        var result = 0
        while let index = self.firstIndex(of: element) {
            self.remove(at: index)
            self.insert(contentsOf: others, at: index)
            result += 1
        }
        return result
    }
    
    /// Will replace any occurance of Equatable elements equal to element with the given array of elements inserted in its place
    /// - Parameter element: element to replace
    /// - Parameter with: elements to instert is all locations where element appeared
    /// - Returns: count of replacements performed
    @discardableResult mutating func replace(_ element:Element, with other:Element)->Int {
        return self.replace(element, with: [other])
    }
}

extension Array where Element : Equatable & Hashable {
    
    /// Returns an array with the elements in the same order, only removing duplicate elements (equatables)
    /// The resulting array maintains the order, only removes elements
    func uniqueElements()->[Element]{
        var added = Set<Element>()
        var result : [Element] = []
        for item in self {
            if added.contains(item) == false {
                result.append(item)
                added.update(with: item)
            }
        }
        return result
    }
}

extension Sequence {
    
    func toDictionary<T:Hashable>(keyForItem:(_ element:Element)->T?)-> [T:Element] {
        var result :[T:Element] = [:]
        for item in self {
            if let key = keyForItem(item) {
                result[key] = item
            }
        }
        return result
    }
    
    func toDictionary<T:Hashable,Z>(keyForItem:(_ element:Element)->T?, itemForItem:(_ key:T, _ element:Element)->Z?)-> [T:Z] {
        var result :[T:Z] = [:]
        for item in self {
            if let key = keyForItem(item) {
                if let resitem = itemForItem(key, item) {
                    result[key] = resitem
                }
            }
        }
        return result
    }
    
    
    func groupBy<T:Hashable>(keyForItem:(_ element:Element)->T?)-> [T:[Element]] {
        return toDictionaryOfArrays(keyForItem: keyForItem)
    }
    
    // AKA groupBy
    func toDictionaryOfArrays<T:Hashable>(keyForItem:(_ element:Element)->T?)-> [T:[Element]] {
        var result :[T:[Element]] = [:]
        for item in self {
            if let key = keyForItem(item) {
                var arr : [Element] = result[key] ?? []
                arr.append(item)
                result[key] = arr
            }
        }
        return result
    }
    
    func iterateRollingWindow(windowSize maxSize:Int, block:([Element])->Void) {
        var arr : [Element] = []
        for item in self {
            arr.append(item)
            if arr.count > maxSize {
                arr.removeFirst()
            }
            block(arr)
        }
    }
}

