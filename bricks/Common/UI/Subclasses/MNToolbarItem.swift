//
//  MNToolbarItem.swift
//  grafo
//
//  Created by Ido on 30/01/2021.
//

import Cocoa

fileprivate let dlog : DSLogger? = DLog.forClass("MNToolbarItem")

class MNToolbarItem: NSToolbarItem {
    var associatedCommand : AppCommand.Type? = nil
}

class MNToggleToolbarItem: MNToolbarItem {
    
    let DEFAULT_BUTTON_SIZE : CGFloat = 50.0
    
    @IBInspectable var isToggledOn : Bool = true {
        didSet {
            dlog?.info("  isToggledOn >>> \(isToggledOn)")
            if isToggledOn != oldValue, let btn = self.view as? NSButton {
                btn.state =  isToggledOn ? .on : .off
                self.updateImage()
            }
        }
    }
    
    var auxTag : Int = 0
    @IBInspectable var onImage : NSImage? = nil
    @IBInspectable var offImage : NSImage? = nil
    @IBInspectable var onTint : NSColor? = nil
    @IBInspectable var offTint : NSColor? = nil
    @IBInspectable var imagesScale : CGFloat = 1.0
    
    var fwdAction : Selector? = nil
    weak var fwdTarget : AnyObject? = nil
    
    func updateImage() {
        if let btn = self.view as? NSButton {
            
            let rect = CGRect(origin: .zero, size: CGSize(width: DEFAULT_BUTTON_SIZE, height: DEFAULT_BUTTON_SIZE))
            
            if isToggledOn {
                dlog?.info("isToggledOn YES")
                if let onImg = self.onImage ?? self.image {
                    btn.image = onImg.scaledToFit(boundingSize: rect.size.scaled(self.imagesScale))
                }
                if let onTint = self.onTint {
                    btn.image = btn.image?.tinted(onTint)
                    btn.contentTintColor = onTint
                }
            } else {
                dlog?.info("isToggledOn NO")
                if let offImg = self.offImage {
                    btn.image = offImg.scaledToFit(boundingSize: rect.size.scaled(self.imagesScale))
                }
                if let offTint = self.offTint {
                    btn.image = btn.image?.tinted(offTint)
                    btn.contentTintColor = self.offTint
                }
            }
            
            btn.needsLayout = true
            btn.needsDisplay = true
        }
    }
    
    private func setup() {
        // Will forwards the action to this target:
        fwdAction = self.action
        fwdTarget = self.target ?? self.toolbar
        
        // Button:
        let btnRect = CGRect(origin: CGPoint.zero, size: CGSize(width: 48, height: 48))
        let btn = NSButton(frame: btnRect)
        btn.bezelStyle = .recessed
        btn.focusRingType = .none
        btn.isBordered = false
        btn.layer?.backgroundColor = NSColor.clear.cgColor
        btn.layer?.isOpaque = false
        btn.image = self.onImage ?? self.offImage ?? self.image
        btn.imageScaling = .scaleProportionallyDown
        btn.action = #selector(mnToggleToolbarItemButtonAction(_:))
        btn.target = self
        btn.autoresizingMask = [.none]
        self.view = btn
        
        DispatchQueue.main.async {
            btn.frame = btnRect
            self.updateImage()
        }
    }
    
    override init(itemIdentifier: NSToolbarItem.Identifier) {
        super.init(itemIdentifier: itemIdentifier)
        setup()
    }
    
    override func awakeFromNib() {
        if self.responds(to: #selector(self.awakeFromNib)) {
            super.awakeFromNib()
        }
        
        setup()
    }
    
    override func validate() {

        // validate content view
        if let control = self.view as? NSControl,
            let action = fwdAction ?? self.action,
            let validator = fwdTarget ?? NSApp.target(forAction: action, to: self.target, from: self) as AnyObject?
        {
            var newIsEnabled = true
            switch validator {
            case let validator as NSUserInterfaceValidations:
                newIsEnabled = validator.validateUserInterfaceItem(self)
            case let validator as NSToolbarItemValidation:
                newIsEnabled = validator.validateToolbarItem(self)
            default:
                super.validate()
                newIsEnabled = control.isEnabled
            }
            control.isEnabled = newIsEnabled
        } else {
            super.validate()
        }
    }
    
    @objc func mnToggleToolbarItemButtonAction(_ sender : Any) {
        if let action = self.fwdAction {
            var targets : [AnyObject] = []
             
            dlog?.info("Action ----------")
            
            // Ugly.. // study chain of first responders to see how to find the correct one..
            if let ac = fwdTarget { targets.append(ac) }
            if let targ = self.view?.window?.contentView?.firstSubview(which: { aview in
                aview.responds(to: action)
            }, downtree: true) {
                targets.append(targ)
            }
            if let ac = self.view?.window?.contentViewController { targets.append(ac) }
            if let ac = self.view?.window?.contentViewController?.presentedViewControllers { targets.append(contentsOf: ac) }
            if let ac = self.view?.window?.contentViewController?.presentingViewController { targets.append(ac) }
            if let ac = self.view?.window?.contentViewController { targets.append(ac) }
            if let ac = self.view?.window?.contentView { targets.append(ac) }
            if let ac = self.view?.window { targets.append(ac) }
            if let ac = self.view?.window?.firstResponder { targets.append(ac) }
            if let ac = self.target { targets.append(ac) }
            if let ac = self.toolbar { targets.append(ac) }
            
            for target in targets {
                if target.responds(to: fwdAction) {
                    fwdTarget = target
                    
                    if self.autovalidates {
                        
                    }
                    target.performSelector(onMainThread: action, with: self, waitUntilDone: false)
                    return
                }
            }
            dlog?.note("could not find a target to forward the action: \(fwdAction?.description ?? "<nil>" )")
        }
    }
}
