//
//  AppConstants.swift
//  Bricks
//
//  Created by Ido Rabin on 02/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import AppKit
import AudioToolbox

public let IS_DEBUG = true
let IS_RTL_LAYOUT : Bool = NSApplication.shared.userInterfaceLayoutDirection == .rightToLeft

func AppPlayAlertSound() {
    let systemSoundId: SystemSoundID = kSystemSoundID_UserPreferredAlert
    AudioServicesPlaySystemSound(systemSoundId)
}

extension NSColor {
    static var appFailureOrange =  NSColor(named: "failure_orange_color")!
    static var appFailureRed    =  NSColor(named: "failure_red_color")!
    static var appSuccessGreen  =  NSColor(named: "success_green_color")!
    static var appLabelColor : NSColor {
        return labelColor
    }
}

struct AppConstants {
    static let SETTINGS_FILENAME = "bricks_app_settings"
    static let DOCUMENT_HISTORY_FILENAME = "brick_file_history"
    static let BRICK_FILE_EXTENSION = "bricks"
    static let BRICK_FILE_UTI = "com.idorabin.bricks.document"
    
    static let RULE_SET_FILE_EXTENSTION = "bricksruleset"
    
    static let BUTTON_CORNER_SMALL : CGFloat = 4.0
    static let BUTTON_CORNER_BIG : CGFloat = 6.0
}

// Constants
extension String {
    public static let NBSP = "\u{00A0}"
    public static let THIN_SPACE = "\u{2009}" // “thin space”, less than a full space
    public static let FIGURE_SPACE = "\u{2007}" // “Tabular width”, the width of digits
    public static let IDEOGRAPHIC_SPACE = "\u{3000}" // The width of ideographic (CJK) characters.
    public static let NBHypen = "\u{2011}" // non-breaking hyphen
    public static let ZWSP = "\u{200B}" // Use with great care! ZERO WIDTH SPACE (HTML &#8203)
}

extension Date {
    public static let SECONDS_IN_A_MONTH : TimeInterval = 86400.0 * 7.0 * 4.0
    public static let SECONDS_IN_A_WEEK : TimeInterval = 86400.0 * 7.0
    public static let SECONDS_IN_A_DAY : TimeInterval = 86400.0
    public static let SECONDS_IN_A_DAY_INT : Int = 86400
    public static let SECONDS_IN_AN_HOUR : TimeInterval = 3600.0
    public static let SECONDS_IN_AN_HOUR_INT : Int = 3600
    public static let SECONDS_IN_A_MINUTE : TimeInterval = 60.0
    public static let MINUTES_IN_AN_HOUR : TimeInterval = 60.0
    public static let MINUTES_IN_A_DAY : TimeInterval = 1440.0
}

extension NSView {
    var isDarkThemeActive : Bool {
        if #available(OSX 10.14, *) {
            return self.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua, .vibrantDark]) == .darkAqua
        }
        return false
    }
}

func isDarkThemeActive(view: NSView) -> Bool {
    
    if #available(OSX 10.14, *) {
        return view.isDarkThemeActive
    }
    return false
}
