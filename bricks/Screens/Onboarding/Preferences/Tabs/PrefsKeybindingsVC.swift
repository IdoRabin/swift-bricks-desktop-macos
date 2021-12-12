//
//  PrefsKeybindingsVC.swift
//  Bricks
//
//  Created by Ido on 12/12/2021.
//

import Foundation
import AppKit

class PrefsKeybindingsVC : NSViewController {
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = AppStr.KEY_BINDINGS.localized()
    }
}
