//
//  BundleEx.swift
//
//
//  Created by Ido on 12/10/2022.
//

import Foundation

extension Bundle {
    
    var versionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    public var fullVersion : String {
        let result = "\(self.versionNumber ?? "0").\(self.buildNumber ?? "0")"
        return result
    }
    
    public var bundleName: String? {
        /*
        property list key CFBundleName
            A user-visible short name for the bundle.
            Name: Bundle name
         
        property list key CFBundleDisplayName
            The user-visible name for the bundle, used by Siri and visible on the iOS Home screen.
            Name: Bundle display name
         
        property list key CFBundleSpokenName
            A replacement for the app name in text-to-speech operations.
            Name: Accessibility Bundle Name
         */
        
        let keys = ["CFBundleDisplayName", "CFBundleName", "CFBundleSpokenName"]
        for key in keys {
            let str = self.infoDictionary?[key] as? String;
            if (str?.count ?? 0 > 0) {
                return str;
            }
        }
        
        return nil
    }
}
