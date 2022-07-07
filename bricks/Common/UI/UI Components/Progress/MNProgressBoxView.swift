//
//  MNProgressBoxView.swift
//  Bricks
//
//  Created by Ido on 26/12/2021.
//

import AppKit

fileprivate typealias ProgressTexts = (title:String?, subtitle:String?)

fileprivate let dlog : DSLogger? = DLog.forClass("MNProgressBV")

protocol MNProgressBoxViewObserver {
    func mnProgressBoxView(_ view:MNProgressBoxView, didLeftMouseDown:NSEvent)
    func mnProgressBoxView(_ view:MNProgressBoxView, didRightMouseDown:NSEvent)
}

class MNProgressBoxView : NSView {
    static let dateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd HH:mm:ss.SSS")
    var observers = ObserversArray<MNProgressBoxViewObserver>()
    
    // MARK: static and enum
    private let DEBUG_DRAWING = Debug.IS_DEBUG && false
    private let DEBUG_TEST_PROGRESS_OBSERVATION = Debug.IS_DEBUG && false
    private let DEBUG_INIT_WITH_CIRCLE_SHOWN = Debug.IS_DEBUG && false
    private let DEBUG_ALWAYS_HAVE_TITLE = Debug.IS_DEBUG && false
    private let DEBUG_ALWAYS_HAVE_SUBTITLE = Debug.IS_DEBUG && false
    private let DEFAULT_LEADING_PAD : CGFloat = 18.0
    private let DEBUG_SLOW_ANIMATIONS = Debug.IS_DEBUG && false
    
    private let COPY_MENU_ITEM_ID = "mnProgressBoxViewCopyMenuItemID"
    private let VIEW_LOG_MENU_ITEM_ID = "mnProgressBoxViewLogMenuItemID"
    
    private enum ProgressCircleState {
        case visible
        case hidden
        var isVisible : Bool { return self == .visible }
    }
    
    // MARK: UI outlets
    @IBOutlet weak var progressWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressCircle: CircleProgressView!
    
    @IBOutlet weak var leadingPadConstraint: NSLayoutConstraint!
    @IBOutlet weak var unitsLabel: NSTextField!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var titleLabelCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var subtitleLabelBottomConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    fileprivate var lastRecievedProgressTexts : ProgressTexts? = nil
    fileprivate var lastLabelsPresentedCount : Int = 0
    fileprivate(set) var lastLogEntry : String = ""
    fileprivate var _animatingPresentedLabels : Bool = false
    fileprivate var progressCircleUnshrunkWidth : CGFloat = 32
    fileprivate var progressCircleShrunkWidth : CGFloat = 1
    fileprivate var lastMouseDownLoc : CGPoint? = nil
    
    private(set) var isPopupMenuPresented : Bool = false
    private(set) var isPopupMenuClosing : Bool = false
    private(set) var isUpdatingMNProgress : Bool = false
    
    @IBInspectable var title : String {
        get {
            return titleLabel.stringValue
        }
        set {
            if titleLabel.stringValue != newValue {
                titleLabel.stringValue = newValue
                self.updateLabelsConstraints(animated: self.window != nil)
            }
        }
    }
    
    @IBInspectable var subtitle : String {
        get {
            return subtitleLabel.stringValue
        }
        set {
            if subtitleLabel.stringValue != newValue {
                subtitleLabel.stringValue = newValue
                self.updateLabelsConstraints(animated: self.window != nil)
            }
        }
    }
    
    @IBInspectable var units : String {
        get {
            return unitsLabel.stringValue
        }
        set {
            if unitsLabel.stringValue != newValue {
                unitsLabel.stringValue = newValue
                self.updateLabelsConstraints(animated: self.window != nil)
            }
        }
    }
    
    @IBInspectable var progress : CGFloat {
        get {
            return progressCircle.progress
        }
        set {
            if progressCircle.progress != newValue {
                progressCircle.progress = newValue
            }
        }
    }
    
    fileprivate var progressIsHidden : Bool {
        get {
            progressCircle.isHidden
        }
        set {
            if progressCircle.isHidden != newValue {
                progressCircle.isHidden = newValue
            }
        }
    }
    
