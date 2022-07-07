//
//  ImageString.swift
//  Bricks
//
//  Created by Ido on 06/07/2022.
//

import AppKit

struct ImageString {
    let rawValue : String
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    func systemSymbolImage(accessibilityDescription:String?)->NSImage {
        return NSImage(systemSymbolName: rawValue, accessibilityDescription: nil)!
    }
    
    var systemSymbolImage : NSImage {
        get {
            // NOTE: This will crash if string is an asset name
            return NSImage(systemSymbolName: rawValue, accessibilityDescription: nil)!
        }
    }
    
    var image : NSImage {
        get {
            // NOTE: This will crash if string is a system symbol name
            return NSImage(named:self.rawValue)!
        }
    }
    
    var placeholderImage : NSPlaceholderImage {
        get {
            return NSPlaceholderImage(named:self.rawValue)!
        }
    }
    
    func imageTinted(_ color:NSColor)->NSImage {
        return self.image.tinted(color)!
    }
    
    func imageScaled(_ scale:CGFloat)->NSImage {
        return self.image.scaled(scale)!
    }
    
    func image(scale:CGFloat, tintColor:NSColor)->NSImage {
        return self.image.scaled(scale)!.tinted(tintColor)!
    }
}
