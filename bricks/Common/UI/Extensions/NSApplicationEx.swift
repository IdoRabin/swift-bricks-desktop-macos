//
//  NSApplicationEx.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import AppKit

extension NSApplication {
    
    func isWindowExistsOfClass<T:NSWindow>(_ wclass:T.Type)->Bool {
        for window in windows {
            if window is T {
                return true
            }
        }
        return false
    }
    
    func isViewControllerExistsOfClass<T:NSViewController>(_ vclass:T.Type)->Bool {
        for window in windows {
            if window.contentViewController is T {
                return true
            }
        }
        return false
    }
    
}
