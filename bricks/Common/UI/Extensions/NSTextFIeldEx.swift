//
//  NSTextFIeldEx.swift
//  grafo
//
//  Created by Ido on 16/10/2021.
//

import Cocoa

extension NSTextField {
    
    func setStringValue(_ newValue: String, animated: Bool = true, duration: TimeInterval = 0.7) {
        guard stringValue != newValue else { return }
        if animated {
            animateText(change: { self.stringValue = newValue }, duration: duration)
        } else {
            stringValue = newValue
        }
    }

    func setAttributedStringValue(_ newValue: NSAttributedString, animated: Bool = true, duration: TimeInterval = 0.7) {
        guard attributedStringValue != newValue else { return }
        if animated {
            animateText(change: { self.attributedStringValue = newValue }, duration: duration)
        }
        else {
            attributedStringValue = newValue
        }
    }

    private func animateText(change: @escaping () -> Void, duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration / 2.0
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animator().alphaValue = 0.0
        }, completionHandler: {
            change()
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = duration / 2.0
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
                self.animator().alphaValue = 1.0
            }, completionHandler: {})
        })
    }
}