    var copyMenuItem : NSMenuItem? {
        return menu?.items.filter(ids: [COPY_MENU_ITEM_ID]).first
    }
    
    var viewLogMenuItem : NSMenuItem? {
        return menu?.items.filter(ids: [VIEW_LOG_MENU_ITEM_ID]).first
    }
    
    // MARK: Vars
    var leadingPad : CGFloat = 18.0 {
        didSet {
            self.needsLayout = true
        }
    }
    
    private var _lastSubtitleWhileAnimating : String? = nil
    private func setLabels(title:String, subtitle:String, units:String, animated:Bool) {
        guard titleLabel.stringValue != title ||
              subtitleLabel.stringValue != subtitle ||
              unitsLabel.stringValue != units else {
            return
        }
        
        self.selectsAllText = false
        if titleLabel.stringValue != title {
            titleLabel.stringValue = title
        }
        if unitsLabel.stringValue != units {
            unitsLabel.stringValue = units
        }
        
        if subtitleLabel.stringValue != subtitle {
            
            if animated && subtitleLabel.stringValue.count > 0 && subtitle.count == 0 && _lastSubtitleWhileAnimating == nil {
                // This case is ONLY for when new subtitle label is an empty string ("")
                _lastSubtitleWhileAnimating = "" // Clear subtitle...
                self.clearUnitsTitle(animated: true, delay: animated ? (DEBUG_SLOW_ANIMATIONS ? 0.35 : 0.24) : 0.05) {
                    self.subtitleLabel.stringValue = subtitle
                    self._lastSubtitleWhileAnimating = nil
                    self.updateLabelsConstraints(animated: animated)
                }
            } else if !_animatingPresentedLabels {
                subtitleLabel.stringValue = subtitle
                _lastSubtitleWhileAnimating = nil
            } else {
                _lastSubtitleWhileAnimating = subtitle
            }
        }
        
        // Log entry:
        updateLastLogEntry()
        
        self.updateLabelsConstraints(animated: animated)
    }
    
    private func updateLastLogEntry() {
        var unts = units
        if unts.count == 0 && (self.progress > 0.0 || self.progressIsHidden == false) {
            unts = (self.progress * 100).toString(dec: 0) + "%"
        }
        unts = unts.trimmingCharacters(in: .whitespacesAndNewlines).trimming(string: "|").trimmingCharacters(in: .whitespacesAndNewlines).paddingLeft(toLength: 4, withPad: " ").replacingOccurrences(ofFromTo: [" " : String.FIGURE_SPACE])
        let dateStr = Self.dateFormatter.string(from: Date())
        
        // Compose all values:
        var newLogEntry = "\(dateStr) | \(unts) | \(title)"
        if subtitle.count > 0 && _lastSubtitleWhileAnimating != "" {
            newLogEntry += " | \(subtitle)"
        }
        if lastLogEntry != newLogEntry {
            lastLogEntry = newLogEntry
            // dlog?.info("LOGE: \(newLogEntry)")
            // Push into log file...
        }
    }
    
    private func updateLabelsConstraints(animated:Bool) {
        
        func exec() {
            let labs = (lastLabelsPresentedCount == 2)
             // dlog?.info("updateLabelsConstraints labels: \(lastLabelsPresentedCount) animated: \(animated)")
            
            // TODO: See why this is doesn't trigger implicit animations
            titleLabelCenterYConstraint.constant = labs ?    /* top half */   -6.0 : 0.0 /* center y */
            subtitleLabelBottomConstraint.constant = labs ?  /* bottom half */ -1.0 : -18.0 /* hidden below bottom */
            subtitleLabel.alphaValue = labs ? 1.0 : 0.0
        }
        
        let duration : TimeInterval = animated ? (DEBUG_SLOW_ANIMATIONS ? 0.34 :  0.22) : 0.17
        var isShowsTwoLabels = titleLabel.stringValue.count > 0 && subtitleLabel.stringValue.count > 0
        if let sut = _lastSubtitleWhileAnimating, sut.count == 0 {
            isShowsTwoLabels = false
        }
        let newLabelsPresentedCount = isShowsTwoLabels ? 2 : 1
        if lastLabelsPresentedCount != newLabelsPresentedCount {
            lastLabelsPresentedCount = newLabelsPresentedCount
            if animated {
                if _animatingPresentedLabels && newLabelsPresentedCount == 1 {
                    // This can wait
                    // dlog?.note("updateLabelsConstraints will wait: already animating")
                    DispatchQueue.main.asyncAfter(delayFromNow: duration + 0.01) {
                        self.lastLabelsPresentedCount = 0 // "Force" change
                        self.updateLabelsConstraints(animated: true)
                    }
                    return
                }
                
                _animatingPresentedLabels = true
                NSView.animate(duration: duration, delay: 0.04) { context in
                    context.allowsImplicitAnimation = true
                    exec()
                    self.superview?.superview?.layoutSubtreeIfNeeded()
                } completionHandler: {
                    self._animatingPresentedLabels = false
                }
            } else {
                exec()
            }
        }
    }

