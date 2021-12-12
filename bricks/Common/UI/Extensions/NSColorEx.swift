//
//  NSColorEx.swift
//
//  Created by Ido on 28/01/2021.
//

import AppKit

extension NSColor {
    /**
     A tuple of the hue, saturation, brightness and alpha components of this NSColor
     calibrated in the RGB color space. Each tuple value is a CGFloat between 0 and 1.
     */
    var CGFloatHSB: (hue:CGFloat, saturation:CGFloat, brightness:CGFloat, alpha:CGFloat)? {
        if let calibratedColor = NSColor.white.usingColorSpace(NSColorSpace.extendedSRGB) {  // genericRGB // NSColorSpace corresponding to Cocoa color space name NSCalibratedRGBColorSpace // NSColorSpaceName.calibratedRGB
        var hueComponent:        CGFloat = 0
        var saturationComponent: CGFloat = 0
        var brightnessComponent: CGFloat = 0
        var alphaFloatValue:     CGFloat = 0
        calibratedColor.getHue(&hueComponent, saturation: &saturationComponent, brightness: &brightnessComponent, alpha: &alphaFloatValue)
        return (hueComponent, saturationComponent, brightnessComponent, alphaFloatValue)
      }
      return nil
    }
    
    public convenience init(withHSB hsb:(hue:CGFloat, saturation:CGFloat, brightness:CGFloat, alpha:CGFloat)) {
        self.init(calibratedHue: hsb.hue, saturation: hsb.saturation, brightness: hsb.brightness, alpha: hsb.alpha)
    }
    
}

extension NSColor { // }: Codable {
    
    static func colorFrom(hex: String)->NSColor? {
        guard hex.hasPrefix("#") || hex.hasPrefix("0x") else {
            return nil
        }
        
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        let dR : CGFloat = CGFloat(r) / 255.0
        let dG : CGFloat = CGFloat(g) / 255.0
        let dB : CGFloat = CGFloat(b) / 255.0
        let dA : CGFloat = CGFloat(a) / 255.0
        return NSColor(srgbRed: dR, green: dG, blue: dB, alpha: dA)
    }
    
    func hexString()->String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = (components.count >= 4) ? Float(components[3]) :  Float(1.0)
        return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
    }
}

extension String {
    func colorFromHex()->NSColor? {
        guard self.hasPrefix("#") || self.hasPrefix("0x") else {
            return nil
        }
        
        return NSColor.colorFrom(hex: self)
    }
}
