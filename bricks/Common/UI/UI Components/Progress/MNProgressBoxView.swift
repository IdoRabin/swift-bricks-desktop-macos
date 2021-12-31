//
//  MNProgressBoxView.swift
//  Bricks
//
//  Created by Ido on 26/12/2021.
//

import AppKit

fileprivate typealias ProgressTexts = (title:String?, subtitle:String?)

fileprivate let dlog : DSLogger? = nil // DLog.forClass("MNProgressBV")

class MNProgressBoxView : NSView {
    
    // MARK: static and enum
    private let DEBUG_DRAWING = IS_DEBUG && false
    private let DEBUG_TEST_PROGRESS_OBSERVATION = IS_DEBUG && false
    private let DEBUG_INIT_WITH_CIRCLE_SHOWN = IS_DEBUG && false
    private let DEBUG_ALWAYS_HAVE_TITLE = IS_DEBUG && false
    private let DEBUG_ALWAYS_HAVE_SUBTITLE = IS_DEBUG && false
    private let DEFAULT_LEADING_PAD : CGFloat = 18
    private let DEBUG_SLOW_ANIMATIONS = IS_DEBUG && false
    
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
    fileprivate var _animatingPresentedLabels : Bool = false
    fileprivate var progressCircleUnshrunkWidth : CGFloat = 32
    fileprivate var progressCircleShrunkWidth : CGFloat = 1
    
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
    
    // MARK: Vars
    var leadingPad : CGFloat = 18.0 {
        didSet {
            self.needsLayout = true
        }
    }
    
    private var _latSubtitleWhileAnimating : String? = nil
    private func setLabels(title:String, subtitle:String, units:String, animated:Bool) {
        titleLabel.stringValue = title
        unitsLabel.stringValue = units
        
        if animated && subtitleLabel.stringValue.count > 0 && subtitle.count == 0 && _latSubtitleWhileAnimating == nil {
            _latSubtitleWhileAnimating = ""
            DispatchQueue.main.asyncAfter(delayFromNow: 0.24) {
                self.subtitleLabel.stringValue = self._latSubtitleWhileAnimating ?? ""
                self._latSubtitleWhileAnimating = nil
            }
        } else if !_animatingPresentedLabels {
            subtitleLabel.stringValue = subtitle
            _latSubtitleWhileAnimating = nil
        } else {
            _latSubtitleWhileAnimating = subtitle
        }
        
        self.updateLabelsConstraints(animated: animated)
    }
    
    private func updateLabelsConstraints(animated:Bool) {
        
        func exec() {
             // dlog?.info("updateLabelsConstraints labels: \(lastLabelsPresentedCount) animated: \(animated)")
            
            // TODO: See why this is doesn't trigger implicit animations
            titleLabelCenterYConstraint.constant = isShowsTwoLabels ?    /* top half */   -6.0 : 0.0 /* center y */
            subtitleLabelBottomConstraint.constant = isShowsTwoLabels ?  /* bottom half */ -1.0 : -18.0 /* hidden below bottom */
            subtitleLabel.alphaValue = isShowsTwoLabels ? 1.0 : 0.0
        }
        
        let duration : TimeInterval = DEBUG_SLOW_ANIMATIONS ? 0.34 :  0.22
        var isShowsTwoLabels = titleLabel.stringValue.count > 0 && subtitleLabel.stringValue.count > 0
        if let sut = _latSubtitleWhileAnimating, sut.count == 0 {
            isShowsTwoLabels = false
        }
        let newLabelsPresentedCount = isShowsTwoLabels ? 2 : 1
        if lastLabelsPresentedCount != newLabelsPresentedCount {
            lastLabelsPresentedCount = newLabelsPresentedCount
            if animated {
                if _animatingPresentedLabels && newLabelsPresentedCount == 1 {
                    // This can wait
                    dlog?.info("updateLabelsConstraints will wait: already animating")
                    DispatchQueue.main.asyncAfter(delayFromNow: duration + 0.01) {
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
            dlog?.info("first layout - circle progressWidthConstraint will be \(self.bounds.height)")
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
            dlog?.info("setup height: \(self.bounds.height) circle progressWidthConstraint: \(progressWidthConstraint.constant) sze: \(progressCircle.frame.size)")
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
//        progressCircle?.clearAllClosureProperties() // will deinit nicely even if we have a cyclic reference in the blocks..
        TestMNProgressEmitter.shared.observers.remove(observer: self)
        dlog?.info("deinit")
    }
    
    // MARK: Public
    func updateWithDoc(_ doc:BrickDoc?) {
        dlog?.info("updateWithDoc \((doc?.displayName).descOrNil) updating progress hidden: \(doc != nil)")
        
        setLabels(title: DEBUG_DRAWING || DEBUG_ALWAYS_HAVE_TITLE ? "Lorem ipsum title" :  "",
                  subtitle: DEBUG_DRAWING || DEBUG_ALWAYS_HAVE_SUBTITLE ? "Lorem ipsum subtitle is longer." :  "",
                  units: DEBUG_DRAWING || DEBUG_ALWAYS_HAVE_TITLE ? "0/100" : "",
                  animated: false)
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
        if IS_DEBUG {
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
                                      forcedProgressCircleState:ProgressCircleState? = nil) {
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

            let duration : TimeInterval = DEBUG_SLOW_ANIMATIONS ? 1.5 : 0.25
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
                        dlog?.info("iconPresentationInfo presented")
                        self.updateCircleProgress(withProgress: newProgress,
                                                  animated: animated,
                                                  iconPresentation: nil,
                                                  forcedProgressCircleState: .hidden)
                    })
                }
            }

        }
    }
    
