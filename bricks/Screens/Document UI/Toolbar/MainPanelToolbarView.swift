//
//  MainPanelToolbarItem.swift
//  Bricks
//
//  Created by Ido on 15/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("MainPanelToolbarItem")

class MainPanelToolbarView : NSView {
    let DEBUG_DRAWING = IS_DEBUG && false
    let DEBUG_TEST_PROGRESS_OBSERVATION = IS_DEBUG && true
    var lastRecievedProgressAction : MNProgressAction? = nil
    
    // MARK: Properties
    
    // External stack view -
    @IBOutlet weak var extStackView: NSStackView!
    @IBOutlet weak var leadingExtButton: NSButton!
    
    // Center
    @IBOutlet weak var centerBoxContainer: NSBox!
        @IBOutlet weak var centerStackView: NSStackView!
        @IBOutlet weak var pathControl: NSPathControl!
    
    
        @IBOutlet weak var progressActivityContainer: NSView!
            @IBOutlet weak var activityLabelCenterYConstraint: NSLayoutConstraint!
            @IBOutlet weak var activityLabelLeadingConstraint: NSLayoutConstraint!
            @IBOutlet weak var activityLabel: NSTextField!
    
            @IBOutlet weak var progressWidthConstraint: NSLayoutConstraint!
            @IBOutlet weak var progress: CircleProgressView? = nil
    
    @IBOutlet weak var trailingExtButton1: NSButton!
    @IBOutlet weak var trailingextButton2: NSButton!
    
    
    private weak var _lastDoc : BrickDoc? = nil
    
    var isWindowCurrent : Bool {
        var isCurWindow = false
        if let window = self.window, window.isKeyWindow && window.isMainWindow {
            isCurWindow = true
        }
        return isCurWindow
    }
    
    // MARK: Lifecycle
    private func setupProgressIndicator() {
        guard let progress = progress else {
            return
        }
        
        if DEBUG_DRAWING {
            progress.layer?.border(color: .magenta, width: 1)
        }
    }
    
