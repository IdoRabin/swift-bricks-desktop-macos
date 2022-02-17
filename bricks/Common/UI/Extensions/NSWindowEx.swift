//
//  NSWindowEx.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import Foundation
import AppKit

extension NSWindow {
    
    class func forceWindowCornerRadius(_ window:NSWindow, cornerRadius : CGFloat = 12, setup:((NSWindow?)->Void)? = nil) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.showsToolbarButton =   false
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView?.layer?.corner(radius: cornerRadius)
        setup?(window)
    }
    
    func forceWindowCornerRadius(_ radius : CGFloat = 12,setup:((NSWindow?)->Void)? = nil) {
        NSWindow.forceWindowCornerRadius(self, cornerRadius:radius, setup: setup)
    }
    
    func bringToFront() {
        self.orderedIndex = 0
    }
    
    var hasAnySheetPresented : Bool {
        return self.sheets.count > 0
    }
    var sheetTitles : [String] {
        self.sheets.compactMap { window in
            window.title.replacingOccurrences(ofFromTo: ["," : "_"])
        }
    }
    
    var isFullScreen : Bool {
        let result = styleMask.contains(.fullScreen)
        // DLog.ui["WindowScrn"]?.info("\(result ? "full" : "partial" ) screen")
        return result
    }
}

extension NSWindow {
    
    func fadeHide(completed:@escaping ()->Void) {
        guard let cv = self.contentView else {
            return
        }
        
        let precloseFrame = self.frame
        
        func finalize() {
            cv.layer?.opacity = 0.0
            self.contentViewController?.view.alphaValue = 0.0
            self.setFrame(precloseFrame, display: false, animate: false)
            // dlog?.info("fadeHide finalized")
            completed()
        }
        let duration : TimeInterval = 0.2

        NSAnimationContext.runAnimationGroup(
            { (context) -> Void in
        context.duration = duration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().alphaValue = 0.0

            }, completionHandler: {
                finalize()
        })
    }
    
    func shake(with intensity : CGFloat = 0.3, duration : Double = 0.5, completion:(()->Void)? = nil){
        let numberOfShakes = 3
        let frame : CGRect = self.frame
        let shakeAnimation :CAKeyframeAnimation  = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x:NSMinX(frame),y:NSMinY(frame)))

        let clampedIntensity = clamp(value: intensity, lowerlimit: 0.01, upperlimit: 100.0) { intensity in
            DLog.ui["NSWindowEx"]?.note("shake(with intensity:\(intensity)) out of bounds: was clamped to the range: 0.01...100.0")
        }
        let szeW : CGFloat = frame.size.width * clampedIntensity * 0.05
        let szeH : CGFloat = frame.size.height * clampedIntensity * 0.05
        for index in 0...numberOfShakes-1 {
            
            // Mu;ltiplier for the shake - should become smaller for each repeat:
            let mul = 1.0 - (CGFloat(index) / CGFloat(numberOfShakes))
            shakePath.addLine(to: CGPoint(x:NSMinX(frame) - szeW * mul, y:NSMinY(frame)))
            shakePath.addLine(to: CGPoint(x:NSMinX(frame) - szeW * mul, y:NSMinY(frame) - szeH * mul))
            shakePath.addLine(to: CGPoint(x:NSMinX(frame) + szeW * mul, y:NSMinY(frame)))
        }

        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = duration

        self.animations = ["frameOrigin":shakeAnimation]
        self.animator().setFrameOrigin(self.frame.origin)
        
        if let completion = completion {
            DispatchQueue.main.asyncAfter(delayFromNow: duration + 0.01) {
                completion()
            }
        }
    }
}


extension NSWindowController {
    
    func forceWindowCornerRadius(_ radius : CGFloat = 12, setup:((NSWindow?)->Void)? = nil) {
        waitFor("window", interval: 0.02, timeout: 0.1, testOnMainThread: {
            self.isWindowLoaded
        }, completion: { waitResult in
            self.window?.forceWindowCornerRadius(radius, setup: setup)
        }, counter: 1)
    }
    
    func bringWindowToFront() {
        guard self.isWindowLoaded else {
            return
        }
        self.window?.bringToFront()
    }
}

class NSUtilWindow : NSWindow {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExcludedFromWindowsMenu = true
    }
}
