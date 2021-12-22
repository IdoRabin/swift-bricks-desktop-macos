//
//  MNTree.swift
//  Bricks
//
//  Created by Ido on 22/12/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("MNTreeNode")

class MNTreeNode<T> {
    let MAX_RECURSION_DEPTH = 126
    
    enum IterationInstruction {
        case `continue`
        case stop
    }
    
    var value: T
    weak var parent: MNTreeNode?
    var children: [MNTreeNode] = []
    
    init(value newValue: T) {
        self.value = newValue
    }

    // MARK: Informative
    var hasSiblings : Bool {
        return parent?.children.count ?? 0 > 1
    }
    
    var siblings : [MNTreeNode]? {
        return parent?.children
    }
    
    var hasParent : Bool {
        return parent != nil
    }
    
    var hasChildren : Bool {
        return children.count > 0
    }
    var hasNoChildren : Bool {
        return children.count == 0
    }
    
    var isLeaf : Bool {
        return children.count == 0
    }
    
    var isTrunk : Bool {
        return !self.isLeaf && !self.isRoot
    }
    
    var isRoot : Bool {
        return parent == nil
    }
    
    var root :MNTreeNode {
        var found : MNTreeNode = self
        self.iterateUptree { node in
            found = node
            return ( node.parent != nil) ? .continue : .stop
        }
        return found
    }
    
    var depthInTree : Int {
        var depth : Int = 0
        self.iterateUptree { node in
            depth += 1
            return ( node.parent != nil) ? .continue : .stop
        }
        return depth
    }
    
    func leafNodesBelowSelf()->[MNTreeNode] {
        return self.filter(isDownTree: true) { node in
            return node.isLeaf && (node !== self)
        }
    }
    
    func trunkNodesBelowSelf()->[MNTreeNode] {
        return self.filter(isDownTree: true) { node in
            return node.isTrunk && (node !== self)
        }
    }
    
    func allLeafNodesInTree()->[MNTreeNode] {
        return self.root.filter(isDownTree: true) { node in
            node.isLeaf
        }
    }
    
    func allTrunkNodesInTree()->[MNTreeNode] {
        return self.root.filter(isDownTree: true) { node in
            node.isTrunk
        }
    }
    
    func parentNodesAboveSelf()->[MNTreeNode] {
        var nodes : [MNTreeNode] = []
        self.iterateUptree { node in
            if node !== self {
                nodes.append(node)
            }
            return .continue
        }
        return nodes
    }
    
    func allChildNodesInTree()->[MNTreeNode] {
        return self.root.allChildNodes()
    }
    
    func allChildNodes()->[MNTreeNode] {
        var nodes : [MNTreeNode] = []
        self.iterate(isDownTree: true) { node in
            if node !== self {
                nodes.append(node)
            }
            return .continue
        }
        return nodes
    }
    
    var childrenValues : [T] {
        return children.map { node in
            return node.value
        }
    }
    
    func childrenValues(isDownTree:Bool)->[T] {
        if isDownTree {
            return self.allChildNodes().map { node in
                return node.value
            }
        } else {
            return self.childrenValues
        }
    }
    
    // MARK: CRUD
    func add(children newChildren: [MNTreeNode]) {
        children.append(contentsOf: newChildren)
        newChildren.forEach { child in
            child.parent = self
        }
    }
    
    func add(child: MNTreeNode) {
        self.add(children: [child])
    }
    
    func insert(children newChildren: [MNTreeNode], at index:Int) {
        guard index >= 0 && index <= self.children.count else {
            dlog?.raiseAssertFailure("insert children failed: index out of bounds: index: \(index) not in range [0 .. \(self.children.count)]")
            return
        }
        children.insert(contentsOf: newChildren, at: index)
        newChildren.forEach { child in
            child.parent = self
        }
    }
    
    func insert(child: MNTreeNode, at index:Int) {
        self.insert(children: [child], at: index)
    }
    
    func replace(childAt index:Int, with newChild: MNTreeNode) {
        guard index >= 0 && index <= self.children.count else {
            dlog?.raiseAssertFailure("replace child failed: index out of bounds: index: \(index) not in range [0 .. \(self.children.count)]")
            return
        }
        
        if newChild !== children[index] {
            children[index].parent = nil
            children[index] = newChild
            newChild.parent = self
        }
    }
    
    func remove(childrenAt range:Range<Int>)->[MNTreeNode] {
        let removed = Array(self.children[range])
        self.children.removeSubrange(range)
        removed.forEach { child in
            child.parent = nil
        }
        return removed
    }
    
    func remove(childAt index:Int)->MNTreeNode {
        let child = self.children[index]
        self.children.remove(at: index)
        child.parent = nil
        return child
    }

    // MARK: Iteration - internal
    // MAX_RECURSION_DEPTH
    func internal_childrenValues(isDownTree:Bool, depth:Int) {
        guard depth < MAX_RECURSION_DEPTH else {
            dlog?.note("WARNING: childrenValues recursion depth > 127 levels!")
            return
        }
    }
    
