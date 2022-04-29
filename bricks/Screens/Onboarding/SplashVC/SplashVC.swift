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
    let TABLEVIEW_WIDTH : CGFloat = 220 // hhh
    static var sharedWindowController : NSWindowController? = nil
    
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
    @IBOutlet weak var mainButtonsStackViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainButtonsStackView: NSStackView!
    @IBOutlet weak var startNewProjectButton: MNButton!
    @IBOutlet weak var openExistinProjectButton: MNButton!
    
    private var historyFiles : [BrickBasicInfo] = []
    
    func setHistoryTableHidden(_ hidden:Bool) {
        dlog?.info("setHistoryTableHidden: \(hidden)")
        if historyTableviewContainer.isHidden != hidden {
            historyTableviewContainer.isHidden = hidden
            waitFor("view load", interval: 0.1, timeout: 1.0, testOnMainThread: {
                self.isViewLoaded && self.view.window != nil
            }, completion: { [self] waitResult in
                DispatchQueue.mainIfNeeded {
                    if let window = self.view.window {

                        var rect = window.frame
                        if hidden {
                            rect = rect.changed(width: MIN_WIDTH)
                        } else {
                            rect = rect.changed(width: MIN_WIDTH + TABLEVIEW_WIDTH)
                        }

                        window.setFrame(rect, display: true, animate: false)
                    }
                }
            }, logType: .allAfterFirstTest)
        }
    }
    
    private func layoutMainActionButtons() {
        var maxW : CGFloat = 0
        [startNewProjectButton, openExistinProjectButton].forEach { button in
            if let button = button {
                button.titleNBSPPrefixIfNeeded(count: 2)
                button.needsLayout = true
                button.needsUpdateConstraints = true
                maxW = max(maxW, button.intrinsicContentSize.width)
            }
        }
        if maxW > 0 {
            maxW = maxW + 1 + mainButtonsStackView.edgeInsets.left + mainButtonsStackView.edgeInsets.right // + mainButtonsStackView.spacing
            maxW = min(maxW, self.view.bounds.width - 24)
            //dlog?.info("layout maxW:\(maxW)")
            mainButtonsStackViewWidthConstraint.constant = maxW
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog?.info("viewDidLoad")
        
        let yearStr = DateFormatter.localeYearFormatter.string(from: Date())
        titleLabel.stringValue = AppStr.PRODUCT_NAME.localized()
        subtitleLabel.stringValue = AppStr.COPYRIGHT_COMPANY_W_YEAR_FORMAT.formatLocalized(yearStr) + "\n" + AppStr.VERSION.localized() + Bundle.main.fullVersionAsDisplayString
        
        showWindowCheckBox.title = AppStr.SHOW_THIS_WINDOW_ON_STARTUP.localized()
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
        
        if DEBUG_DRAWING {
            // self.historyTableviewContainer.debugBorder(color: .red, width: 1)
            // self.mainItemsConstainer.debugBorder(color: .green, width: 1)
            self.startNewProjectButton.debugBorder(color: .cyan, width: 1)
            self.openExistinProjectButton.debugBorder(color: .cyan, width: 1)
            self.startNewProjectButton.superview?.debugBorder(color: .magenta, width: 1)
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        let box : MNColoredView? = self.view.subviews.first { view in
            view is MNColoredView
        } as? MNColoredView
        if DEBUG_DRAWING {
            box?.debugBorder(color: .blue, width: 1)
        }
        box?.frame = self.view.frame
        dlog?.info("viewDidLayout")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if Self.sharedWindowController != nil {
            dlog?.warning("Two splash screens opened at once!")
        }
        Self.sharedWindowController = self.view.window?.windowController
        self.view.window?.isMovableByWindowBackground = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        dlog?.info("viewDidAppear")
    }
    
    // TODO: NSWindow with no title bar cannot become keyWindow -> and cannot recieve keyboard events except cmd+w and a few other winow mgmgt keys
    override func cancelOperation(_ sender: Any?) {
        self.closeButtonAction(sender ?? self)
    }
    
    deinit {
        Self.sharedWindowController = nil
        dlog?.info("deinit \(self.basicDesc)")
    }
}

extension SplashVC /* Actions */ {
    
    func hideAndCloseSelf(animated:Bool = true, completion:@escaping (_ wasClosed:Bool)->Void) {
        guard let window = self.view.window,self.isViewLoaded && window.isVisible else {
            completion(false)
            return
        }
        
        window.fadeHide {
            window.close()
            completion(true)
        }
    }
    
    private func terminateAppIfNeeded() {
        if AppSettings.shared.general.splashScreenCloseBtnWillCloseApp {
            BrickDocController.shared.lastClosedWasOnSplashScreen = (BrickDocController.shared.brickDocWindows.count == 0)
            
            if BrickDocController.shared.hasEditedDocuments {
                DLog.splash.raisePreconditionFailure("TODO: Handle unsaved documents")
            } else {
                DispatchQueue.main.async {
                    AppDelegate.shared.documentController?.invalidateMenu(context: "terminateAppIfNeeded")
                    
                    // Terminate the app:
                    BricksApplication.shared.terminate("SplashVC")
                }
            }
        }
    }
    
    @IBAction func closeButtonAction(_ sender:Any) {
        dlog?.info("closeButtonAction")
        
        if let window = self.view.window {
            if window.delegate?.windowShouldClose?(window) ?? true {
                self.hideAndCloseSelf(animated: self.isViewLoaded) { wasClosed in
                    self.terminateAppIfNeeded()
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
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return nil
    }
    
}

extension SplashVC : SinglyInstanced {
    static var isRequiresSingeInstance: Bool { return true }
}