    private func update(with mnProgress:MNProgress) {
        
        // Calc title and subtitle:
        var texts = self.calcProgressTexts(with: mnProgress)
        
        // Update misc. using the state:
        var forceCircleState : ProgressCircleState? = nil
        var iconPresentation : CircleProgressView.IconPresentationInfo? = nil
        
        // Complete icon presentation:
        var unitsLabelColor : NSColor = NSColor.secondaryLabelColor.blended(withFraction: 0.4, of: NSColor.tertiaryLabelColor) ?? NSColor.tertiaryLabelColor
        switch mnProgress.state {
        case .pending:
            forceCircleState = .hidden
        case .inProgress:
            break
        case .success, .failed, .userCanceled:
            dlog?.info("Will present Icon for state: \(mnProgress.state)")
            
            if let img = mnProgress.state.iconImage { //}, self.progressCircle?.isContentsShrunk == false {
                let color = mnProgress.state.iconTintColor
                let bkgColor = mnProgress.state.iconBkgColor
                iconPresentation = CircleProgressView.IconPresentationInfo(image: img, tint: color, bkgColor: bkgColor, duration: 1.5)
                unitsLabelColor = color.darker(part: 0.25).desaturate(part0to1: 0.85)
            } else {
                dlog?.note("failed presenting icon for state: \(mnProgress.state) iconName: [\(mnProgress.state.imageSystemSymbolName)]")
            }
        }
        
        // Update progress percentages:
        self.progressCircle?.progressType = mnProgress.isLongTimeAction ? .determinateSpin : .determinate
        self.updateCircleProgress(withProgress: mnProgress.fractionCompleted,
                                  animated: self.window != nil,
                                  iconPresentation: iconPresentation,
                                  forcedProgressCircleState:forceCircleState)
        // Update center text?
        // self.progressCircle.centerText = "\(Int(floor(mnProgress.fractionCompleted * 35)))"
        
        // Update label
        if texts.title == nil && texts.subtitle == nil, let lastRecv = self.lastRecievedProgressTexts {
            texts = lastRecv
        } else {
            self.lastRecievedProgressTexts = texts
        }
        
        let unitsTitle = "|\(String.NBSP)" + (mnProgress.discreteStructOrNil?.progressUnitsDisplayString ?? mnProgress.fractionCompletedDisplayString)
        self.unitsLabel.textColor = unitsLabelColor
        self.setLabels(title: texts.title ?? "",
                       subtitle: texts.subtitle ?? "",
                       units: unitsTitle,
                       animated: self.window != nil)
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
