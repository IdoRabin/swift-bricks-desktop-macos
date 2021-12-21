//
//  MNBaseView.swift
//  grafo
//
//  Created by Ido on 28/01/2021.
//

import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("MNBaseView")

class MNBaseView: NSView {
    
    private var hoverTrackingArea : NSTrackingArea? = nil
    @IBInspectable var isDetectHover : Bool = false {
        didSet {
            self.updateTrackingAreas()
        }
    }
    
    private var _lastMouseDownTime : Date? = nil
    private var _isMouseOver : Bool = false
    var isMouseOver : Bool {
        return _isMouseOver
    }
    
    var onMouseEnter : ((_ sender : MNBaseView)->Void)? = nil
    var onMouseExit : ((_ sender : MNBaseView)->Void)? = nil
    var onMouseUp : ((_ sender : MNBaseView)->Void)? = nil
    var onMouseDown : ((_ sender : MNBaseView)->Void)? = nil
    var onClick : ((_ sender : MNBaseView)->Void)? = nil
    
    private func removeTracking() {
        if let area = hoverTrackingArea {
            self.removeTrackingArea(area)
            hoverTrackingArea = nil
        }
    }
    
    override func updateTrackingAreas() {
        if isDetectHover {
            removeTracking()
            hoverTrackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: nil)
            self.addTrackingArea(hoverTrackingArea!)
        } else {
            removeTracking()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        _lastMouseDownTime = Date()
        super.mouseDown(with: event)
        //dlog?.info("mouseDown")
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        let interval = abs(_lastMouseDownTime?.timeIntervalSinceNow ?? 999.9)
        if interval < 0.3 {
            self.mouseClick(with: event)
        }
        //dlog?.info("mouseUp")
    }
    
    func mouseClick(with event: NSEvent) {
        // dlog?.info("click")
        onClick?(self)
    }
    
    override func mouseEntered(with event: NSEvent) {
        _isMouseOver = true
        super.mouseEntered(with: event)
        //dlog?.info("mouseEntered")
        onMouseEnter?(self)
    }
    
    override func mouseExited(with event: NSEvent) {
        _isMouseOver = false
        super.mouseEntered(with: event)
        //dlog?.info("mouseExited")
        onMouseEnter?(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // dlog?.info("awakeFromNib [\(self.attributedTitle.string)] sze:\(self.frame.size)")
        DispatchQueue.main.async {[self] in
            self.updateTrackingAreas()
        }
    }
    
    deinit {
        removeTracking()
    }
}