    // MARK: Private
    
    override func layout() {
        super.layout()
        DispatchQueue.main.performOncePerInstance(self) {
            // dlog?.info("first layout - circle progressWidthConstraint will be \(self.bounds.height)")
            let newH = self.bounds.height
            progressCircleUnshrunkWidth = newH
            updateLabelsConstraints(animated: false)
            
            // Hide progress circle on init
            if DEBUG_INIT_WITH_CIRCLE_SHOWN {
                progressWidthConstraint.constant = progressCircleUnshrunkWidth
                progressCircle.progress = 0.0
                progressCircle.alphaValue = 1.0
            } else {
                self.leadingPadConstraint.constant = leadingPad + newH
                self.leadingPadConstraint.priority = .defaultHigh
                progressCircle.progress = 0.0
                progressCircle.alphaValue = 0.0
                progressWidthConstraint.constant = progress > 0.0 ? newH : 0.0
            }
            
        }
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.setup()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.setup()
        
        if DEBUG_DRAWING {
            self.debugBorders(downtree: true, alpha: 0.5)
            self.progressCircle.debugBorder(color: .red, width: 1)
        }
    }
    
    func setup() {
        guard self.superview != nil && self.window != nil else {
            return
        }
        DispatchQueue.main.performOncePerInstance(self) {
            //dlog?.info("setup height: \(self.bounds.height) circle progressWidthConstraint: \(progressWidthConstraint.constant) sze: \(progressCircle.frame.size)")
            self.menu?.delegate = self
        }
    }
    
