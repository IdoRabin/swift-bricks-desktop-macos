//
//  NSView+ANIMATION.swift
//  grafo
//
//  Created by Ido on 25/01/2021.
//

import Cocoa

extension NSView {
    
    var animator : Self {
        return self.animator()
    }
    
    class func animate(duration:TimeInterval,
                       delay:TimeInterval = 0,
                       changes: @escaping (NSAnimationContext) -> Void,
                       completionHandler: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(delayFromNow: delay) {
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = duration
                changes(context)
            }, completionHandler: completionHandler)
        }
    }
}
