//
//  MNButton.swift
//  XPlan
//
//  Created by Ido on 02/11/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("MNButton")

class MNButton: NSButton {
    var associatedCommand : AppCommand.Type? = nil {
        didSet {
            if let cmd = self.associatedCommand {
                self.toolTip = cmd.tooltipTitleFull
                if self.imagePosition == .imageOnly {
                    self.title = ""
                } else {
                    self.title = cmd.buttonTitle
                    if let tttile = cmd.tooltipTitle, !tttile.isEmpty && tttile.willFitBoundingSize(self.bounds.size, attributes: self.attributesForWholeTitle) {
                        // Longer title?
                        self.title = tttile
                    }
                }
                self.keyEquivalent = cmd.keyboardShortcut.chars
                self.keyEquivalentModifierMask = cmd.keyboardShortcut.modifiers
                if let imgName = cmd.buttonImageName, self.image == nil {
                    self.image = NSImage(named: NSImage.Name(imgName))
                }
            }
        }
    }
    
    // private properties
    private var initFrame = CGRect.zero
    private var hoverTrackingArea : NSTrackingArea? = nil
    private var preHoverTintColor : NSColor? = nil
    
    var instrinsicContentSizePadding = NSEdgeInsets.zero
    
    // public var
    @IBInspectable var isDetectHover : Bool = false {
        didSet {
            self.updateTrackingAreas()
        }
    }
    
    @IBInspectable var hoverTextColor : NSColor? = nil {
        didSet {
            if hoverTextColor != nil {
                self.isDetectHover = true
            }
        }
    }
    
    var onMouseEnter : ((_ sender : MNButton)->Void)? = nil
    var onMouseExit : ((_ sender : MNButton)->Void)? = nil
    
