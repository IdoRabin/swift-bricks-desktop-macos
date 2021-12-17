//
//  AboutVC.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("AboutVC")

class AboutVC: NSViewController {

    // TODO: Make AboutVC behave like an NSPanel, closing automaticamainlly when the user clicks on another window or another app or the desktop
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var copyrightLabel: NSTextField!
    @IBOutlet weak var ackButton: MNButton!
    @IBOutlet weak var licenseButton: MNButton!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.delegate = AppDelegate.shared.documentController
    }
    
    override func viewDidLoad() {
        dlog?.info("viewDidLoad")
        super.viewDidLoad()

        self.titleLabel.stringValue = AppStr.PRODUCT_NAME.localized()
        self.versionLabel.stringValue = AppStr.VERSION.localized() + " " + Bundle.main.fullVersionAsDisplayString

        let yearStr = DateFormatter.localeYearFormatter.string(from: Date())
        self.copyrightLabel.stringValue = AppStr.COPYRIGHT_COMPANY_W_YEAR_FORMAT_LONG.formatLocalized(yearStr)
    }
    
    deinit {
        dlog?.info("deinit \(self.basicDesc)")
    }
    
}
