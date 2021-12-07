//
//  MouseTracking.swift
//  grafo
//
//  Created by Ido on 23/01/2021.
//

import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("MouseTracking")

enum MouseEvent : CustomStringConvertible {
    case hover
    case lDown // before determining if click or drag
    case rDown // before determining if click or drag
    case lClick
    case rClick
    case lDrag
    case rDrag
    
    static var all : [MouseEvent] = [.hover, .lDown, .rDown, .lClick, .rClick, .lDrag, .rDrag]
    static private var drags : [MouseEvent] = [.lDrag, .rDrag]
    static private var clicks : [MouseEvent] = [.lClick, .rClick]
    
    var isADrag : Bool {
        return Self.drags.contains(self)
    }
    var isAClick : Bool {
        return Self.clicks.contains(self)
    }
    
    var description: String {
        switch self {
        case .hover: return "hover"
        case .lDown: return "lDown"
        case .rDown: return "rDown"
        case .lClick: return "lClick"
        case .rClick: return "rClick"
        case .lDrag: return "lDrag"
        case .rDrag: return "rDrag"
        }
    }
}

enum MouseEventState : Equatable  {
    case begin
    case middle
    case end(CGFloat)
    
    static func ==(lhs:MouseEventState, rhs:MouseEventState)->Bool {
        switch (lhs, rhs) {
        case (.begin, .begin):    return true
        case (.middle, .middle):  return true
        case (.end(let x), end(let y)):    return x == y
        default: return false
        }
    }
    
    var isEnd : Bool {
        switch self {
        case .end(_):
            return true
        default:
            return false
        }
    }
}

class MouseTracking {
    var lastClickTime : Date? = nil
    var mouseUpTime : Date? = nil
    var mouseDownTime : Date? = nil
    var mouseDownPoint : CGPoint? = nil
    var mouseUpPoint : CGPoint? = nil
    var rect : NSRect? = nil
    var fadeoutRect : NSRect? = nil
    var fadeoutCompleted : CGFloat = 0.0
    var snapMode : GridViewSnapMode = .grid
    var consecutiveEventCount : Int = 0 // counts how many times this event was called consecutively..
    func clear() {
        lastClickTime = nil
        mouseUpTime = nil
        mouseDownTime = nil
        mouseDownPoint = nil
        mouseUpPoint = nil
        rect = nil
        fadeoutRect = nil
        fadeoutCompleted = 0
        consecutiveEventCount = 0
        // snapMode = // stays as it was..
    }
}

protocol MouseTrackingObserver {
    func mouseTracked(type:MouseEvent, rect:CGRect?, state:MouseEventState)
    func mouseClicked(type:MouseEvent, rect:CGRect)
    func mouseDblClicked(type:MouseEvent, rect:CGRect)
}

class MouseTrackings : NSObject {
    
    var observers = ObserversArray<MouseTrackingObserver>()
    var isEnabled : Bool = true
    var events : [MouseEvent:MouseTracking] = [:]
    weak var snappableView : GridViewSnappable? = nil
    weak var hostView : NSView? = nil
    var canceledKeys : [String] = []
    
    private var _type : MouseEvent? = nil
    var type : MouseEvent {
        get {
            return _type ?? .hover
        }
        set {
            let tracking = self[newValue]
            
            if _type != newValue {
                if let prevType = _type {
                    self.endState(eventType:prevType)
                }
                
                if _type != newValue { // make sure the endState of last event didn't change _type
                    // Started new type of event
                    _type = newValue
                    self.state = .begin
                }
                dlog?.info("type changed to:\(_type?.description ?? "<nil>" )")
            } else {
                if self.state != .middle {
                    self.state = .middle
                }
                tracking.consecutiveEventCount += 1
            }
            
            self.observers.enumerateOnCurrentThread { (observer) in
                observer.mouseTracked(type: newValue, rect: tracking.rect, state: self.state)
            }
        }
    }
    
    private var _state : MouseEventState? = nil
    private var state : MouseEventState {
        get {
            return _state ?? .begin
        }
        set {
            if _state != newValue {
                _state = newValue
            }
        }
    }
    
    // Constants
    let mousePointRadius : CGFloat = 10
    let fadeoutCounter : Int = 0
    let fadeoutDuration : TimeInterval = 0.3
    let fadeoutMaxCount = 25
    
    subscript(key:MouseEvent)->MouseTracking {
        if events[key] == nil {
            events[key] = MouseTracking()
            if [MouseEvent.lDown, MouseEvent.rDown].contains(key) {
                events[key]?.snapMode = .rounded
            }
            if [MouseEvent.lDown, MouseEvent.rDown].contains(key) {
                events[key]?.snapMode = .rounded
            }
            if key.isADrag {
                events[key]?.snapMode = .grid
            }
        }
        return events[key]!
    }
    