    private func setup() {
        guard self.superview != nil else {
            return
        }
        
        DispatchQueue.main.performOncePerInstance(self) {
            updateWithDoc(nil)
            setupProgressIndicator()
            centerBoxContainer.fillColor = .quaternaryLabelColor.withAlphaComponent(0.05)
            centerBoxContainer.borderColor = .quaternaryLabelColor.withAlphaComponent(0.1)
            centerBoxContainer.borderWidth = 0.5
            
            // Setup progress:
            if let progress = progress {
                progress.widthConstraint = self.progressWidthConstraint
                let targetW : CGFloat = 2
                progress.onHideAnimating = {[weak self] (context) in
                     let existingW = self?.progress?.bounds.width ?? 28
                     self?.progressWidthConstraint.constant = targetW
                     self?.activityLabelLeadingConstraint.constant = 18 + existingW - targetW
                }
                progress.onUnhideAnimating = {[weak self] (context) in
                     self?.progressWidthConstraint.constant = 28
                     self?.activityLabelLeadingConstraint.constant = 18
                }
                if progress.progress == 0.0 {
                    progress.resetToZero(animated: false, hides: true) {
                        dlog?.info("reset")
                    }
                }
            }
            
            if DEBUG_DRAWING {
                for item in self.subviews {
                    item.wantsLayer = true
                    item.layer?.border(color: .orange.withAlphaComponent(0.7), width: 1)
                }
                for item in centerStackView.subviews {
                    item.wantsLayer = true
                    item.layer?.border(color: .yellow.withAlphaComponent(0.7), width: 1)
                }
            }
        }
        
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.progress?.needsLayout = true
        self.needsLayout = true
        DispatchQueue.main.async {
            self.showItemsIfPossible()
        }
        
        if DEBUG_TEST_PROGRESS_OBSERVATION {
            self.debugTestProgressObservations()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async {
            self.showItemsIfPossible()
        }
    }
    
    func showItemsIfPossible() {
        guard self.window != nil && self.superview != nil else {
            return
        }
        
        DispatchQueue.main.performOncePerInstance(self) {
            NSView.animate(duration: 0.5, delay: 0.1) { context in
                self.progressActivityContainer.animator().alphaValue = 1.0
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        progressActivityContainer.alphaValue = 0.01
        
        //dlog?.info("awakeFromNib \(self.basicDesc) window: \(self.window?.basicDesc ?? "<nil>" )")
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    deinit {
        //dlog?.info("deinit")
    }
    
    // MARK: Public
    func updateWithDoc(_ doc:BrickDoc?) {
        if _lastDoc != doc {
            _lastDoc?.observers.remove(observer: self)
            _lastDoc = doc
            _lastDoc?.observers.add(observer: self)
            
            if let _ = doc {
                // TODO: Update progress
                progress?.isHidden = false
                
            } else {
                progress?.isHidden = true
            }
        }
    }
    
    func updateWindowState() {
        self.alphaValue = self.isWindowCurrent ? 1.0 : 0.6
    }
    
}

extension MainPanelToolbarView : BrickDocObserver {
    
    func brickDocumentError(_ brick: BrickDoc, error: AppError?) {
        guard self._lastDoc == brick else {
            return
        }
    }
    
    func brickDocumentWillClose(_ brick: BrickDoc) {
        guard self._lastDoc == brick else {
            return
        }
    }
    
    func brickDocumentDidClose(_ brick: BrickDoc) {
        guard self._lastDoc == brick else {
            return
        }
    }
    
    func brickDocumentWillOpen(_ brick: BrickDoc) {
        guard self._lastDoc == brick else {
            return
        }
    }
    
    func brickDocumentDidOpen(_ brick: BrickDoc) {
        guard self._lastDoc == brick else {
            return
        }
    }
    
    func brickDocumentDidChange(_ brick: BrickDoc, activityState: BrickDoc.DocActivityState) {
        guard self._lastDoc == brick else {
            return
        }
    }
    
    func brickDocumentDidChange(_ brick: BrickDoc, saveState: BrickDoc.DocSaveState) {
        guard self._lastDoc == brick else {
            return
        }
    }
}

extension MainPanelToolbarView : MNProgressObserver {

    private func setTitles(for action: MNProgressAction? = nil, discretes: DiscreteMNProgStruct?, error: AppError?) {
        var title = ""
        var subtitle : String? = nil
        if let action = action ?? lastRecievedProgressAction {
            lastRecievedProgressAction = action
            title = action.title
            subtitle = action.subtitle
            self.progress?.progressType = action.isLongTimeAction ? .determinateSpin : .determinate
        } else {
            self.progress?.progressType = .determinate
            if let error = error {
                title = AppStr.ERROR_FORMAT.formatLocalized(error.localizedDescription)
            }
        }
        
        if let units = discretes {
            title += " | \(units.progressUnitsDisplayString)"
        }
        
        var totalStr = title
        if let subtitle = subtitle, subtitle.count > 0 {
            totalStr += "\n\(subtitle.prefix(40))"
        }
        let font = activityLabel.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attr = NSMutableAttributedString(string: totalStr, attributes: [.font:font])
        attr.setAtttibutesForStrings(matching: subtitle ?? "", attributes: [.font:font.withSize(NSFont.systemFontSize(for: .mini))])
        activityLabel.stringValue = title
    }
    
    func mnProgress(emitter: MNProgressEmitter, action: MNProgressAction?, hadError error: AppError, didStopAllProgress: Bool) {
        dlog?.todo("Handle reported errors! \(error) didStopAllProgress:\(didStopAllProgress)")
        if didStopAllProgress {
            self.progress?.resetToZero(animated: true, hides: true, completion: nil)
        }
    }
    
    func mnProgress(emitter: MNProgressEmitter, didChangeLastAction lastAction: MNProgressAction?, fraction: Double, discretes: DiscreteMNProgStruct?) {
        dlog?.info("mnProgress: \(type(of: emitter)) fraction: \(round(fraction * 100))%")
        
        // Progress view:
        let fract = clamp(value: fraction, lowerlimit: 0.0, upperlimit: 1.0) { frac in
            dlog?.note("mnProgress(emitter \(emitter) emitted a fraction that is out-of bounds: \(fraction) should be in the range [0.0...1.0]")
        }
        
        // Set progress fraction
        self.progress?.progress = fract
        
        // Action title:
        self.setTitles(for: lastAction, discretes: discretes, error: nil)
    }
    
    func debugTestProgressObservations() {
        guard DEBUG_TEST_PROGRESS_OBSERVATION else {
            return
        }
        dlog?.info("debugTestProgressObservations")
        
        TestMNProgressEmitter.shared.timedTest(delay: 0.3,
                                               interval: 3,
                                               changesCount: 10,
                                               finishWith: .failure(AppError(AppErrorCode.misc_unknown, detail: "Final call of test")),
                                               observerToAdd: self)
    }
}
