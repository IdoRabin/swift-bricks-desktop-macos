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
    private var _lastDocUID : BrickDocUID? = nil
    weak var centerProgressBoxView : MNProgressBoxView? = nil
    
    var isWindowCurrent : Bool {
        var isCurWindow = false
        if let window = self.window, window.isKeyWindow && window.isMainWindow {
            isCurWindow = true
        } else if BrickDocController.shared.curDocWC?.window == self.window {
            isCurWindow = true
        }
        return isCurWindow
    }
    
    // MARK: Lifecycle
    private func setupIfPossible() {
        DispatchQueue.main.performOncePerInstance(self) {
            dlog?.info("setup")
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
                newPBoXView.observers.add(observer: self)
                
                if let copyItem = newPBoXView.copyMenuItem {
                    copyItem.target = self
                    copyItem.action = #selector(mptbvCopyMenuItemAction(_:))
                }
                
                if let viewLogItem = newPBoXView.viewLogMenuItem {
                    viewLogItem.target = self
                    viewLogItem.action = #selector(mptbvViewLogMenuItemAction(_:))
                }
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
        centerProgressBoxView?.observers.remove(observer: self)
        dlog?.info("deinit")
    }
    
    // MARK: Public
    func updateWithDoc(_ doc:BrickDoc?) {
        if _lastDoc != doc {
            dlog?.info("updateWithDoc")
            _lastDoc?.observers.remove(observer: self)
            _lastDoc = doc
            _lastDocUID = doc?.id
            _lastDoc?.observers.add(observer: self)
            
            centerProgressBoxView?.updateWithDoc(doc)
        }
    }
    
    func basicUpdate(state newState:MNProgressState, title newTitle:String?, subtitle newSubtitle:String?, progress newProgress:CGFloat? = nil) {
        dlog?.info("basicUpdate \(newTitle.descOrNil) | \(newSubtitle.descOrNil) progress:\(newProgress.descOrNil)")
        centerProgressBoxView?.basicUpdate(state:newState, title: newTitle, subtitle: newSubtitle, progress: newProgress)
    }
    
    
    func updateWindowState() {
        dlog?.info("updateWindowState isWindowCurrent: \(self.isWindowCurrent)")
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
    
    func brickDocumentDidClose(_ brickUID: BrickDocUID) {
        guard self._lastDocUID == brickUID else {
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

extension MainPanelToolbarView : MNProgressBoxViewObserver {
    func mnProgressBoxView(_ view: MNProgressBoxView, didLeftMouseDown event: NSEvent) {
        //dlog?.info("mnProgressBoxView:didLeftMouseDown:")
        if view.isAllTextSeleted == false && view.isPopupMenuPresented == false {
            view.selectsAllText = true
            view.presentPopUpContextMenu(event: event)
        }
    }
    
    func mnProgressBoxView(_ view: MNProgressBoxView, didRightMouseDown event: NSEvent) {
        // dlog?.info("mnProgressBoxView:didRightMouseDown:")
        if view.isAllTextSeleted == false && view.isPopupMenuPresented == false {
            view.selectsAllText = true
            view.presentPopUpContextMenu(event: event)
        }
    }
    
}

@objc extension MainPanelToolbarView /* MNProgressBoxView menu events */ {
    
    @objc fileprivate func mptbvCopyMenuItemAction(_ sender:Any) {
        guard let boxView = centerProgressBoxView else {
            return
        }
        
        // Copy last log entitiy to pasteboard:
        let log = boxView.lastLogEntry
        dlog?.info("popup menu action: Copy... [\(log)]")
        
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(log, forType: .string)
    }
    
    @objc fileprivate func mptbvViewLogMenuItemAction(_ sender:Any) {
        dlog?.info("popup menu action: View Log...")
        // Enqueue command:
        if let docWC = self.window?.windowController as? DocWC, docWC.isCurentDocWC, let doc = docWC.brickDoc {
            doc.createCommand(CmdUITogglePopupForToolbarLogFileView.self, context: "toolbar.toggleLogViewPopup", isEnqueue: true)
        }
    }
}