    private func endState(eventType:MouseEvent) {
        guard let _ = hostView else {
            return
        }
        
        if let event = events[eventType] {
            
            if event.fadeoutRect == nil {
                event.fadeoutRect = event.rect
            }
            let rect = event.fadeoutRect ?? event.rect ?? NSRect.zero
            
            self._state = .end(0)
            
            if eventType.isADrag {
                self.endedMouseDrags()
            }
            
            if event.fadeoutCompleted >= 0 && event.fadeoutCompleted < 1.0 {
                self.observers.enumerateOnMainThread { (observer) in
                    observer.mouseTracked(type: eventType, rect: rect, state: .end(1.0))
                }
            }
        }
    }
    
    private func calcLocationInView(point:CGPoint, snapMode:GridViewSnapMode)->CGPoint? {
        guard let _ = hostView else {
            return nil
        }
        
        var result = point
        if let gridView = snappableView {
            result = gridView.snapPoint(pt: point, snapMode: snapMode) ?? point
        }
        
        return result
    }
    
    private func calcLocationInView(for event: NSEvent, snapMode:GridViewSnapMode)->CGPoint? {
        guard let hostview = hostView else {
            return nil
        }
        
        var result = event.locationInView(hostview)
        if let gridView = snappableView {
            result = gridView.snapLocationInView(for: event, snapMode: snapMode)
        }
        
        return result
    }
    
    private var isEnabledAndValid : Bool {
        return self.isEnabled && hostView != nil
    }
    
    required init(hostView newHostView:NSView) {
        hostView = newHostView
    }
    
    private func animateRectRefresh(view:NSView, rect:CGRect, time:TimeInterval, slices:Int, block:((_ step:Int)->Void)? = nil) {
        let tSlice : TimeInterval = time / TimeInterval(max(slices, 1))
        var step = 0
        for i in 0...max(slices + 2, 1) {
            DispatchQueue.main.asyncAfter(delayFromNow: TimeInterval(i)*tSlice) {
                view.setNeedsDisplay(rect.insetBy(dx: -10, dy: -10))
                block?(step)
                step += 1
            }
        }
    }
    
    // MARK: Fwd mouse events
    func rightMouseDown(with event: NSEvent) {
        guard isEnabledAndValid else {
            return
        }
        
    }
    
    func rightMouseDragged(with event: NSEvent) {
        guard isEnabledAndValid else {
            return
        }
    }
    
    func rightMouseUp(with event: NSEvent) {
        guard isEnabledAndValid else {
            return
        }
        
    }
    
    func mouseDown(with event: NSEvent) {
        guard isEnabledAndValid else {
            return
        }
        
        let now = Date()
        let mouseEvt = self[.lClick]
        if let location = self.calcLocationInView(for: event, snapMode: mouseEvt.snapMode) {
            mouseEvt.rect = location.rectAroundCenter(width: mousePointRadius, height: mousePointRadius)
            mouseEvt.mouseDownPoint = mouseEvt.rect?.center
            mouseEvt.mouseDownTime = now
            dlog?.info("mouseDown .lClick location: \(location) snapMode:\(mouseEvt.snapMode)")
            _state = nil
            self.type = .lDown
        }
        
        let downEvt = self[.lDown]
        if let location = self.calcLocationInView(for: event, snapMode: downEvt.snapMode) {
            downEvt.rect = location.rectAroundCenter(width: mousePointRadius, height: mousePointRadius)
            downEvt.mouseDownPoint = downEvt.rect?.center
            downEvt.mouseDownTime = now
            dlog?.info("mouseDown .lDown location: \(location) snapMode:\(mouseEvt.snapMode)")
            _state = nil
        }
    }
    
    func mouseMoved(with event: NSEvent) {
        guard isEnabledAndValid else {
            return
        }
        let mouseEvt = self[.hover]
        if let location = self.calcLocationInView(for: event, snapMode: mouseEvt.snapMode) {
            let rect = location.rectAroundCenter(width: mousePointRadius, height: mousePointRadius)
            if mouseEvt.rect != rect || state.isEnd {
                mouseEvt.rect = rect
                self.type = .hover
            }
        }
    }
    
    private func endedMouseDrags(location:CGPoint? = nil) {
        for evtType in [MouseEvent.lDrag, MouseEvent.rDrag] {
            let dragEvt = self[evtType]
            if dragEvt.mouseDownPoint != nil {
                dlog?.info("clearing drag \(evtType)")
                if let location = location {
                    dragEvt.mouseUpPoint = location
                }
                dragEvt.mouseUpTime = Date()
                dragEvt.fadeoutRect = dragEvt.rect
                
                DispatchQueue.main.async {
                    dlog?.info("drag \(evtType) cleared")
                    dragEvt.clear()
                }
            }
        }
    }
    
