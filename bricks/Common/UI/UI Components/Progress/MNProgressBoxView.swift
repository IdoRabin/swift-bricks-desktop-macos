//
//  MNProgressBoxView.swift
//  Bricks
//
//  Created by Ido on 26/12/2021.
//

import AppKit

fileprivate typealias ProgressTexts = (title:String?, subtitle:String?)

fileprivate let dlog : DSLogger? = DLog.forClass("MNProgressBV")

class MNProgressBoxView : NSView {
    
    // MARK: static and enum
    private let DEBUG_DRAWING = IS_DEBUG && false
    private let DEBUG_TEST_PROGRESS_OBSERVATION = IS_DEBUG && false
    private let DEBUG_ALWAYS_HAVE_TITLE = IS_DEBUG && false
    private let DEBUG_ALWAYS_HAVE_SUBTITLE = IS_DEBUG && false
    
    private enum ProgressCircleState {
        case visible
        case hidden
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
            // leadingPadConstraint.animator().constant = leadingPad
        }
    }
    
    private func setLabels(title:String, subtitle:String, units:String, animated:Bool) {
        titleLabel.stringValue = title
        subtitleLabel.stringValue = subtitle
        unitsLabel.stringValue = units
        
        self.updateLabelsConstraints(animated: animated)
    }
    
    private func updateLabelsConstraints(animated:Bool) {
        
        func exec() {
            dlog?.info("updateLabelsConstraints labels: \(lastLabelsPresentedCount)")
            titleLabelCenterYConstraint.constant = isShowsTwoLabels ? 0.0 : 0.0
            subtitleLabel.alphaValue = isShowsTwoLabels ? 1.0 : 0.0
            subtitleLabelBottomConstraint.constant = isShowsTwoLabels ? -2.0 : -18.0
        }
        
        let isShowsTwoLabels = titleLabel.stringValue.count > 0 && subtitleLabel.stringValue.count > 0
        let newLabelsPresentedCount = isShowsTwoLabels ? 2 : 1
        if lastLabelsPresentedCount != newLabelsPresentedCount {
            lastLabelsPresentedCount = newLabelsPresentedCount
            if animated {
                NSView.animate(duration: 0.2) { context in
                    context.allowsImplicitAnimation = true
                    exec()
                }
            } else {
                exec()
            }
        }
    }

    // MARK: Private
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.setup()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.setup()
        
        if DEBUG_DRAWING {
            self.debugBorders(downtree: true, alpha: 0.5)
        }
    }
    
    func setup() {
        guard self.superview != nil && self.window != nil else {
            return
        }
        DispatchQueue.main.performOncePerInstance(self) {
            dlog?.info("setup height: \(self.bounds.height) circleWidth: \(progressWidthConstraint.constant) sze: \(progressCircle.frame.size)")

            // Init using the awoken up hidden state:
            if progressWidthConstraint != nil && progressCircle.widthConstraint == nil {
                progressCircle.widthConstraint = progressWidthConstraint
            }
//            progressWidthConstraint.constant = progressCircle.isHidden ? 0.0 : 32.0
//            progressCircle.setIsHidden(progressCircle.isHidden, animated: false, isForced: true)
            let targetW : CGFloat = 2
            progressCircle.onShrinking = {[weak self] (context) in
                // let existingW = self?.progressCircle.bounds.width ?? 28
                //self?.progressWidthConstraint.animator().constant = targetW
//                self?.leadingPadConstraint.constant = 18 + existingW - targetW
            }
            progressCircle.onUnshrinking = {[weak self] (context) in
                //self?.progressWidthConstraint.animator().constant = 28
//                self?.leadingPadConstraint.constant = 18
            }
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
        progressCircle?.clearAllClosureProperties() // will deinit nicely even if we have a cyclic reference in the blocks..
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
    
    private func update(with mnProgress:MNProgress) {
        
        // Calc title and subtitle:
        var texts = self.calcProgressTexts(with: mnProgress)
        
        // Update progress percentages:
        self.progressCircle?.progressType = mnProgress.isLongTimeAction ? .determinateSpin : .determinate
        self.progressCircle?.progress = mnProgress.fractionCompleted
        
        // Update misc. using the state:
        switch mnProgress.state {
        case .pending:
            self.progressCircle?.isHidden = true
            
        case .inProgress:
            if self.progressCircle?.isHidden == true {
                self.progressCircle?.isHidden = false
            }
        case .success, .failed, .userCanceled:
            dlog?.info("Will present Icon for state: \(mnProgress.state)")
            
            if self.progressCircle?.isHidden == false, let img = mnProgress.state.iconImage {
                let color = mnProgress.state.iconTintColor
                let bkgColor = mnProgress.state.iconBkgColor
                self.progressCircle?.presentIcon(image: img, tint: color, bkgColor: bkgColor, completion: {
                    self.progressCircle?.setIsShrunk(true, animated: true, isForced: false, isDelay: false)
                })
            } else {
                dlog?.note("failed presenting icon for state: \(mnProgress.state) iconName: [\(mnProgress.state.imageSystemSymbolName)]")
                self.progressCircle?.isHidden = true
            }
        }
        
        // Update label
        if texts.title == nil && texts.subtitle == nil, let lastRecv = self.lastRecievedProgressTexts {
            texts = lastRecv
        } else {
            self.lastRecievedProgressTexts = texts
        }
        
        // self.setTitles(texts: texts, mnProgress:mnProgress)
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
                                               changesCount: 50,
                                               finishWith: .failure(AppError(AppErrorCode.misc_unknown, detail: "Final call of test")),
                                               observerToAdd: self)
    }
}