    private func internal_iterateUptree(_ block:(_ node : MNTreeNode)->IterationInstruction, depth:Int) {
        guard depth < MAX_RECURSION_DEPTH else {
            dlog?.note("WARNING: iterateUptree recursion depth > 127 levels!")
            return
        }
        
        switch block(self) {
        case .continue:
            break
        case .stop:
            return
        }
        if let parent = parent {
            parent.internal_iterateUptree(block, depth: depth + 1)
        }
    }
    
    private func internal_iterate(isDownTree:Bool, _ block:(_ node : MNTreeNode)->IterationInstruction, depth:Int) {
        guard depth < MAX_RECURSION_DEPTH else {
            dlog?.note("WARNING: iterate downtree recursion depth > 127 levels!")
            return
        }
        
        switch block(self) {
        case .continue:
            break
        case .stop:
            return
        }
        
        if isDownTree {
            for child in children {
                switch block(child) {
                case .continue:
                    if isDownTree && child.hasChildren {
                        child.internal_iterate(isDownTree: true, block, depth: depth + 1)
                    }
                case .stop:
                    return
                }
            }
        }
    }
    
    private func internal_enumerate(isDownTree:Bool, _ block:(_ index : Int, _ total:Int, _ node : MNTreeNode)->IterationInstruction, depth:Int) {
        guard depth < MAX_RECURSION_DEPTH else {
            dlog?.note("WARNING: enumerate downtree recursion depth > 127 levels!")
            return
        }
        
        switch block(siblings?.count ?? 0, self.siblings?.count ?? 1, self) {
        case .continue:
            break
        case .stop:
            return
        }
        
        if isDownTree {
            var index : Int = 0
            let totalCount = children.count
            for child in children {
                switch block(index, totalCount, child) {
                case .continue:
                    if isDownTree && child.hasChildren {
                        child.internal_enumerate(isDownTree: true, block, depth: depth + 1)
                    }
                case .stop:
                    return
                }
                index += 1
            }
        }
    }
    
    private func internal_findFirst(isDownTree:Bool, depthFirst:Bool, _ test:(_ node : MNTreeNode)->Bool, depth:Int)->MNTreeNode? {
        guard depth < MAX_RECURSION_DEPTH else {
            dlog?.note("WARNING: findFirst downtree recursion depth > 127 levels!")
            return nil
        }
        
        if test(self) {
            return self
        } else {
            for child in children {
                if (!isDownTree || !depthFirst) && test(child) {
                    return child
                } else if isDownTree && depthFirst {
                    // Depth first:
                    if let result = child.internal_findFirst(isDownTree: true, depthFirst: true, test, depth: depth + 1) {
                        // Stops loop
                        return result
                    }
                }
            }
            
            if isDownTree && !depthFirst {
                // Breadth first:
                for child in children {
                    if let result = child.internal_findFirst(isDownTree: true, depthFirst: false, test, depth: depth + 1) {
                        // Stops loop
                        return result
                    }
                }
            }
        }
        
        return nil
    }
    private func internal_filter(isDownTree:Bool, _ test:(_ node : MNTreeNode)->Bool, depth:Int)->[MNTreeNode] {
        guard depth < MAX_RECURSION_DEPTH else {
            dlog?.note("WARNING: filter downtree recursion depth > 127 levels!")
            return []
        }
        
        var result : [MNTreeNode] = []
        if test(self) {
            result.append(self)
        }
        if !isDownTree {
            result.append(contentsOf: children.filter(test))
        } else {
            let downtree = internal_filter(isDownTree: true, test, depth: depth + 1)
            result.append(contentsOf: downtree)
        }
        return result
    }
    
    func iterateUptree(_ block:(_ node : MNTreeNode)->IterationInstruction) {
        self.internal_iterateUptree(block, depth:0)
    }
    
    // Depth-first
    func iterate(isDownTree:Bool, _ block:(_ node : MNTreeNode)->IterationInstruction) {
        self.internal_iterate(isDownTree: isDownTree, block, depth: 0)
    }
    
    // Depth-first
    func enumerate(isDownTree:Bool, _ block:(_ index : Int, _ total:Int, _ node : MNTreeNode)->IterationInstruction) {
        self.internal_enumerate(isDownTree: isDownTree, block, depth: 0)
    }
    
    // Depth-first or Breadth-first
    func findFirst(isDownTree:Bool, depthFirst:Bool, _ test:(_ node : MNTreeNode)->Bool)->MNTreeNode? {
        self.internal_findFirst(isDownTree: isDownTree, depthFirst: depthFirst, test, depth: 0)
    }
    
    func filter(isDownTree:Bool, _ test:(_ node : MNTreeNode)->Bool)->[MNTreeNode] {
        // self.internal_filter(isDownTree: isDownTree, block, depth: 0)
        self.internal_filter(isDownTree: isDownTree, test, depth: 0)
    }
}