    // MARK: Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        dlog?.info("awakeFromNib \(self.basicDesc) window: \(self.window?.basicDesc ?? "<nil>" )")
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    deinit {
        // progressCircle?.clearAllClosureProperties() // will deinit nicely even if we have a cyclic reference in the blocks..
        TestMNProgressEmitter.shared.observers.remove(observer: self)
        dlog?.info("deinit")
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        super.menu(for: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        lastMouseDownLoc = event.locationInWindow
        // dlog?.info("mouseDown \(isPopupMenuPresented)")
        if self.isPopupMenuPresented {
            // Hide menu
            
        } else {
            self.observers.enumerateOnMainThread { observer in
                observer.mnProgressBoxView(self, didLeftMouseDown: event)
            } completed: {
                
            }
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if self.isPopupMenuPresented {
            if !self.isPopupMenuClosing {
                
            }
        } else {
            super.rightMouseDown(with: event)
            lastMouseDownLoc = event.locationInWindow
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return false
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        if NSEvent.pressedMouseButtons == 2, let window = self.window, self.isPopupMenuPresented == false { // right mouse button
            let loc = self.convert(point, to: window.contentView)
            self.lastMouseDownLoc = loc
            self.presentPopUpContextMenu(event: nil)
        }
        return result
    }
    
    // MARK: Text Selection
    fileprivate func isSel(label:NSTextField)->Bool {
        return label.textColor == .selectedTextColor
    }
    
    fileprivate func setSel(seleted sel: Bool, label:NSTextField, col:NSColor) {
        label.wantsLayer = true
        if label.stringValue.count > 0 {
            var alayer : CAShapeLayer? = label.layer?.sublayers?.first(where: { blayer in
                blayer is CAShapeLayer
            }) as? CAShapeLayer
            if sel {
                let rect = label.stringValue.boundingRect(with: label.bounds.size, options: .usesLineFragmentOrigin, attributes: label.attributedStringValue.attributes(at: 0, effectiveRange: nil), context: nil).rounded().insetBy(dx: -1, dy: -1)
                if alayer == nil {
                    alayer = CAShapeLayer()
                    alayer?.frame = rect
                    //alayer?.filters = []
                    alayer?.compositingFilter = "screenBlendMode" // multiplyBlendMode"
                    // alayer?.path = CGPath(rect: rect.boundsRect(), transform: nil)
                    label.layer?.insertSublayer(alayer!, below: nil)
                }
            } else {
                alayer?.removeFromSuperlayer()
            }
            
            alayer?.backgroundColor =  sel ? NSColor.controlAccentColor.withAlphaComponent(0.8).cgColor : NSColor.clear.cgColor
            label.textColor = sel ? .selectedTextColor : col
        }
    }
    
    var isAllTextSeleted : Bool {
        return isSel(label: self.titleLabel) && isSel(label: subtitleLabel) && isSel(label: unitsLabel)
    }
    
    @IBInspectable var selectsAllText : Bool = true {
        didSet {
            self.setSel(seleted: selectsAllText, label: self.titleLabel, col: .secondaryLabelColor)
            self.setSel(seleted: selectsAllText, label: self.subtitleLabel, col: .tertiaryLabelColor)
            self.setSel(seleted: selectsAllText, label: self.unitsLabel, col: .tertiaryLabelColor)
        }
    }
    
    func presentPopUpContextMenu(event:NSEvent?) {
        guard let menu = self.menu, let window = window, isPopupMenuPresented == false else {
            return
        }
        
        let evt : NSEvent = event ?? {
            let loc = lastMouseDownLoc ?? self.convert(self.bounds.center, to: window.contentView)
            let newEvent = NSEvent.mouseEvent(with: .rightMouseDown,
                                            location: loc,
                                            modifierFlags: [], timestamp: Date().timeIntervalSince1970, windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 0, pressure: 1)!
            return newEvent
        }()
        
        isPopupMenuPresented = true
        menu.update()
        NSMenu.popUpContextMenu(menu, with: evt, for: self)
    }
    
    // MARK: Public
    func clearUnitsTitle(animated:Bool = true, delay:TimeInterval = 0.0, completion: (()->Void)? = nil) {
        func exec() {
            self._lastSubtitleWhileAnimating = nil
            self.updateLabelsConstraints(animated: animated)
            self.superview?.superview?.layoutSubtreeIfNeeded()
        }
        DispatchQueue.main.asyncAfter(delayFromNow: delay) {
            self.unitsLabel.animatedClearCharsLIFO(duration: self.DEBUG_SLOW_ANIMATIONS ? 0.25 :  0.17) {
                exec()
                completion?()
            }
        }
    }
    
    func hideCircleProgress(animated:Bool = true, reset:Bool = true, completion: (()->Void)? = nil) {
        self.updateCircleProgress(withProgress: 0.0,
                                  animated: animated,
                                  iconPresentation: nil,
                                  forcedProgressCircleState: .hidden,
                                  completion: completion)
    }
    
    func updateWithDoc(_ doc:BrickDoc?) {
        guard doc != nil else {
            // No document
            dlog?.warning("updateWithDoc(<nil>) hides progress circle!")
            self.hideCircleProgress()
            return
        }
        
        let ttle = DEBUG_DRAWING || DEBUG_ALWAYS_HAVE_TITLE ? "Lorem ipsum title" :  ""
        let subttle = DEBUG_DRAWING || DEBUG_ALWAYS_HAVE_SUBTITLE ? "Lorem ipsum subtitle is longer." :  ""
        let unitsStr = DEBUG_DRAWING || DEBUG_ALWAYS_HAVE_TITLE ? "0/100" : ""
        
        if self.isUpdatingMNProgress {
            return
        }
        
        if self.title != ttle ||
            self.subtitle != subttle ||
            units != unitsStr {
            dlog?.info("updateWithDoc \((doc?.displayName).descOrNil) updating progress hidden: \(doc != nil)")
            
            setLabels(title: ttle,
                      subtitle: subttle,
                      units: unitsStr,
                      animated: false)
        }
        
        
        // progressCircle?.resetToZero(animated: true, hides: true, completion: nil)
        
        DispatchQueue.main.async {
            if self.DEBUG_TEST_PROGRESS_OBSERVATION {
                self.debugTestProgressObservations()
            }
        }
    }
    
    private func calcProgressTexts(with mnProgress:MNProgress)->ProgressTexts {
        var title = mnProgress.title
        var subtitle = mnProgress.subtitle
        if mnProgress.state.isComplete && title?.count ?? 0 == 0 {
            title = mnProgress.state.displayString
        }
        if let error = mnProgress.error, subtitle == nil {
            if title == nil {
                title = error.localizedDescription
                subtitle = "\(error.domainCodeDesc)"
            } else {
                subtitle = "\(error.domainCodeDesc) \(error.localizedDescription)"
            }
        }
        
        // Debugging only:
        if Debug.IS_DEBUG {
            if DEBUG_ALWAYS_HAVE_TITLE && title?.count ?? 0 == 0 {
                title = "DEBUG always have lg title"
            }
            if DEBUG_ALWAYS_HAVE_SUBTITLE && subtitle?.count ?? 0 == 0 {
                subtitle = "DEBUG always have subtitle lg Fox jumps fence ipsum!"
            }
        }
        
        return ProgressTexts(title:title, subtitle:subtitle)
    }
    
    private var currentCircleState : ProgressCircleState {
        return (progressCircle.isHidden || progressCircle.alphaValue == 0.0 || progressWidthConstraint.constant < 2) ? .hidden : .visible
    }
    
    private func updateCircleProgress(withProgress newProgress:CGFloat,
                                      animated:Bool,
                                      iconPresentation:CircleProgressView.IconPresentationInfo?,
                                      forcedProgressCircleState:ProgressCircleState? = nil,
                                      completion: (()->Void)? = nil
    ) {
        let prevCircleState : ProgressCircleState = self.currentCircleState
        var newCircleState : ProgressCircleState = .visible
        let prevProgress = progressCircle.progress
        let curCircleState = self.currentCircleState
        
        // Determine required state:
        if (prevProgress <= 0.0 || curCircleState == .hidden) && newProgress > 0.0 {
            newCircleState = .visible
        } else if (prevProgress <= 1.0 || curCircleState == .visible) && newProgress > 1.0 {
            newCircleState = .hidden
        } else {
            newCircleState = forcedProgressCircleState ?? .visible
        }
        
        let isShouldShowIcon = ((iconPresentation != nil) != progressCircle.isIconPresented)
        
        // Update progress regardless of state:
        progressCircle.progress = newProgress
        
        if (newCircleState != prevCircleState || isShouldShowIcon) {

            let duration : TimeInterval = animated ? (DEBUG_SLOW_ANIMATIONS ? 1.5 : 0.25) : 0.17
            NSView.animate(duration: duration, delay: 0.0) {[self] context in
                context.allowsImplicitAnimation = true
                self.progressWidthConstraint.animator().constant = newCircleState.isVisible ? progressCircleUnshrunkWidth : progressCircleShrunkWidth
                self.leadingPadConstraint.animator().constant = newCircleState.isVisible ? leadingPad : leadingPad + (progressCircleUnshrunkWidth - progressCircleShrunkWidth)
                
                if (newCircleState != prevCircleState) {
                    switch newCircleState {
                    case .visible:
                        self.progressCircle.alphaValue = 1.0
                    case .hidden:
                        self.progressCircle.alphaValue = 0.0
                    }
                }
            } completionHandler: {
                if isShouldShowIcon, let iconPresentation = iconPresentation {
                    self.progressCircle.presentIcon(info: iconPresentation, completion:{
                        // dlog?.info("iconPresentationInfo presented")
                        self.updateCircleProgress(withProgress: newProgress,
                                                  animated: animated,
                                                  iconPresentation: nil,
                                                  forcedProgressCircleState: .hidden,
                                                  completion: completion)
                    })
                } else {
                    completion?()
                }
            }
            
        } else {
            
            completion?()
        }
    }
    
    private func updateCenterTexts(mnProgress:MNProgress,texts txts: ProgressTexts, unitsLabelColor:NSColor, forceCircleState:ProgressCircleState? = nil) {
        var texts : ProgressTexts = txts
        // Update center text?
        // self.progressCircle.centerText = "\(Int(floor(mnProgress.fractionCompleted * 35)))"
        
        // Update label
        if texts.title == nil && texts.subtitle == nil, let lastRecv = self.lastRecievedProgressTexts {
            texts = lastRecv
        } else {
            self.lastRecievedProgressTexts = texts
        }
        
        let unitsTitle : String = "|\(String.NBSP)" + (mnProgress.discreteStructOrNil?.progressUnitsDisplayString ?? mnProgress.fractionCompletedDisplayString)
        self.unitsLabel.textColor = unitsLabelColor
        self.setLabels(title: texts.title ?? "",
                       subtitle: texts.subtitle ?? "",
                       units: unitsTitle,
                       animated: self.window != nil)
        if forceCircleState ?? .visible == .hidden {
            self.clearUnitsTitle(animated: self.window != nil, completion: nil)
        }
    }
    
    func basicUpdate(state:MNProgressState, title:String?, subtitle:String?, progress:CGFloat? = nil) {
        var mnProgress = MNProgress(completed: state, title: title ?? "", subtitle: subtitle, info: nil)
        if let progress = progress {
            do {
                try mnProgress.setProgress(fractionCompleted: progress)
            } catch let error {
                dlog?.warning("mnProgress.setProgress failed with error:\(error.localizedDescription)")
            }
        }
        
        dlog?.info("basicUpdate \(title.descOrNil) | \(subtitle.descOrNil) progress:\(progress.descOrNil)")
        
        self.update(with: mnProgress)
    }
    
    private func isShouldCollapseUnitsLabel(mnProgress:MNProgress)->Bool {
        if mnProgress.title?.lowercased() == AppStr.READY.localized().lowercased() ||
                self.title.lowercased() == AppStr.READY.localized().lowercased() {
            if mnProgress.fractionCompleted == 1.0 || mnProgress.state == .success {
                return true
            }
        }
        return false
    }
    
    private func internal_update(with mnProgress:MNProgress) {
        // Assuming run on mainThread:
        self.isUpdatingMNProgress = true
        let ttle = mnProgress.title ?? "<no title>"
        dlog?.info("update with mnProgress \(ttle) START")
        DLog.indentStart(logger: dlog)
        
        // Clear previous selection
        self.selectsAllText = false
        
        // Calc title and subtitle:
        let texts = self.calcProgressTexts(with: mnProgress)
        
        // Update misc. using the state:
        var forceCircleState : ProgressCircleState? = nil
        var iconPresentation : CircleProgressView.IconPresentationInfo? = nil
        
        // Complete icon presentation:
        var unitsLabelColor : NSColor = NSColor.secondaryLabelColor.blended(withFraction: 0.4, of: NSColor.tertiaryLabelColor) ?? NSColor.tertiaryLabelColor
        switch mnProgress.state {
        case .idle, .pending:
            forceCircleState = .hidden
        case .inProgress:
            break
        case .success, .failed, .userCanceled:
            dlog?.info("Will present Icon for state: \(mnProgress.state)")
            
            if let img = mnProgress.state.iconImage { //}, self.progressCircle?.isContentsShrunk == false {
                let color = mnProgress.state.iconTintColor
                let bkgColor = mnProgress.state.iconBkgColor
                iconPresentation = CircleProgressView.IconPresentationInfo(image: img, tint: color, bkgColor: bkgColor, duration: 1.5)
                unitsLabelColor = color.darker(part: self.isDarkThemeActive ? -0.15 :  0.15).desaturate(part0to1: 0.85)
            } else {
                dlog?.note("failed presenting icon for state: \(mnProgress.state) iconName: [\(mnProgress.state.imageSystemSymbolName)]")
            }
        }
        
        // Update progress percentages:
        self.progressCircle?.progressType = mnProgress.isLongTimeAction ? .determinateSpin : .determinate
        self.updateCircleProgress(withProgress: mnProgress.fractionCompleted,
                                  animated: self.window != nil,
                                  iconPresentation: iconPresentation,
                                  forcedProgressCircleState:forceCircleState) {
            DispatchQueue.mainIfNeeded {
                self.updateCenterTexts(mnProgress: mnProgress, texts: texts, unitsLabelColor: unitsLabelColor, forceCircleState: forceCircleState)
                DLog.indentEnd(logger: dlog)
                dlog?.info("update with mnProgress \(ttle) END")
                if self.isShouldCollapseUnitsLabel(mnProgress:mnProgress) {
                    let animated = (self.window != nil)
                    let delay : TimeInterval = animated ? (self.DEBUG_SLOW_ANIMATIONS ? 0.35 : 0.24) : 0.05
                    self.clearUnitsTitle(animated: animated, delay: delay, completion: nil)
                }
                self.isUpdatingMNProgress = false
            }
        }
    }
    
    func update(with mnProgress:MNProgress) {
        guard Thread.current.isMainThread else {
            DispatchQueue.mainIfNeeded {
                self.update(with: mnProgress)
            }
            return
        }
        
        waitFor("isUpdatingMNProgress == false", testOnMainThread: {
            self.isUpdatingMNProgress == false
        }, completion: { waitResult in
            DispatchQueue.mainIfNeeded {
                self.internal_update(with: mnProgress)
            }
        }, logType: .never)
    }
}

extension MNProgressBoxView : MNProgressObserver {
    
    func mnProgress(sender: Any, isPendingProgress mnProgress: MNProgress, fraction: Double, discretes: DiscreteMNProg?) {
        dlog?.info("xMNProgress     isPendingProgress \(mnProgress)")
    }
    
    func mnProgress(sender: Any, didStartProgress mnProgress: MNProgress, fraction: Double, discretes: DiscreteMNProg?) {
        dlog?.info("xMNProgress     didStartProgress \(mnProgress)")
        self.update(with: mnProgress)
    }
    
    func mnProgress(sender: Any, didProgress mnProgress: MNProgress, fraction: Double, discretes: DiscreteMNProg?) {
        dlog?.info("xMNProgress     didProgress \(mnProgress)")
        self.update(with: mnProgress)
    }
    
    func mnProgress(sender: Any, didComplete mnProgress: MNProgress, state: MNProgressState) {
        dlog?.info("xMNProgress     didComplete \(mnProgress)")
        self.update(with: mnProgress)
    }
}

extension MNProgressBoxView : NSMenuDelegate {
    
    func menuWillOpen(_ menu: NSMenu) {
        // Will load doc:
        //dlog?.info("menuWillOpen..")
        self.selectsAllText = true
        DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
            // dlog?.info("menuWillOpen.. DONE")
            self.isPopupMenuPresented = true
        }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // dlog?.info("menuDidClose.. ")
        self.isPopupMenuClosing = true
        self.selectsAllText = false
        
        DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
            self.isPopupMenuPresented = false
            self.isPopupMenuClosing = false
            // dlog?.info("menuDidClose.. DONE")
        }
    }
}

extension MNProgressBoxView  /* debugging */ {
    
    func debugTestProgressObservations() {
        guard DEBUG_TEST_PROGRESS_OBSERVATION else {
            return
        }
        dlog?.info("debugTestProgressObservations")
        TestMNProgressEmitter.shared.observers.add(observer: self)
        TestMNProgressEmitter.shared.timedTest(delay: 0.5,
                                               interval: 0.1,
                                               changesCount: 70,
                                               finishWith: .failure(AppError(AppErrorCode.misc_unknown, detail: "Final call of test")),
                                               observerToAdd: self)
    }
    
}
