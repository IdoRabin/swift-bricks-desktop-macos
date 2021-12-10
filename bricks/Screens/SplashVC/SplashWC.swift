//
//  SplashWC.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("SplashWC")

class SplashWC : NSWindowController {
    
    weak var bkgBox : MNColoredView? = nil
    weak var bkgBoxLayer : CALayer? = nil
    var isClosing = false
    
    override var windowFrameAutosaveName: NSWindow.FrameAutosaveName {
        get {
            return "\(type(of: self))"
        }
        set {
            // does nothing
        }
    }
    
    override func windowWillLoad() {
        super.windowWillLoad()
        // window?.collectionBehavior = [.ignoresCycle]// , .ignoresCycle, .canJoinAllSpaces]
        AppDocumentHistory.shared.revalidateAll()
    }
    
    func addBoxBkg(cornerRadius : CGFloat) {
        guard let window = self.window else {
            return
        }
        
        // add a box:
        let box = MNColoredView(frame: window.frame.boundsRect())
        box.backgroundColor = NSColor.gray
        box.borderWidth = 0
        box.autoresizesSubviews = true
        box.borderColor = .clear
        box.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(box, positioned: .below, relativeTo: nil)
        
        // Add corner radius as path
        let wid : CGFloat = 0.5
        let bnds = window.frame.boundsRect().insetBy(dx: wid, dy: wid) // .adding(widthAdd: -0.95)
        let rad = cornerRadius
        let layer = CAShapeLayer()
        layer.frame = window.frame.boundsRect()
        layer.fillColor = NSColor.windowBackgroundColor.cgColor
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer.path = CGPath(roundedRect: bnds, cornerWidth: rad - wid, cornerHeight: rad - wid, transform: nil)
        layer.masksToBounds = false
        box.wantsLayer = true
        box.layer?.masksToBounds = true
        box.layer?.addSublayer(layer)
        bkgBoxLayer = layer
        bkgBox = box
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        let cornerRadius : CGFloat = 12.0
        if let window = self.window {
            window.minSize = CGSize(width: 420, height: 420)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.isExcludedFromWindowsMenu = true
            window.isMovableByWindowBackground = true
            window.contentView?.layer?.corner(radius: cornerRadius)
            window.titlebarAppearsTransparent  =   true
            window.titleVisibility             =   .hidden
            window.contentViewController?.title = "xxx"
            window.showsToolbarButton          =   false
            window.showsResizeIndicator = false
            (window.contentViewController as? SplashVC)?.windowController = self
        } else {
            dlog?.note("window is nil, expected value.")
        }
        
        self.window?.delegate = AppDelegate.shared.documentController
        
        DispatchQueue.main.asyncAfter(delayFromNow: 0.02) {[self] in
            addBoxBkg(cornerRadius: cornerRadius)
            self.showWindow(self)
        }
    }
    
    deinit{
        dlog?.info("deinit")
    }
    
}
