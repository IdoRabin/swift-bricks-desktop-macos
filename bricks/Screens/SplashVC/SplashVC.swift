//
//  SplashVC.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("SplashVC")

class HistoryTableviewContainer : NSScrollView {
    override var isHidden: Bool {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var fittingSize: NSSize {
        if self.isHidden {
            return super.fittingSize.changed(width: 1.0)
        } else {
            return super.fittingSize
        }
    }
    
    override var intrinsicContentSize: NSSize {
        if self.isHidden {
            return super.intrinsicContentSize.changed(width: 1.0)
        } else {
            return super.intrinsicContentSize
        }
    }
}

class SplashVC : NSViewController {
    let DEBUG_DRAWING = IS_DEBUG && false
    
    var windowController : NSWindowController? = nil
    
    @IBOutlet weak var mainItemsConstainer: NSView!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var showWindowCheckBox: NSButton!
    @IBOutlet weak var historyTableviewContainer: HistoryTableviewContainer!
    @IBOutlet weak var historyTableview : NSTableView!
    @IBOutlet weak var closeButton: MNButton!
    
    // Vertical stack buttons
    @IBOutlet weak var startNewProjectButton: MNButton!
    @IBOutlet weak var openExistinProjectButton: MNButton!
    
    private var historyFiles : [BrickBasicInfo] = []
    
    fileprivate func setHistoryTableHidden(_ hidden:Bool) {
        if historyTableviewContainer.isHidden != hidden {
            historyTableviewContainer.isHidden = hidden
            waitFor("view load", interval: 0.1, timeout: 1.0, testOnMainThread: {
                self.isViewLoaded && self.view.window != nil
            }, completion: { [self] waitResult in
                DispatchQueue.mainIfNeeded {
                    if let window = self.view.window {
                        window.setFrame(window.frame.adding(widthAdd: (hidden ? -1 : 1) * historyTableviewContainer.frame.width), display: true, animate: false)
                    }
                }
            }, counter: 1)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog?.info("viewDidLoad")
        
        let yearStr = DateFormatter.localeYearFormatter.string(from: Date())
        titleLabel.stringValue = AppStr.BRICKS.localized()
        subtitleLabel.stringValue = AppStr.COPYRIGHT_COMPANY_W_YEAR_FORMAT.formatLocalized(yearStr) + "\n" + AppStr.VERSION.localized() + Bundle.main.fullVersionAsDisplayString
        showWindowCheckBox.state = AppSettings.shared.general.showsSplashScreenOnInit ? .on : .off
        
        closeButton.onMouseEnter = {btn in
            btn.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: AppStr.CLOSE.localized())
        }
        closeButton.onMouseExit = {btn in
            btn.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: AppStr.CLOSE.localized())
        }
        
        // Add NBSP prefix to titles:
        startNewProjectButton.title = AppStr.START_A_NEW_PROJECT_DOT_DOT.localized()
        openExistinProjectButton.title = AppStr.OPEN_AN_EXISTING_PROJECT_DOT_DOT.localized()
        [startNewProjectButton, openExistinProjectButton].forEach { button in
            if let button = button {
                button.titleNBSPPrefixIfNeeded(count: 2)
                button.needsLayout = true
                button.needsUpdateConstraints = true
                button.sizeToFit()
                button.wantsLayer = true
                button.layer?.border(color: .red, width: 1)
            }
        }
        
        AppDocumentHistory.shared.whenLoaded { updated in
            switch updated {
            case .success:
                self.setHistoryTableHidden(AppDocumentHistory.shared.history.count == 0)
            case .failure:
                self.setHistoryTableHidden(true)
            }
        }
        
        if DEBUG_DRAWING {
            self.historyTableviewContainer.layer?.border(color: .red, width: 1)
            self.mainItemsConstainer.layer?.border(color: .green, width: 1)
        }
    }
}

extension SplashVC /* Actions */ {
    
    @IBAction func closeButtonAction(_ sender:Any) {
        dlog?.info("closeButtonAction")
        
        if let window = self.view.window {
            if window.delegate?.windowShouldClose?(window) ?? true {
                self.windowController = nil
                window.close()
            }
        }
        
        if AppSettings.shared.general.splashScreenCloseBtnWillCloseApp {
            if NSDocumentController.shared.hasEditedDocuments {
                DLog.splash.raisePreconditionFailure("TODO: Handle unsaved documents")
            } else {
                DispatchQueue.main.async {
                    AppDelegate.shared.documentController?.invalidateMenu()
                    NSApplication.shared.terminate(self)
                }
            }
        }
    }
    
    @IBAction func showWindowCheckboxAction(_ sender:Any) {
        guard let checkbox = sender as? NSButton else {
            dlog?.note("showWindowCheckboxAction sender unknwon \(sender)")
            return
        }
        AppSettings.shared.general.showsSplashScreenOnInit = (checkbox.state == .on)
    }
    
    @IBAction func startNewProjectButtonAction(_ sender:Any) {
        dlog?.info("startNewProjectButtonAction")
    }
    
    @IBAction func openExistingProjectButton(_ sender: Any) {
        
        NSDocumentController.shared.beginOpenPanel { (urls) in
            dlog?.info("open panel closed with \(urls?.description ?? "< no urls>" )")
        }
    }

    @IBAction func historyTableViewDidSelectRow(_ sender:Any) {
        dlog?.info("historyTableViewDidSelectRow")
    }
}

extension SplashVC : NSTableViewDelegate, NSTableViewDataSource {
    
}
