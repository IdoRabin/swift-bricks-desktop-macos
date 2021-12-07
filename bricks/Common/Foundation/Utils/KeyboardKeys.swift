//
//  KeyboardKeys.swift
//  Bricks
//
//  Created by Ido Rabin on 23/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation

enum KeyboardLayoutKeys : Int {
    case kVK_ANSI_A                    = 0x00
    case kVK_ANSI_S                    = 0x01
    case kVK_ANSI_D                    = 0x02
    case kVK_ANSI_F                    = 0x03
    case kVK_ANSI_H                    = 0x04
    case kVK_ANSI_G                    = 0x05
    case kVK_ANSI_Z                    = 0x06
    case kVK_ANSI_X                    = 0x07
    case kVK_ANSI_C                    = 0x08
    case kVK_ANSI_V                    = 0x09
    case kVK_ANSI_B                    = 0x0B
    case kVK_ANSI_Q                    = 0x0C
    case kVK_ANSI_W                    = 0x0D
    case kVK_ANSI_E                    = 0x0E
    case kVK_ANSI_R                    = 0x0F
    case kVK_ANSI_Y                    = 0x10
    case kVK_ANSI_T                    = 0x11
    case kVK_ANSI_1                    = 0x12
    case kVK_ANSI_2                    = 0x13
    case kVK_ANSI_3                    = 0x14
    case kVK_ANSI_4                    = 0x15
    case kVK_ANSI_6                    = 0x16
    case kVK_ANSI_5                    = 0x17
    case kVK_ANSI_Equal                = 0x18
    case kVK_ANSI_9                    = 0x19
    case kVK_ANSI_7                    = 0x1A
    case kVK_ANSI_Minus                = 0x1B
    case kVK_ANSI_8                    = 0x1C
    case kVK_ANSI_0                    = 0x1D
    case kVK_ANSI_RightBracket         = 0x1E
    case kVK_ANSI_O                    = 0x1F
    case kVK_ANSI_U                    = 0x20
    case kVK_ANSI_LeftBracket          = 0x21
    case kVK_ANSI_I                    = 0x22
    case kVK_ANSI_P                    = 0x23
    case kVK_ANSI_L                    = 0x25
    case kVK_ANSI_J                    = 0x26
    case kVK_ANSI_Quote                = 0x27
    case kVK_ANSI_K                    = 0x28
    case kVK_ANSI_Semicolon            = 0x29
    case kVK_ANSI_Backslash            = 0x2A
    case kVK_ANSI_Comma                = 0x2B
    case kVK_ANSI_Slash                = 0x2C
    case kVK_ANSI_N                    = 0x2D
    case kVK_ANSI_M                    = 0x2E
    case kVK_ANSI_Period               = 0x2F
    case kVK_ANSI_Grave                = 0x32
    case kVK_ANSI_KeypadDecimal        = 0x41
    case kVK_ANSI_KeypadMultiply       = 0x43
    case kVK_ANSI_KeypadPlus           = 0x45
    case kVK_ANSI_KeypadClear          = 0x47
    case kVK_ANSI_KeypadDivide         = 0x4B
    case kVK_ANSI_KeypadEnter          = 0x4C
    case kVK_ANSI_KeypadMinus          = 0x4E
    case kVK_ANSI_KeypadEquals         = 0x51
    case kVK_ANSI_Keypad0              = 0x52
    case kVK_ANSI_Keypad1              = 0x53
    case kVK_ANSI_Keypad2              = 0x54
    case kVK_ANSI_Keypad3              = 0x55
    case kVK_ANSI_Keypad4              = 0x56
    case kVK_ANSI_Keypad5              = 0x57
    case kVK_ANSI_Keypad6              = 0x58
    case kVK_ANSI_Keypad7              = 0x59
    case kVK_ANSI_Keypad8              = 0x5B
    case kVK_ANSI_Keypad9              = 0x5C
}

/* keycodes for keys that are independent of keyboard layout*/
enum KeyboardKeys : Int {
    case kVK_Return                    = 0x24
    case kVK_Tab                       = 0x30
    case kVK_Space                     = 0x31
    case kVK_Delete                    = 0x33
    case kVK_Escape                    = 0x35
    case kVK_Command                   = 0x37
    case kVK_Shift                     = 0x38
    case kVK_CapsLock                  = 0x39
    case kVK_Option                    = 0x3A
    case kVK_Control                   = 0x3B
    case kVK_RightShift                = 0x3C
    case kVK_RightOption               = 0x3D
    case kVK_RightControl              = 0x3E
    case kVK_Function                  = 0x3F
    case kVK_F17                       = 0x40
    case kVK_VolumeUp                  = 0x48
    case kVK_VolumeDown                = 0x49
    case kVK_Mute                      = 0x4A
    case kVK_F18                       = 0x4F
    case kVK_F19                       = 0x50
    case kVK_F20                       = 0x5A
    case kVK_F5                        = 0x60
    case kVK_F6                        = 0x61
    case kVK_F7                        = 0x62
    case kVK_F3                        = 0x63
    case kVK_F8                        = 0x64
    case kVK_F9                        = 0x65
    case kVK_F11                       = 0x67
    case kVK_F13                       = 0x69
    case kVK_F16                       = 0x6A
    case kVK_F14                       = 0x6B
    case kVK_F10                       = 0x6D
    case kVK_F12                       = 0x6F
    case kVK_F15                       = 0x71
    case kVK_Help                      = 0x72
    case kVK_Home                      = 0x73
    case kVK_PageUp                    = 0x74
    case kVK_ForwardDelete             = 0x75
    case kVK_F4                        = 0x76
    case kVK_End                       = 0x77
    case kVK_F2                        = 0x78
    case kVK_PageDown                  = 0x79
    case kVK_F1                        = 0x7A
    case kVK_LeftArrow                 = 0x7B
    case kVK_RightArrow                = 0x7C
    case kVK_DownArrow                 = 0x7D
    case kVK_UpArrow                   = 0x7E
}
