//
//  NSBundle+Versions.swift
//  Bricks
//
//  Created by Ido Rabin on 02/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation

// Swift 3
extension Bundle {

    var versionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    var fullVersionAsDisplayString : String {
        var strings : [String] = []
        if let ver = Bundle.main.versionNumber {
            strings.append(ver)
        }
        if let build = Bundle.main.buildNumber {
            strings.append(build)
        }
        return strings.joined(separator: " build ")
    }
}
