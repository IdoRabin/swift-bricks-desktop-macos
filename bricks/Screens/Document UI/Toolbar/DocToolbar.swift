//
//  DocToolbar.swift
//  Bricks
//
//  Created by Ido on 19/12/2021.
//

import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("DocToolbar")

class DocToolbar: NSToolbar {
    override var isVisible: Bool {
        didSet {
            if self.isVisible != oldValue {
                (self.delegate as? DocWC)?.updateToolbarVisible()
            }
        }
    }
    
    override var delegate: NSToolbarDelegate? {
        didSet {
            if self.delegate !== oldValue {
                (self.delegate as? DocWC)?.updateToolbarVisible()
            }
        }
    }
    
    override init(identifier: NSToolbar.Identifier) {
        super.init(identifier: identifier)
        //dlog?.info("init(identifier) \(identifier)")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //dlog?.info("awakeFromNib \(self.basicDesc)")
    }
    
    deinit {
        //dlog?.info("deinit")
    }
}
