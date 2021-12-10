//
//  AboutVC.swift
//  Bricks
//
//  Created by Ido on 10/12/2021.
//

import Cocoa

class AboutVC: NSViewController {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var copyrightLabel: NSTextField!
    @IBOutlet weak var ackButton: MNButton!
    @IBOutlet weak var licenseButton: MNButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.stringValue = AppStr.PRODUCT_NAME.localized()
        self.versionLabel.stringValue = AppStr.VERSION.localized() + " " + Bundle.main.fullVersionAsDisplayString
        
        let yearStr = DateFormatter.localeYearFormatter.string(from: Date())
        self.copyrightLabel.stringValue = AppStr.COPYRIGHT_COMPANY_W_YEAR_FORMAT_LONG.formatLocalized(yearStr)
    }
}