    override func updateTrackingAreas() {
        if isDetectHover && self.trackingAreas.count == 0 {
            hoverTrackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: nil)
            self.addTrackingArea(hoverTrackingArea!)
        } else if isDetectHover == false && self.trackingAreas.count > 0, let area = self.hoverTrackingArea {
            self.removeTrackingArea(area)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        //dlog?.info("mouseDown")
        if self.action == nil, let cmd = self.associatedCommand {
            dlog?.note("associatedCommand: [\(cmd.typeName)] needs to be instantiated and added to an invoker.")
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        //dlog?.info("mouseUp")
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        //dlog?.info("mouseEntered")
        onMouseEnter?(self)
        if let color = hoverTextColor {
            preHoverTintColor = self.contentTintColor
            self.contentTintColor = color
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        //dlog?.info("mouseExited")
        onMouseExit?(self)
        if let _ = hoverTextColor {
            self.contentTintColor = preHoverTintColor
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initFrame = self.frame
        // dlog?.info("awakeFromNib [\(self.attributedTitle.string)] sze:\(self.frame.size)")
        DispatchQueue.main.async {[self] in
            self.updateTrackingAreas()
        }
    }
    
    func titleNBSPPrefixIfNeeded(count:Int = 1) {
        if !self.title.hasPrefix(String.NBSP) {
            // dlog?.info("BTN \(button.title)")
            let firstChar = String.NBSP[String.NBSP.startIndex]
            self.title = self.title.paddingLeft(padCount: 1, withPad: firstChar)
            self.needsLayout = true
            self.needsDisplay = true
        }
    }
    
    func calcedTitleSize()->CGSize {
        let attributes = self.attributesForWholeTitle
        let result = (self.title as NSString).boundingRect(with: self.bounds.size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).rounded()
        // dlog?.info(" MNButton titleSze: \"\(self.attributedTitle.string)\": \(result)")
        return result.size
    }
    
    func calcedImageSize()->CGSize {
        if let img = self.state == .on ? self.alternateImage : self.image {
            var result = CGRect(origin: CGPoint.zero, size: img.size.scaled(1.0 / (NSScreen.main?.backingScaleFactor ?? 1.0))).rounded()
            
            var minSide = min(initFrame.width, initFrame.height)
            if minSide == 0 {
                minSide = min(self.frame.width, self.frame.height)
            }
            let minBounds = CGRect(origin: self.bounds.origin, size: CGSize(width: minSide, height: minSide))
            
            // Calc scaling:
            switch self.imageScaling {
            case .scaleAxesIndependently:
                result = self.bounds.rounded()
            case .scaleProportionallyDown:
                let rct = result.aspectFit(rect: minBounds).rounded()
                if rct.width >= img.size.width && rct.height >= img.size.height {
                    result = CGRect(origin: self.bounds.origin, size: img.size)
                }
            case .scaleProportionallyUpOrDown:
                result = result.aspectFit(rect: minBounds).rounded()
            case .scaleNone:
                fallthrough
            default:
                break // keep size
            }
            //dlog?.info(" MNButton imageSze: \"\(self.attributedTitle.string)\": \(result)")
            return result.size
        }
        return CGSize.zero
    }
    
    func calcedTitleRect()->CGRect {
        guard self.title.count > 0 || self.attributedTitle.string.count > 0 else {
            return CGRect.zero // .changed(height: self.bounds.height)
        }
        
        var result = CGRect(origin: CGPoint.zero, size: self.calcedTitleSize())
        let imgSize = self.calcedImageSize()
        if !imgSize.isZero {
            // Calc location
            if imageHugsTitle {
                // dlog?.todo("implement calcedTitleRect for when imageHugsTitle == true")
                switch cell?.alignment ?? .left {
                case .center:
                    return result.settingNewCenter(self.bounds.center)
                case .justified:
                    return result.changed(x: 0)
                case .left:
                    return result.changed(x: 0)
                case .right:
                    return result.changed(x: self.bounds.width - result.width)
                case .natural:
                    return result.settingNewCenter(self.bounds.center)
                @unknown default:
                    return result.changed(x: 0)
                }
            } else {
                switch imagePosition {
                case .noImage:
                    break // Keep rect
                case .imageOnly:
                    result = CGRect.zero
                case .imageLeft:
                    result = result.changed(x: imgSize.width)
                case .imageRight:
                    result = result.changed(x: self.bounds.width - result.width - imgSize.width)
                case .imageBelow:
                    result = result.changed(y: self.bounds.height - result.height - imgSize.height)
                case .imageAbove:
                    result = result.changed(y: imgSize.height)
                case .imageOverlaps:
                    break
                case .imageLeading:
                    result = result.changed(x: IS_RTL_LAYOUT ? self.bounds.width - result.width - imgSize.width : imgSize.width)
                case .imageTrailing:
                    result = result.changed(x: IS_RTL_LAYOUT ? imgSize.width : self.bounds.width - result.width - imgSize.width)
                @unknown default:
                    break
                }
            }
        }
        return result
    }
    
    func calcedImageRect()->CGRect? {
        guard self.image != nil || self.alternateImage != nil else {
            return CGRect.zero // .changed(height: self.bounds.height)
        }
        
        let size = calcedImageSize()
        if size.width != 0.0 && size.height != 0.0 {
            var result = CGRect(origin: CGPoint.zero, size: size)
            
            if imageHugsTitle {
                // dlog?.todo("implement calcedImageRect for when imageHugsTitle == true")
            } else {
                // Calc location
                switch imagePosition {
                case .noImage:
                    result = CGRect.zero
                case .imageOnly:
                    // Keep rect
                    break
                case .imageLeft:
                    result = result.changed(x: 0)
                case .imageRight:
                    result = result.changed(x: self.bounds.width - result.width)
                case .imageBelow:
                    result = result.changed(y: self.bounds.height - result.height)
                case .imageAbove:
                    result = result.changed(y: 0)
                case .imageOverlaps:
                    result = result.changed(x: (self.bounds.width - result.width) * 0.5)
                case .imageLeading:
                    result = result.changed(x: IS_RTL_LAYOUT ? self.bounds.width - result.width : 0.0)
                case .imageTrailing:
                    result = result.changed(x: IS_RTL_LAYOUT ? 0.0 : self.bounds.width - result.width)
                @unknown default:
                    break
                }
            }
            
            return result
        }
        return nil
    }
    
    override var intrinsicContentSize: NSSize {
        var result = calcedTitleRect()
        let imgrect = self.calcedImageRect()
        if imageHugsTitle {
            var mx = super.intrinsicContentSize
            mx.width = max(mx.width + 2, result.width + (imgrect?.width ?? 0.0) + 2)
            return mx.adding(widthAdd: instrinsicContentSizePadding.left + instrinsicContentSizePadding.right, heightAdd: instrinsicContentSizePadding.top + instrinsicContentSizePadding.bottom)
        }
        if let imgrect = imgrect {
            result = result.union(imgrect)
        }
        return result.size.adding(widthAdd: 2)
    }
}

extension MNButton : NSValidatedUserInterfaceItem {
    
}
