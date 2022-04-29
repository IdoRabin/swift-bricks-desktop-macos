//
//  NSViewController+Validations.swift
//  Bricks
//
//  Created by Ido on 01/01/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("NSViewController+Validations")

public protocol NSUserInterfacePluralValidations : NSUserInterfaceValidations {
    func validateUserInterfaceItems(anyItems: [Any])
    
    func validateUserInterfaceItems(_ items: [NSValidatedUserInterfaceItem])
}

extension NSUserInterfaceValidations {
    
    fileprivate func applyValidation(item:NSValidatedUserInterfaceItem, isEnabled:Bool) {
        switch item {
        case let btn as NSButton:
            btn.isEnabled = isEnabled
        case let mnu as NSMenuItem:
            mnu.isEnabled = isEnabled
        case let tbbtn as NSToolbarItem:
            tbbtn.isEnabled = isEnabled
        default:
            break
        }
    }
}

extension NSUserInterfacePluralValidations /* default implementation */  {
    
    func validateUserInterfaceItems(anyItems: [Any]) {
        if let self = self as? NSViewController, self.isViewLoaded == false {
            dlog?.note("cannot validate UI anyItems before isViewLoaded.")
            return
        }
        
        let validatables : [NSValidatedUserInterfaceItem] = anyItems.map { any in
            any is NSValidatedUserInterfaceItem
        } as? [NSValidatedUserInterfaceItem] ?? []
        if validatables.count > 0 {
            self.validateUserInterfaceItems(validatables)
        }
    }
    
    func validateUserInterfaceItems(_ items: [NSValidatedUserInterfaceItem]) {
        if let self = self as? NSViewController, self.isViewLoaded == false {
            dlog?.note("cannot validate UI items before isViewLoaded.")
            return
        }
        
        for item in items {
            let isEnabled = self.validateUserInterfaceItem(item)
            applyValidation(item: item, isEnabled: isEnabled)
        }
    }
}

extension NSViewController {
    
    @objc func triggerValidations() {
        guard self.isViewLoaded else {
            DLog.ui["\(type(of: self))"]?.note("triggerValidations cannot work when isViewLoaded == false")
            return
        }
        
        let items = self.view.subviews(which: { view in
            switch view {
            case is MNButton: // is NSButton
                return true
            default:
                return false
            }
        }, downtree: true) as? [NSValidatedUserInterfaceItem]

        if items?.count ?? 0 == 0 {
            dlog?.note("triggerValidations for VC: \(type(of: self)) found 0 items to validate")
            let retry = self.view.subviews(which: { view in
                switch view {
                case is NSButton:
                    dlog?.note("triggerValidations    view : \(view) is NSButton - should it be an MNButton?")
                    return true
                default:
                    return false
                }
            }, downtree: true)
            dlog?.note("triggerValidations retry for VC:\(type(of: self)) found \(retry.count) items: \(retry.descriptionsJoined)")
        } else if let plural = self as? NSUserInterfacePluralValidations {
            plural.validateUserInterfaceItems(items ?? [])
        } else if let single = self as? NSUserInterfaceValidations {
            for item in items ?? [] {
                let isEnabled = single.validateUserInterfaceItem(item)
                single.applyValidation(item: item, isEnabled: isEnabled)
            }
        }
    }
}

