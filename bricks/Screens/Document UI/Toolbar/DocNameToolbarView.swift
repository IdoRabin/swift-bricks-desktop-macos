//
//  DocNameToolbarView.swift
//  Bricks
//
//  Created by Ido on 15/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocNameToolbarView")

class DocNameToolbarView : MNBaseView {

    // MARK: Properties
    @IBOutlet weak var mainImageView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var titleImageView: NSImageView!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var subtitleProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var subtitleChevronImageView: NSImageView!
    private weak var _lastDoc : BrickDoc? = nil
    private var _lastDocUID : BrickDocUID? = nil
    
    public var isChevronPointsDown : Bool = true {
        didSet {
            updateChevronImage(isPointsDown: isChevronPointsDown)
        }
    }

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
    private func setup() {
        updateWithDoc(nil)
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        //dlog?.info("awakeFromNib \(self.basicDesc) window: \(self.window?.basicDesc ?? "<nil>" )")
        setup()
    }
    
    deinit {
        //dlog?.info("deinit")
    }
    
    // MARK: Private
    private func updateChevronImage(isPointsDown isDown:Bool = false) {
        var valIsDn = isDown
        if !valIsDn && !self.isWindowCurrent {
            valIsDn = true
        }
        let symbolName = "chevron.\(valIsDn ? "down" : "up")"
        let img = NSImage.systemSymbol(named: symbolName,
                                       pointSize: 14, weight: .medium,
                                       accessibilityDescription: nil)
        subtitleChevronImageView.image = img
    }
    
    // MARK: Public
    func updateWindowState() {
        self.alphaValue = self.isWindowCurrent ? 1.0 : 0.6
        isChevronPointsDown = true
    }
    
    func updateWithDoc(_ doc:BrickDoc?) {
        if _lastDoc != doc {
            _lastDoc?.observers.remove(observer: self)
            _lastDoc = doc
            _lastDocUID = doc?.id
            _lastDoc?.observers.add(observer: self)
        }
        
        updateChevronImage(isPointsDown: isChevronPointsDown)
        subtitleChevronImageView.alphaValue = 0.01
        subtitleLabel.alphaValue = 0.7
        
        if let doc = doc {
            titleLabel.stringValue = doc.displayName ?? doc.fileURL?.lastPathComponents(count: 2) ?? AppStr.UNTITLED.localized()
            titleImageView.image = nil
            var subtitle = doc.fileURL?.lastPathComponents(count: 2) ?? AppStr.UNSAVED.localized()
            if !doc.isDraft && (doc.hasUnautosavedChanges || doc.isDocumentEdited || doc.brick.isNeedsSaving) {
                subtitle += "*"
            }
            subtitleLabel.stringValue = subtitle
            mainImageView.image = doc.docSaveState.iconImage
            mainImageView.alphaValue = isWindowCurrent ? (isMouseOver ? 1.0 : 0.8 ) : 0.5
            subtitleProgressIndicator.stopAnimation(self)
            subtitleProgressIndicator.isHidden = true
        } else {
            // No document
            titleLabel.stringValue = AppStr.LOADING.localized()
            titleImageView.image = nil
            subtitleLabel.stringValue = AppStr.PLEASE_WAIT_A_MOMENT_DOT_DOT.localized()
            mainImageView.alphaValue = (isMouseOver ? 0.6 : 0.4)
            mainImageView.image = AppImages.docNewEmptyDocumentIcon.image
            subtitleProgressIndicator.startAnimation(self)
        }
        
    }
    
    func setHighlighted(_ isOn:Bool) {
        NSView.animate(duration: 0.17) {[self] context in
            subtitleChevronImageView.animator().alphaValue = isOn ? (self.isWindowCurrent ? 1.0 : 0.5) : 0.01
            let labelsColor : NSColor = isOn ? .labelColor : .secondaryLabelColor
            titleLabel.animator().textColor = labelsColor
            subtitleLabel.animator().textColor = labelsColor
        }
    }
    
    // MARK: Mouse events
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        updateWithDoc(_lastDoc)
        setHighlighted(false)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        updateWithDoc(_lastDoc)
        setHighlighted(true)
    }
    
    override func mouseClick(with event: NSEvent) {
        super.mouseClick(with: event)
        DispatchQueue.main.async {
            self.setHighlighted(true)
        }
        
        // Enqueue command:
        if let docWC = self.window?.windowController as? DocWC, docWC.isCurentDocWC, let doc = docWC.brickDoc {
            doc.createCommand(CmdUITogglePopupForToolbarNameView.self, context: "toolbar.toggleNamwPopup", isEnqueue: true)
        }
    }

}

extension DocNameToolbarView : BrickDocObserver {
    
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
        // brickDocumentWillLoad
        guard self._lastDoc == brick else {
            return
        }
    }
    
    func brickDocumentDidOpen(_ brick: BrickDoc) {
        // brickDocumentDidLoad
        guard self._lastDoc == brick else {
            return
        }
        
        DispatchQueue.main.async {
            self.updateWithDoc(brick)
        }
    }
    
    func brickDocumentWillSave(_ brick: BrickDoc) {
        guard self._lastDoc == brick else {
            return
        }
        self.subtitleLabel.stringValue = AppStr.SAVING.localized()
    }
    
    func brickDocumentDidSave(_ brick: BrickDoc, result: AppResult) {
        guard self._lastDoc == brick else {
            return
        }
        self.updateWithDoc(brick)
        
        switch result {
        case .success:
            self.subtitleLabel.stringValue = AppStr.SAVED.localized()
        case .failure: // (let err):
            self.subtitleLabel.stringValue = AppStr.FAILED.localized()
        }
        
    }
    
    func brickDocumentDidChange(_ brick: BrickDoc, activityState: BrickDoc.DocActivityState) {
        guard self._lastDoc == brick else {
            return
        }
        
        switch activityState {
        case .saving(let progress):
            self.subtitleLabel.stringValue = "todo percent! \(progress)"
            // AppStr.SAVING_X_DOT_DOT_FORMAT.localized()
        case .loading(let progress):
            self.subtitleLabel.stringValue = "todo percent! \(progress)"
            // AppStr.SAVING_X_DOT_DOT_FORMAT.localized()
        default:
            break
        }
    }
    
    func brickDocumentDidChange(_ brick: BrickDoc, saveState: BrickDoc.DocSaveState) {
        guard self._lastDoc == brick else {
            return
        }
        
        mainImageView.image = brick.docSaveState.iconImage
        BrickDocController.shared.curDocWC?.mainMenu?.updateWindowsDynamicMenuItems()
        // (brick.windowControllers.first as? DocWC)?.mainMenu?.updateWindowsDynamicMenuItems()
    }
}
