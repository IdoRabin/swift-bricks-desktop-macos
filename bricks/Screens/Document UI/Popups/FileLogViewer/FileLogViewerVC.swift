//
//  FileLogViewerVC.swift
//  Bricks
//
//  Created by Ido on 29/01/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("FileLogViewerVC")

class FileLogViewerVC: NSViewController {
    // MARK: Static
    
    // MARK: Const
    var preferredLoadSize: CGSize? = nil
    
    // MARK: UI outlets
    @IBOutlet weak var buttonsWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var fileLogView: FileLogView!
    @IBOutlet weak var saveButton: MNButton!
    @IBOutlet weak var shareButton: MNButton!
    @IBOutlet weak var copyButton: MNButton!
    
    // MARK: Properties / members
    weak var fileLog : FileLog? = nil {
        didSet {
            waitFor("FileLogViewerVC", testOnMainThread: {
                self.isViewLoaded
            }, completion:{ waitResult in
                self.fileLogView.observers.add(observer: self)
                DispatchQueue.mainIfNeeded {
                    self.fileLogView.fileLog = self.fileLog
                }
            })
        }
    }
    
    // MARK: Private
    private func setupSize() {
        DispatchQueue.main.performOncePerInstance(self) {
            self.findPreferredLoadWidthIfNeeded()
            if let loadSze = self.preferredLoadSize {
                self.view.frame = self.view.frame.changed(width: loadSze.width, height: loadSze.height)
            }
        }
    }
    
    private func setupButtons() {
        guard self.isViewLoaded else {
            return
        }
        
        DispatchQueue.main.performOncePerInstance(self) {
            let buttons : [MNButton]? = self.view.subviews(which: { view in
                view is MNButton
            }, downtree: true) as? [MNButton]
            
            guard let buttons = buttons, buttons.count > 0 else {
                return
            }
            
            // Set localized titles
            var maxTextW : CGFloat = 42.0
            saveButton.title = AppStr.SAVE.localized()
            shareButton.title = AppStr.SHARE_DOT_DOT.localized()
            copyButton.title = AppStr.COPY.localized()
            
            for button in buttons  {
                button.instrinsicContentSizePadding = NSEdgeInsets()
                if button.title.count > 0 {
                    dlog?.info("setting up btn: [\(button.title)]")
                    maxTextW = max(maxTextW, button.attributedTitle.size().width + 6.0)
                }
            }
            
            buttonsWidthConstraint.constant = maxTextW
            
            // TODO: Tooltops for FileLogViewerVC buttons
            // saveButton.toolTip = AppStr.SAVE.localized()
            // shareButton.toolTip = AppStr.SHARE_DOT_DOT.localized()
            // copyButton.toolTip = AppStr.COPY_.localized()
        }
    }
    
    // MARK: Public
    func findPreferredLoadWidthIfNeeded(window:NSWindow? = nil) {
        guard preferredLoadSize == nil, let docWC = (window?.windowController ?? self.view.window?.windowController) as? DocWC else {
            return
        }
        
        if let view = docWC.docVC?.splitView.arrangedSubviews[1] ?? docWC.contentViewController?.view {
            var sze = view.bounds.size.adding(widthAdd: -100, heightAdd: -100)
            sze.width = max(sze.width, 200)
            sze.height = max(sze.height, 160)
            self.preferredLoadSize = sze
        }
    }
    
    func invalidateButtons() {
        let isVis = self.isViewLoaded && self.view.superview != nil && self.presentingViewController != nil
        saveButton.isEnabled = isVis && (fileLog?.count ?? 0 > 0)
        shareButton.isEnabled = isVis && (fileLog?.count ?? 0 > 0) && (fileLog?.isNeedsSave ?? true == false)
        copyButton.isEnabled = isVis && (fileLog != nil) && (fileLogView.selectedRowIndexes.count > 0)
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog?.info("viewDidLoad \(self.basicDesc)")
        self.setupSize()
        self.setupButtons()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.setupSize()
        saveButton.isEnabled =  false
        shareButton.isEnabled = false
        copyButton.isEnabled =  false
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.invalidateButtons()
        DispatchQueue.main.asyncAfter(delayFromNow: 0.1) {
            self.invalidateButtons()
        }
    }
 
    deinit {
        dlog?.info("deinit \(self.basicDesc)")
    }
    
    // MARK: Actions
    @IBAction func saveButtonAction(_ sender: Any) {
        dlog?.info("saveButtonAction")
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {
        dlog?.info("shareButtonAction")
    }
    
    @IBAction func copyButtonAction(_ sender: Any) {
        dlog?.info("copyButtonAction")
        if let string = self.fileLogView.selectedLines()?.asString, string.count > 0 {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(string, forType: .string)
        }
    }
}

extension  FileLogViewerVC : FileLogViewObserver {
    func fileLogView(_ fileLogView: FileLogView, didSelectRows rows: IndexSet) {
        dlog?.info("fileLogView : didSelectRows : \(rows)")
        self.invalidateButtons()
    }
}
