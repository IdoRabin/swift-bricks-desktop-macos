//
//  NSApplicationEx.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import AppKit

extension NSApplication {
    
    func findPresentedVC<T:NSViewController>(identifier:String)->T? {
        let clearID = identifier.trimmingSuffix("VCID").trimmingSuffix("WCID").appending("VCID")
        
        for window in self.windows {
            if window.contentViewController?.identifier?.rawValue == clearID,
               let vc = window.contentViewController as? T {
                return vc
            }
        }
        return nil
    }
    
    func findPresentedWindow<T:NSWindow>(identifier:String)->T? {
        let clearID = identifier.trimmingSuffix("VCID").trimmingSuffix("WCID").appending("WCID")
        
        for window in self.windows {
            if window.identifier?.rawValue == clearID,
               let vc = window as? T {
                return vc
            }
        }
        return nil
    }
    
    func findPresentedVCsOfType<T:NSViewController>(_ type:T.Type)->[T] {
        var result : [T] = []
        for window in self.windows {
            if let vc = window.contentViewController as? T {
                result.append(vc)
            }
        }
        return result
    }
    
    func findPresentedWCsOfType<T:NSWindowController>(_ type:T.Type)->[T] {
        var result : [T] = []
        for window in self.windows {
            if let wc = window.windowController as? T {
                result.append(wc)
            }
        }
        return result
    }
    
    func findPresentedWindowOfType<T:NSWindow>(_ type:T.Type)->T? {
        for window in self.windows {
            if let vc = window as? T {
                return vc
            }
        }
        return nil
    }

    func isWindowControllerExistsOfClass<T:NSWindowController>(_ vclass:T.Type)->Bool {
        return self.findPresentedWCsOfType(vclass).count > 0
    }
    
    func isViewControllerExistsOfClass<T:NSViewController>(_ vclass:T.Type)->Bool {
        return self.findPresentedVCsOfType(vclass).count > 0
    }
    
    func isViewControllerExists(identifier:String)->Bool {
        return findPresentedVC(identifier: identifier) != nil
    }
    
}