    func mouseDragged(with event: NSEvent) {
        guard isEnabledAndValid else {
            return
        }
                 
        let mouseEvt = self[.lDown]
        if let location = self.calcLocationInView(for: event, snapMode: mouseEvt.snapMode) {

            var mouseDownPt = location
            var startTime = Date()
            if let pt = mouseEvt.mouseDownPoint ?? mouseEvt.rect?.center  {
                mouseDownPt = pt
            }
            if let tme = mouseEvt.mouseDownTime ?? mouseEvt.lastClickTime {
                startTime = tme
            }
            
            // distance can be replaced with distanceSqr if CPU needs become stressed
            let distanceFromStart = round(mouseDownPt.distance(to: location) * 1000) / 1000
            if distanceFromStart > 6 || abs(startTime.timeIntervalSinceNow) > 0.2 {
                // Mouse drag
                dlog?.info("drag distance:\(distanceFromStart)")
                let dragEvt = self[.lDrag]
                let curLoc = self.calcLocationInView(for: event, snapMode: dragEvt.snapMode) ?? location
                let startingExactLoc = self[.lDown].mouseDownPoint ?? dragEvt.mouseDownPoint ?? location
                let startingSnappedLoc = self.calcLocationInView(point: startingExactLoc, snapMode: dragEvt.snapMode) ?? startingExactLoc

                var stt = self.state
                if self.type != .lDrag {
                    stt = .begin
                }
                switch stt {
                case .begin:
                    dragEvt.mouseDownPoint = startingSnappedLoc
                    dragEvt.mouseDownTime =  self[.lDown].mouseDownTime ?? Date()
                    dragEvt.rect = startingSnappedLoc.rectAroundCenter(width: 1, height: 1)
                case .middle, .end:
                    if let downPoint = dragEvt.mouseDownPoint {
                        let deltaSize = CGSize(width:  curLoc.x - downPoint.x,
                                               height: curLoc.y - downPoint.y)
                        dragEvt.rect = CGRect(origin: downPoint, size: deltaSize)
                    }
                    
                    if state.isEnd {
                        self.endedMouseDrags(location: curLoc)
                    }
                }
                self.type = .lDrag
                
            } else {
                // Mouse click movement (small tolerance allows mini-drag and still count this whole operation asa a click)
                dlog?.info("small tolerance drag \(distanceFromStart)")
                self.type = .lDown
                mouseEvt.rect = location.rectAroundCenter(width: mousePointRadius, height: mousePointRadius)
            }
        }
    }
    
    func mouseUp(with event: NSEvent) {
        guard isEnabledAndValid else {
            return
        }

        // End previous event:
        let prevType = self.type
        if prevType != .lClick {
            self.endState(eventType: prevType)
        }
        
        if prevType.isADrag {
            dlog?.info("Drag mouseUp will not trigger a click")
            self[.lDown].clear()
            self[.lClick].clear()
            self[.rDown].clear()
            self[.rClick].clear()
            return
        }
        
        self.type = .lClick
        let mouseEvt = self[.lClick]
        if let location = self.calcLocationInView(for: event, snapMode: mouseEvt.snapMode) {
            
            mouseEvt.rect = location.rectAroundCenter(width: mousePointRadius, height: mousePointRadius)
            mouseEvt.mouseUpPoint = location
            let now = Date()
            mouseEvt.mouseUpTime = now
            mouseEvt.lastClickTime = now
            mouseEvt.fadeoutRect = mouseEvt.rect
            
            let key = "T\(now.timeIntervalSince1970)"
            switch event.clickCount {
            case 1:
                DispatchQueue.main.asyncAfter(delayFromNow: NSEvent.doubleClickInterval) {
                    self.mouseClicked(key: key, evt:mouseEvt)
                    self.cancelClick(key:key)
                }
            case 2:
                DispatchQueue.main.asyncAfter(delayFromNow: NSEvent.doubleClickInterval - 0.02) {
                    self.cancelClick(key:key)
                }
                dlog?.info("DBL CLICK")
                self.mouseDblClicked(evt:mouseEvt)
            default:
                break
            }
            
            self.endState(eventType: self.type)
        }
    }
    
    func mouseExited(with event: NSEvent) {
        if self.type == .hover {
            self.endState(eventType: .hover)
        }
    }
    
    func mouseEntered(with event: NSEvent) {
        self.state = .begin
        let mouseEvt = self[.hover]
        if let location = self.calcLocationInView(for: event, snapMode: mouseEvt.snapMode) {
            mouseEvt.rect = location.rectAroundCenter(width: mousePointRadius, height: mousePointRadius)
        }
        self.type = .hover
    }
    
    func cancelClick(key:String) {
        canceledKeys.append(key)
        DispatchQueue.main.asyncAfter(delayFromNow: 0.2) {
            self.canceledKeys.remove(objects: [key])
        }
    }
    
    func mouseClicked(key:String, evt:MouseTracking) {
        guard !self.canceledKeys.contains(key) else {
            dlog?.info("Click was canceled")
            return
        }
        dlog?.info("Click done")
        if let rect = self[.lClick].fadeoutRect ?? self[.lClick].rect {
            observers.enumerateOnMainThread { (observer) in
                observer.mouseClicked(type: .lClick, rect: rect)
            }
        }
    }
    
    func mouseDblClicked(evt:MouseTracking) {
        dlog?.info("DblClick done")
        if let rect = self[.lClick].fadeoutRect ?? self[.lClick].rect {
            observers.enumerateOnMainThread { (observer) in
                observer.mouseDblClicked(type:.lClick, rect: rect)
            }
        }
    }
    
    func cancelCurrentDrag() {
        if self.type == .lDrag {
            self._type = .none
            self[.lDrag].clear()
        }
    }
}
