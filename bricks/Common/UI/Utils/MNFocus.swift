//
//  MNFocus.swift
//  grafo
//
//  Created by Ido on 28/01/2021.
//

import Cocoa

protocol MNFocusObserver {
    func mnFocusChanged(from:NSResponder?, to:NSResponder?)
}

fileprivate let v = MNFocus.shared
class MNFocus {
    
    var observers = ObserversArray<MNFocusObserver>()
    
    // MARK: Shared instance and lifecycle
    // Singleton
    static let shared = MNFocus()
    private init()
    {
        // Setup
    }
    
    var current : NSResponder? = nil {
        didSet {
            if oldValue != current {
                // notify listeners / observers
                observers.enumerateOnMainThread { (observer) in
                    oldValue?.resignFirstResponder()
                    observer.mnFocusChanged(from: oldValue, to: self.current)
                }
            }
        }
    }
    
    func didResignFocusNotif(view:NSResponder) {
        if current == view {
            current = nil
        }
    }
    
    func didBecomeFocusNotif(view:NSResponder) {
        if current != view {
            current = view
        }
    }
}

extension NSView {
    var isFirstResponder : Bool {
        return MNFocus.shared.current == self
    }
}
