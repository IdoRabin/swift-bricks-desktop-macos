//
//  PropertiesVC.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//

import AppKit

class PropertiesVC : NSSplitViewController, DocSubVC {
    // MARK: Constants
    // MARK: Enums
    // MARK: Properties
    // MARK: Computed vars
    
    // MARK: private Properties
    // MARK: Private funcs
    private func setup() {
        registerToDocWC()
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return BrickDocController.shared.validateUserInterfaceItem(doc: self.doc, item: item)
    }
    
    // MARK: Public funcs
}


