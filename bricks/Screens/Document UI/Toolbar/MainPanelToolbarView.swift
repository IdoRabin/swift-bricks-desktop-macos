//
//  MainPanelToolbarView.swift
//  Bricks
//
//  Created by Ido on 15/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("MainPanelToolbarView")



class MainPanelToolbarView : NSView {
    let DEBUG_DRAWING = IS_DEBUG && false
    

    // "\u{20D3}" = Short Vertical Line, less than a pipe |
    let TITLE_UNITS_SEPARATOR = String.THIN_SPACE + "|" + String.THIN_SPACE
    
    // MARK: Properties
    
    // External stack view -
    @IBOutlet weak var extStackViewMinWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var extStackViewMaxWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var extStackViewPreferredWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var extStackView: NSStackView!
    @IBOutlet weak var leadingExtButton: NSButton!
    
    // Center
    @IBOutlet weak var centerBoxContainer: NSBox!
        @IBOutlet weak var centerStackView: NSStackView!
        @IBOutlet weak var centerPathControlView: NSPathControl!
        @IBOutlet weak var centerProgressBoxViewContainer: NSView!

    @IBOutlet weak var trailingExtButton1: NSButton!
    @IBOutlet weak var trailingextButton2: NSButton!
    
    private weak var _lastDoc : BrickDoc? = nil
    weak var centerProgressBoxView : MNProgressBoxView? = nil
    
    var isWindowCurrent : Bool {
        var isCurWindow = false
        if let window = self.window, window.isKeyWindow && window.isMainWindow {
            isCurWindow = true
        }
        return isCurWindow
    }
    
    // MARK: Lifecycle
//    private func setupProgressIndicator() {
//        guard let progress = progress else {
//            return
//        }
//
//        if DEBUG_DRAWING {
//            progress.layer?.border(color: .magenta, width: 1)
//        }
//    }
    
    private func setupIfPossible() {
        dlog?.info("setup")
        DispatchQueue.main.performOncePerInstance(self) {
            updateWithDoc(self.window?.windowController?.document as? BrickDoc)
            // setupProgressIndicator()
            centerBoxContainer.fillColor = .quaternaryLabelColor.withAlphaComponent(0.05)
            centerBoxContainer.borderColor = .quaternaryLabelColor.withAlphaComponent(0.1)
            centerBoxContainer.borderWidth = 0.5
            
            // Setup progress:
            
            // Replace
            if let newPBoXView = MNProgressBoxView.fromNib() {
                newPBoXView.frame = centerProgressBoxViewContainer.frame.boundsRect()
                newPBoXView.autoresizingMask = [.width, .height]
                centerProgressBoxViewContainer.addSubview(newPBoXView)
                centerProgressBoxView = newPBoXView
            }
            
//            if let progress = progress {

//            }
            
            if DEBUG_DRAWING {
                self.debugBorders(downtree: true)
            }
        }
        
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.centerProgressBoxViewContainer?.needsLayout = true
        self.needsLayout = true
        setupIfPossible()
        DispatchQueue.main.async {
            self.showItemsIfPossible()
        }
        
//        if DEBUG_TEST_PROGRESS_OBSERVATION {
//            self.debugTestProgressObservations()
//        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupIfPossible()
    }
    
