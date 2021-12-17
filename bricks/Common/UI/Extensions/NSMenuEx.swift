//
//  NSMenuEx.swift
//  Bricks
//
//  Created by Ido on 15/12/2021.
//

import Foundation
import AppKit

extension Array where Element == NSUserInterfaceItemIdentifier {
    var rawValues : [String] {
        return self.compactMap { id in
            return id.rawValue
        }
    }
}

extension Array where Element : NSMenuItem {
    
    // MARK: Private
    private func internal_FindItems(conformingToTest test:(NSMenuItem)->Bool, recursive:Bool = true, depth:Int = 0)->[NSMenuItem] {
        guard depth < 127 else {
            return []
        }
        
        var result : [NSMenuItem] = []
        for item in self {
            if test(item) {
                result.append(item)
            }

            if item.hasSubmenu && recursive {
                let subsz = item.submenu!.items.internal_FindItems(conformingToTest: test, recursive: recursive, depth: depth + 1)
                result.append(contentsOf: subsz)
            }
        }

        return result
    }
    
    // MARK: Public
    func filter(conformingToTest test:(NSMenuItem)->Bool, recursive:Bool = true)->[NSMenuItem] {
        return internal_FindItems(conformingToTest: test, recursive: recursive, depth: 0)
    }
    
    func filter(ids:[NSUserInterfaceItemIdentifier], recursive:Bool = false)->[NSMenuItem] {
        let idStrs = ids.rawValues
        return internal_FindItems(conformingToTest: { item in
            idStrs.contains(item.identifier?.rawValue.lowercased() ?? "")
        }, recursive: true, depth: 0)
    }
    
    func filter(ids:[String], recursive:Bool = false, caseSensitive:Bool = false)->[NSMenuItem] {
        let idsStrs = caseSensitive ? ids : ids.lowercased
        return internal_FindItems(conformingToTest: { item in
            if let id = item.identifier?.rawValue {
                return idsStrs.contains(caseSensitive ? id : id.lowercased())
            }
            return false
        }, recursive: true, depth: 0)
    }
    
    func filter(idFragments:[[String]], caseSensitive:Bool = false, recursive:Bool = false)->[NSMenuItem] {
        var idFrags = idFragments
        if caseSensitive == false {
            idFrags = idFragments.compactMap({ ids in
                ids.lowercased
            })
        }
        
        return internal_FindItems(conformingToTest: { item in
            for frags in idFrags {
                if let id = caseSensitive ? item.identifier?.rawValue : item.identifier?.rawValue.lowercased() {
                    if id.contains(allOf: frags) {
                        return true
                    }
                }                
            }
            return false
        }, recursive: true, depth: 0)
    }
    
    
}
