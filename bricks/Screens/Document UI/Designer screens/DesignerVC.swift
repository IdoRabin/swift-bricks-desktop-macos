//
//  DesignerVC.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//

import AppKit

class DesignerVC : NSViewController, DocSubVC {
    // MARK: Constants
    // MARK: Enums
    // MARK: Properties
    // MARK: Computed vars
    
    // MARK: private Properties
    // MARK: Private funcs
    private func setup() {
        self.registerToDocWC()
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: Public funcs
}
