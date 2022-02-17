//
//  NSTextField+Animated Chars.swift
//  Bricks
//
//  Created by Ido on 13/01/2022.
//

import AppKit

extension NSTextField /* animated chars */ {
    
    private func internal_animatedClearChars(duration:TimeInterval, isFifo:Bool, completion:(()->Void)? = nil) {
        // Call completion when done
        guard self.stringValue.count > 0 else {
            completion?()
            return
        }
        
        // Otherwise, subtrat one char
        if isFifo {
            self.stringValue = self.stringValue.substring(to: -1)
        } else {
            self.stringValue = self.stringValue.substring(from: 1)
        }
        
        if self.stringValue.count > 0 {
            // and call self for next subtractions
            DispatchQueue.main.asyncAfter(delayFromNow: duration) {
                self.internal_animatedClearChars(duration: duration, isFifo: isFifo, completion: completion)
            }
        } else {
            completion?()
        }
    }
    
    
    func animatedClearCharsFIFO(duration:TimeInterval, completion:(()->Void)? = nil) {
        let cnt = self.stringValue.count
        guard cnt > 0 else {
            completion?()
            return
        }
        let charDuration = duration / Double(max(cnt, 1))
        self.internal_animatedClearChars(duration: charDuration, isFifo: false, completion: completion)
    }
    
    func animatedClearCharsLIFO(duration:TimeInterval, completion:(()->Void)? = nil) {
        let cnt = self.stringValue.count
        guard cnt > 0 else {
            completion?()
            return
        }
        
        let charDuration = duration / Double(max(cnt, 1))
        self.internal_animatedClearChars(duration: charDuration, isFifo: false, completion: completion)
    }
}
