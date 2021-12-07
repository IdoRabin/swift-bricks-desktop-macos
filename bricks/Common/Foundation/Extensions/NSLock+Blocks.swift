//
//  NSLock+Blocks.swift
//  Sync.AI
//
//  Created by Ido Rabin on 15/11/2017.
//  Copyright © 2017 Bricks. All rights reserved.
//

import Foundation

extension NSLock {
    
    /// Lock the lock and release when the block is performed
    ///
    /// - Parameter block: block to perform while the lock is locked
    func lock(_ block:()->()) {
        self.lock()
        var retainer : NSLock? = self
        block()
        self.unlock()
        if (retainer != nil) {retainer = nil}
    }
}

extension NSRecursiveLock {
    /// Lock the lock and release when the block is performed
    ///
    /// - Parameter block: block to perform while the lock is locked
    func lock(_ block:()->()) {
        self.lock()
        var retainer : NSRecursiveLock? = self
        block()
        self.unlock()
        if (retainer != nil) {retainer = nil}
    }
}
