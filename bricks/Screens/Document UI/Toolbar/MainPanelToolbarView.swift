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
        dlog?.info("deinit")
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
