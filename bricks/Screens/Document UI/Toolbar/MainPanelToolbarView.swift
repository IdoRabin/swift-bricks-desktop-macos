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
    
    // MARK: Properties
    
    // External stack view -
    @IBOutlet weak var extStackView: NSStackView!
    @IBOutlet weak var leadingExtButton: NSButton!
    
    // Center
    @IBOutlet weak var centerBoxContainer: NSBox!
        @IBOutlet weak var centerStackView: NSStackView!
        @IBOutlet weak var pathControl: NSPathControl!
    
        @IBOutlet weak var activiyLabelLeadingConstraint: NSLayoutConstraint!
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
        
        updateWithDoc(nil)
        setupProgressIndicator()
        centerBoxContainer.fillColor = .quaternaryLabelColor.withAlphaComponent(0.05)
        centerBoxContainer.borderColor = .quaternaryLabelColor.withAlphaComponent(0.1)
        centerBoxContainer.borderWidth = 0.5
        progress?.widthConstraint = self.progressWidthConstraint
        let targetW : CGFloat = 2
        progress?.onHideAnimating = {(context) in
             let existingW = self.progress?.bounds.width ?? 28
             self.progressWidthConstraint.constant = targetW
             self.activiyLabelLeadingConstraint.constant = 18 + existingW - targetW
        }
        progress?.onUnhideAnimating = {(context) in
             self.progressWidthConstraint.constant = 28
             self.activiyLabelLeadingConstraint.constant = 18
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
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.progress?.needsLayout = true
        self.needsLayout = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
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
