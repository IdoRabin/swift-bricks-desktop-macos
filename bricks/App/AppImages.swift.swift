//
//  AppImages.swift.swift
//  Bricks
//
//  Created by Ido on 12/12/2021.
//

import AppKit

// All image names used in the app
struct AppImages {
    static let sideMenuLeftCollapsed   =           ImageString("sidebar.left.collapsed")
    static let sideMenuLeftUncollapsed =           ImageString("sidebar.left.uncollapsed")
    static let sideMenuRightCollapsed   =          ImageString("sidebar.right.collapsed")
    static let sideMenuRightUncollapsed =          ImageString("sidebar.right.uncollapsed")
    
    // TODO: Create nicer-version icons for document icons @ small sizes: i.e with better defined outlines.
    static let docNewEmptyDocumentIcon =           ImageString("brick.new.empty.file.icon")
    static let docNewDocumentIcon =                ImageString("brick.new.file.icon")
    static let docRegularDocumentIcon =           ImageString("brick.file.icon")
    
    static func `bool`(_ `bool`:Bool, `true` trueVal:ImageString, `false` falseVal:ImageString)->ImageString {
        return bool ? trueVal : falseVal
    }
}

class NSPlaceholderImage : NSImage {
    convenience init?(named name: String) {
        guard let image = NSImage(named: name), let cgImage = image.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage, size:image.size)
    }
}

struct ImageString {
    let rawValue : String
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    var image : NSImage {
        get {
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
