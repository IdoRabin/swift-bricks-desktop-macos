//
//  KeyboardShortcut.swift
//  Bricks
//
//  Created by Ido on 06/01/2022.
//

import AppKit

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
            if self.contains(.function) { result += "fn" }
            return result
        }
        
    }
}

/*
HTML Entity     GLYPH  NAME
&#63743;              Apple
&#8984;         ⌘      Command, Cmd, Clover, (formerly) Apple
&#8963;         ⌃      Control, Ctl, Ctrl
&#8997;         ⌥      Option, Opt, (Windows) Alt
&#8679;         ⇧      Shift
&#8682;         ⇪      Caps lock
&#9167;         ⏏      Eject
&#8617;         ↩      Return, Carriage Return
&#8629; &crarr; ↵      Return, Carriage Return
&#9166;         ⏎      Return, Carriage Return
&#8996;         ⌤      Enter
&#9003;         ⌫      Delete, Backspace
&#8998;         ⌦      Forward Delete
&#9099;         ⎋      Escape, Esc
&#8594; &rarr;  →      Right arrow
&#8592; &larr;  ←      Left arrow
&#8593; &uarr;  ↑      Up arrow
&#8595; &darr;  ↓      Down arrow
&#8670;         ⇞      Page Up, PgUp
&#8671;         ⇟      Page Down, PgDn
&#8598;         ↖      Home
&#8600;         ↘      End
&#8999;         ⌧      Clear
&#8677;         ⇥      Tab, Tab Right, Horizontal Tab
&#8676;         ⇤      Shift Tab, Tab Left, Back-tab
&#9250;         ␢      Space, Blank
&#9251;         ␣      Space, Blank\
*/
