//
//  NSView+SearchSubviews.swift
//  Bricks
//
//  Created by Ido on 09/12/2021.
//

import AppKit
/// Helps searching for a subview matching a given criteria down the view hierarchy
extension NSView /* SearchSubviews */ {
    /// Search for the first subview matching a given criteria down the view hierarchy
    /// NOTE: Recursive downtree
    ///
    /// - Parameter test: test to be perfomed on each iterated view to locate the first wanted view that passes the test
    /// - Returns: the first view down tree (breadth first) that passed the test
    func subviewWhichMatches(_ test:(NSView)->Bool)->NSView? {
        if test(self) {return self}
        
        for view in self.subviews {
            if let found = view.subviewWhichMatches(test) {
                return found
            }
        }
        
        return nil
    }
    
    
    func subviewsWhichMatches(_ test:(NSView)->Bool)->[NSView]? {
        if test(self) {return [self]}
        
        var result : [NSView] = []
        for view in self.subviews {
            if let found = view.subviewsWhichMatches(test) {
                result.append(contentsOf: found)
            }
        }
        
        if result.count == 0 {
            return nil
        }
        return result
    }
    
    /// Generic typed Search for the first subview matching a given criteria down the view hierarchy, performing the test only on subviews of the given type (generic function)
    /// NOTE: Recursive downtree, generic: the provided type must be a subclass of NSView. The function will iterate ALL subviews in the tree, regardless of type, and test only those of the given type.
    ///
    /// - Parameter test: test to be perfomed on each iterated view to locate the first wanted view that passes the test
    /// - Returns: the first view down tree (breadth first) that passed the test, returned in the required type
    func typedSubviewWhichMatches<T:NSView>(_ test:(T)->Bool)->T? {
        if let typedSelf = self as? T {
            if test(typedSelf) {return typedSelf}
        }
        
        for view in self.subviews {
            if let found = view.typedSubviewWhichMatches(test) {
                return found
            }
        }
        
        return nil
    }
    
    
    /// Search for a superview which matches a given criteria up the view hierarchy
    /// NOTE: Recursive uptree
    ///
    /// - Parameter test: test to be perfomed on each iterated view to locate the first wanted view that passes the test
    /// - Returns: the first view up the tree that passed the test
    func superviewWhichMatches(_ test:(NSView)->Bool)->NSView? {
        if test(self) {return self}
        
        if let superview = self.superview {
            if let found = superview.superviewWhichMatches(test) {
                return found
            }
        }
        
        return nil
    }
    
    
    /// Find the find responder view in a all subviews and their subviews:
    /// NOTE: Recursive downtree
    ///
    /// - Returns: a view that is currently the first responder. uses view.isFirstResponder to evaluate this.
    func findFirstResponder() -> NSView? {
        if self.isFirstResponder == true {
            return self
        }
        
        return self.subviewWhichMatches({ (view) -> Bool in
            return view.isFirstResponder == true
        })
    }
    
    /// Find and resign the first responder if it is in this view and call completion after resigned. If not, call completion immediately
    ///
    /// - Parameters:
    ///   - completionDelay: time after regsigning the first responder to call the completion
    ///   - completion: completion block is called after resigning first responder or immediately if no responder found
    func resignFirstResponderIfPossible(delayWhenResigning:TimeInterval = 0.22, completion:(()->Void)? = nil) {
        if let responder = self.findFirstResponder() { // , responder.canResignFirstResponder {
            responder.resignFirstResponder()
            self.window?.endEditing(for: nil)
            
            if let completion = completion {
                DispatchQueue.main.asyncAfter(delayFromNow: delayWhenResigning) {
                    completion()
                }
            }
        } else {
            completion?()
        }
    }
}
