//
//  NSViewcontroller+XIB.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import AppKit

extension NSViewController /* load from xib */ {
    
    /// Load the viewController from a xib file with a given name
    /// - Parameter name: name of the xib file, or, if nil, the xib file name is assumed to be the same as the class name
    /// - Returns: an instance
    static func loadFromNib(name:String? = nil) -> Self {
        func instantiateFromNib<T: NSViewController>() -> T {
            let nam = name ?? String(describing: T.self)
            return T.init(nibName: nam, bundle: nil)
        }

        return instantiateFromNib()
    }
    
    static func safeLoadFromNib(name:String? = nil) -> Self? {
        
        func instantiateFromNib<T: NSViewController>() -> T? {
            let nam = name ?? String(describing: T.self)
            guard Bundle.main.path(forResource: nam, ofType: "nib") != nil else {
                return nil
            }
            
            return T.init(nibName: name ?? String(describing: T.self), bundle: nil)
            
        }

        return instantiateFromNib()
    }
}
