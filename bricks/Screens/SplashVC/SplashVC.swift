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
    let MIN_WIDTH : CGFloat = 420 // hhh
    var windowController : NSWindowController? = nil
    
    @IBOutlet weak var mainItemsconstainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainItemsconstainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainItemsConstainer: NSView!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var showWindowCheckBox: NSButton!
    @IBOutlet weak var historyTableviewContainer: HistoryTableviewContainer!
    @IBOutlet weak var historyTableview : NSTableView!
    @IBOutlet weak var closeButton: MNButton!
    
    // Vertical stack buttons
    @IBOutlet weak var mainButtonsStackView: NSStackView!
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

                        var rect = window.frame
                        if hidden {
                            rect = rect.growAroundCener(widthAdd: -historyTableviewContainer.frame.width, heightAdd: 0)
                            let delta = MIN_WIDTH - rect.width
                            if delta > 0 {
                                rect = rect.growAroundCener(widthAdd: delta, heightAdd: 0)
                            }
                        } else {
                            rect = rect.growAroundCener(widthAdd: historyTableviewContainer.frame.width, heightAdd: 0)
                        }
                        
                        window.setFrame(rect, display: true, animate: false)
                    }
                }
            }, counter: 1)
        }
    }
    
    private func layoutMainActionButtons() {
        [startNewProjectButton, openExistinProjectButton].forEach { button in
            if let button = button {
                button.needsLayout = true
                button.needsUpdateConstraints = true
                button.titleNBSPPrefixIfNeeded(count: 2)
                button.sizeToFit()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog?.info("viewDidLoad")
        
        let yearStr = DateFormatter.localeYearFormatter.string(from: Date())
        titleLabel.stringValue = AppStr.PRODUCT_NAME.localized()
        subtitleLabel.stringValue = AppStr.COPYRIGHT_COMPANY_W_YEAR_FORMAT.formatLocalized(yearStr) + "\n" + AppStr.VERSION.localized() + Bundle.main.fullVersionAsDisplayString
        showWindowCheckBox.state = AppSettings.shared.general.showsSplashScreenOnInit ? .on : .off
        
        closeButton.onMouseEnter = {btn in
            // btn.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: AppStr.CLOSE.localized())
            btn.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .black)
        }
        closeButton.onMouseExit = {btn in
            btn.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        }
        
        // Add NBSP prefix to titles:
        startNewProjectButton.associatedCommand = CmdNewProject.self
        openExistinProjectButton.associatedCommand = CmdOpenProject.self
        
        self.layoutMainActionButtons()
        
        AppDocumentHistory.shared.whenLoaded { updated in
            switch updated {
            case .success:
                self.setHistoryTableHidden(AppDocumentHistory.shared.history.count == 0)
            case .failure:
                self.setHistoryTableHidden(true)
            }
            DispatchQueue.main.async {
                self.layoutMainActionButtons()
            }
        }
        
        if DEBUG_DRAWING {
            // self.historyTableviewContainer.layer?.border(color: .red, width: 1)
            // self.mainItemsConstainer.layer?.border(color: .green, width: 1)
            self.startNewProjectButton.wantsLayer = true
            self.startNewProjectButton.layer?.border(color: .cyan, width: 1)
            
            self.openExistinProjectButton.wantsLayer = true
            self.openExistinProjectButton.layer?.border(color: .cyan, width: 1)
            
            self.startNewProjectButton.superview?.wantsLayer = true
            self.startNewProjectButton.superview?.layer?.border(color: .magenta, width: 1)
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        let box : MNColoredView? = self.view.subviews.first { view in
            view is MNColoredView
        } as? MNColoredView
        box?.layer?.border(color: .red, width: 1)
        box?.frame = self.view.frame
    }
}

extension SplashVC /* Actions */ {
    
    @IBAction func closeButtonAction(_ sender:Any) {
        dlog?.info("closeButtonAction")
        
        func finalKill() {
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
        
        if let window = self.view.window, let wc = (windowController as? SplashWC) {
            if window.delegate?.windowShouldClose?(window) ?? true {
                dlog?.info("Will fadeHide")
                wc.isClosing = true
                window.fadeHide {
                    wc.isClosing = false
                    window.close()
                    dlog?.info("fadeHide Done")
                    self.windowController = nil // dealloc windowController
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

    @IBAction func historyTableViewDidSelectRow(_ sender:Any) {
        dlog?.info("historyTableViewDidSelectRow")
        //let url =
        // BrickDocController.shared.openDocument(withContentsOf: url, display: true) { doc, Bool, Error? in
            
        //}
    }
    
    
}

extension SplashVC : NSTableViewDelegate, NSTableViewDataSource {
    
}

extension NSWindow {
    
    func fadeHide(completed:@escaping ()->Void) {
        guard let cv = self.contentView, let wc = self.windowController as? SplashWC else {
            return
        }
        
        let precloseFrame = self.frame
        
        func finalize() {
            cv.layer?.opacity = 0.0
            wc.contentViewController?.view.alphaValue = 0.0
            self.setFrame(precloseFrame, display: false, animate: false)
            dlog?.info("fadeHide finalized")
            completed()
        }
        let duration : TimeInterval = 0.2

        NSAnimationContext.runAnimationGroup(
            { (context) -> Void in
        context.duration = duration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().alphaValue = 0.0

            }, completionHandler: {
                finalize()
        })
    }
}