    func showItemsIfPossible() {
        guard self.window != nil && self.superview != nil else {
            return
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupIfPossible()
    }
    
    deinit {
//
        
    }
    
    // MARK: Public
    func updateWithDoc(_ doc:BrickDoc?) {
        if _lastDoc != doc {
            _lastDoc?.observers.remove(observer: self)
            _lastDoc = doc
            _lastDoc?.observers.add(observer: self)
            
            centerProgressBoxView?.updateWithDoc(doc)
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

extension MainPanelToolbarView {
    
    

    


//    private func setTitles(texts:ProgressTexts, mnProgress:MNProgress){
//        let isNeedsUpdate = (texts.title != nil || texts.subtitle != nil)
//        if isNeedsUpdate {
//            let progressState = mnProgress.state // prevents multiple calcs
//
//            // Title and subtitle
//            let titleStr : String? = texts.title
//            let subtitleStr : String? = texts.subtitle
//            var titleTotalStr = titleStr
//
//            // Append the units string at the end of the title string if possible
//            var unitsStr = ""
//            if let titleStr = titleStr, titleStr.count > 0, self.progress?.progressType.isDeterminate ?? true {
//                if let aunitsStr = mnProgress.discreteStructOrNil?.progressUnitsDisplayString {
//                    // title .. "My title is here | 23/100"
//                    unitsStr = aunitsStr
//                    titleTotalStr = "\(titleStr)\(TITLE_UNITS_SEPARATOR)\(unitsStr)"
//                } else if mnProgress.fractionCompleted > 0.0 {
//                    // title .. "My title is here | 23%"
//                    unitsStr = mnProgress.fractionCompletedDisplayString
//                    titleTotalStr = "\(titleStr)\(TITLE_UNITS_SEPARATOR)\(unitsStr)"
//                }
//            }
//
//            // Pad the title string with NBSP's to match the punctuation at the end of the subtitle
//            if let subtitleStr = subtitleStr, subtitleStr.count > 4 {
//                let suffxTrimmed = subtitleStr.trimmingSuffixCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters).union(CharacterSet(charactersIn: "-*")))
//                let delta = subtitleStr.count - suffxTrimmed.count
//                if delta > 0, let total = titleTotalStr {
//                    titleTotalStr = total.paddingRight(padCount: delta, withPad: String.NBSP[String.NBSP.startIndex])
//                    // padding(toLength: totalStr.count + delta, withPad: String.NBSP, startingAt: totalStr.count - 1)
//                    dlog?.info("padded : [\(titleTotalStr.descOrNil)]")
//                }
//            }
//
//            // Set title attributed string
//            // Prepare styles
//            let paragraph = NSMutableParagraphStyle()
//            paragraph.alignment = NSTextAlignment.inverseNatural
//            let font = activityTitleLabel.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
//            let unitsFont = titleStr?.count ?? 0 == 0 ? font : NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
//            let attr = NSMutableAttributedString(string: titleTotalStr ?? "", attributes: [.font:font, .paragraphStyle:paragraph])
//            attr.setAtttibutesForStrings(matching: TITLE_UNITS_SEPARATOR + unitsStr,
//                                         attributes: [
//                                            .font:unitsFont,
//                                            .kern : NSNumber(1), // bigger char spacing
//                                            .foregroundColor: NSColor.tertiaryLabelColor.blended(withFraction: 0.7, of: .secondaryLabelColor)!
//                                         ])
//
//            var unitsTxtColor =  NSColor.tertiaryLabelColor.blended(withFraction: 0.4, of: .secondaryLabelColor)!
//            switch progressState {
//            case .pending, .inProgress:
//                break
//            case .success, .failed, .userCanceled:
//                unitsTxtColor = unitsTxtColor.blended(withFraction: 0.6, of: progressState.iconBkgColor) ?? unitsTxtColor
//            }
//            attr.setAtttibutesForStrings(matching: unitsStr,
//                                         attributes: [
//                                            .foregroundColor: unitsTxtColor
//                                         ])
//            activityTitleLabel.attributedStringValue = attr
//
//            // Set subtitle string
//            let hidesSubtitle = (subtitleStr?.count ?? 0 == 0)
//            activitySubtitleLabel.stringValue = subtitleStr ?? ""
//            if false {
//                // Hide / detach
//                // self.activitySubtitleLabel.isHidden = true
//            } else {
//                let isHiddenSubtitle = self.activitySubtitleLabelHeightConstraint.constant < 1.0
//                if isHiddenSubtitle != hidesSubtitle || self.activityTitleLabel.tag == 0 {
//                    self.activityTitleLabel.tag = 1
//                    self.centerBoxContainer.layer?.removeAllAnimations()
//                    NSView.animate(duration: 0.2) { context in
//                        context.allowsImplicitAnimation = true
//                        let hiddenHeight : CGFloat = 4.0
//                        let titleH    = isHiddenSubtitle ? self.centerBoxContainer.frame.height - hiddenHeight : ceil(self.activityTitleLabel.font?.boundingRectForFont.height ?? 14.0) + 2.0
//                        let subtitleH = isHiddenSubtitle ? hiddenHeight : ceil(self.activitySubtitleLabel.font?.boundingRectForFont.height ?? 14.0) + 2.0
//                        self.activitySubtitleLabelHeightConstraint.animator().constant = hidesSubtitle ? hiddenHeight : subtitleH
//                        self.activityTitleLabelHeightConstraint.animator().constant = hidesSubtitle ? self.centerBoxContainer.bounds.height - hiddenHeight : titleH
//                        self.activitySubtitleLabel.animator().alphaValue = hidesSubtitle ? 0.01 : 1.0
//                        dlog?.info("constraints: title: \(self.activitySubtitleLabelHeightConstraint.constant) subtitle: \(self.activitySubtitleLabelHeightConstraint.constant)")
//                    }
//                }
//            }
//        }
//    }
}
