//
//  AppCommand.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import Foundation
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("CmdCenter")

enum AppCommandCategory {
    case app
    case file
    case edit
    case layer
    case view
    case window
    case help
    case misc
}

protocol AppCommand : Command, AnyObject {
    
    // MARK: AppCommand requires:
    static var category : AppCommandCategory { get }
    static var keyboardShortcut : KeyboardShortcut { get }
    static var buttonTitle : String { get }
    static var buttonImageName : String? { get }
    static var menuTitle : String? { get }
    // TODO: In the future /* weak */ static var menuRepresentation : MNMenuItem? { get set}
    static var tooltipTitle : String? { get }
    
    // MARK: Has default implementaions
    static var tooltipTitleFull : String { get }
    var dlog : DSLogger? { get }
    
}

extension AppCommand /* default implementation */ {
    
    static var tooltipTitleFull : String {
        let title = tooltipTitle ?? buttonTitle
        if AppSettings.shared.general.tooltipsShowKeyboardShortcut, keyboardShortcut.isEmpty == false {
            return title + " " + keyboardShortcut.displayString
        }
        return title
    }
    
    var dlog : DSLogger? {
        if IS_DEBUG {
            return DLog.forClass("\(Self.self)")
        }
        return nil
    }
}

extension Array where Element == AppCommand.Type {
    var typeNames : [String] {
        return self.map { cmd in
            return cmd.typeName
        }
    }
}

protocol DocCommand : AppCommand {
    var docID : BrickDocUID { get }
    var doc: BrickDoc? { get }
    override /* weak */ var receiver : CommandReciever? { get set }
}

extension DocCommand {
    var doc: BrickDoc? {
        if let receiver = receiver as? BrickDoc {
            return receiver
        } else {
            let doc = BrickDocController.shared.document(for: docID)
            receiver = doc
            return doc
        }
    }
}

// TODO: If keyboardShortcut become customizable, MacOS allows to save a .dict plist with the custom key bindings
struct KeyboardShortcut {
    let modifiers : NSEvent.ModifierFlags
    let chars : String // charactersIgnoringModifiers

    var isEmpty : Bool {
        return chars.count == 0 || modifiers == []
    }
    
    static var empty : KeyboardShortcut {
        return KeyboardShortcut(modifiers: [], chars: "")
    }
  
    var displayString: String {
        get {
            var char = chars.uppercased()
            switch Int(char.first?.asciiValue ?? 0) {
            case KeyboardKeys.kVK_Delete.rawValue: char = "⌫"
            case KeyboardKeys.kVK_Return.rawValue: char = "↩︎"
            case KeyboardKeys.kVK_Escape.rawValue: char = "⎋"
            case KeyboardKeys.kVK_UpArrow.rawValue: char = "↑"
            case KeyboardKeys.kVK_DownArrow.rawValue: char = "↓"
            case KeyboardKeys.kVK_LeftArrow.rawValue: char = "←"
            case KeyboardKeys.kVK_RightArrow.rawValue: char = "→"
            default:
                break
            }
            return modifiers.displayString + char
        }
    }
}

extension NSEvent.ModifierFlags {
    var displayString: String {
        get {
            var result = ""
            if self.contains(.option)   { result += "⌥" }
            if self.contains(.control)  { result += "⌃" }
            if self.contains(.shift)    { result += "⇧" }
            if self.contains(.command)  { result += "⌘" }
            return result
        }
    }
}

class CommandCenter {
    
    // MARK: Singleton
    public static let shared = CommandCenter()
    private init() {
    }
    
    func registerCommandType(_ cmd: Command.Type)->Bool {
        dlog?.info("registerCommandType \(cmd)")
        return true
    }
}
