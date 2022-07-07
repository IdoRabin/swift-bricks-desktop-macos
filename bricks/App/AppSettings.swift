//
//  AppSettings.swift
//  Bricks
//
//  Created by Ido Rabin on 24/07/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation
// import Codextended

fileprivate let dlog : DSLogger? = DLog.forClass("AppSettings")

final class AppSettings : JSONFileSerializable {
    static let FILENAME = AppConstants.SETTINGS_FILENAME
    
    @SkipEncode private var _changes : [String] = []
    @SkipEncode private var _isLoading : Bool = false
    
    struct AppSettingsGeneral : Codable {
        @AppSettable(true,   name:"general.allowsAnalyze") var allowsAnalyze : Bool
        @AppSettable(true,   name:"general.showsSplashScreenOnInit") var showsSplashScreenOnInit : Bool
        @AppSettable(true,   name:"general.splashScreenCloseBtnWillCloseApp") var splashScreenCloseBtnWillCloseApp : Bool
        @AppSettable(true,   name:"general.tooltipsShowKeyboardShortcut") var tooltipsShowKeyboardShortcut : Bool
    }
    
    struct AppSettingsStats : Codable {
        @AppSettable(0,      name:"stats.launchCount") var launchCount : Int
        @AppSettable(Date(), name:"stats.firstLaunchDate") var firstLaunchDate : Date
        @AppSettable(Date(), name:"stats.lastLaunchDate") var lastLaunchDate : Date
    }
    
    struct AppSettingsDebug : Codable {
        // All default values should be production values.
        @AppSettable(false,   name:"debug.isSimulateNoNetwork") var isSimulateNoNetwork : Bool
    }
    
    private enum CodingKeys: String, CodingKey {
        case general = "general"
        case stats = "stats"
        case debug = "debug"
        case other = "other"
        
        static var all : [CodingKeys] = [.general, .stats, .debug, .other]
        
        static func isOther(key:String)->Bool {
            let prx = key.lowercased().components(separatedBy: ".").first ?? key.lowercased()
            if let key = CodingKeys(stringValue: prx) {
                return (key == .other)
            } else {
                return true
            }
        }
    }
    
    var general : AppSettingsGeneral
    var stats : AppSettingsStats
    var debug : AppSettingsDebug?
    var other : [String:Any] = [:]
    
    var wasChanged : Bool {
        return _changes.count > 0
    }
    
    // MARK: Private
    func noteChange(_ change:String, newValue:Any) {
        guard _isLoading == false else {
            return
        }
        dlog?.info("changed: \(change) = \(newValue)")
        _changes.append(change + " = \(newValue)")
        
        if CodingKeys.isOther(key: change) {
            other[change] = newValue
        }
        
        //TimedEventFilter.shared.filterEvent(key: "AppSettings.changes", threshold: 0.3, accumulating: change) { changes in
        TimedEventFilter.shared.filterEvent(key: "AppSettings.changes", threshold: 0.2) {
            if self._changes.count > 0 {
                // dlog?.info("changed: \(self._changes.descriptionsJoined)")
                
                // Want to save all changes to settings into a seperate log?
                // Do it here! - use self._changes
                
                self.saveIfNeeded()
            }
        }
    }
    
    fileprivate static func noteChange(_ change:String, newValue:AnyCodable) {
        AppSettings.shared.noteChange(change, newValue:newValue)
    }
    
    static private func pathToSettingsFile()->URL? {
        guard var path = FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory,
                                                   in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            return nil
        }
        // path = path.appendingPathComponent(Bundle.main.bundleName?.capitalized ?? "Bricks")
        path = path.appendingPathComponent(self.FILENAME).appendingPathExtension("json")
        return path
    }
    
    static private func registerIffyCodables() {
        StringAnyDictionary.registerClass(PreferencesVC.PreferencesPage.self)
        StringAnyDictionary.registerClass([String:String].self) // see UnkeyedEncodingContainerEx
    }
    
    // MARK: Public
    @discardableResult func saveIfNeeded()->Bool {
        if self.wasChanged {
            self.save()
            self._changes.removeAll()
            return true
        }
        return false
    }
    
    private func save() {
        if let path = Self.pathToSettingsFile() {
            _ = self.saveToJSON(path, prettyPrint: Debug.IS_DEBUG)
            UserDefaults.standard.synchronize()
        }
    }
    
    // MARK: Singleton
    static var sharedWasLoaded : Bool = false
    
    private static var _shared : AppSettings? = nil
    public static var shared : AppSettings {
        var result : AppSettings? = nil
        if let shared = _shared {
            return shared
        } else if let path = pathToSettingsFile() {
            
            Self.registerIffyCodables()
            
            //  Find setings file in app folder (icloud?)
            let res = Self.loadFromJSON(path)
            
            switch res {
            case .success(let instance):
                result = instance
                sharedWasLoaded = true
                dlog?.success("loaded from: \(path.absoluteString) other: \(instance.other.keysArray.descriptionsJoined)")
            case .failure(let error):
                let appErr = AppError(error: error)
                dlog?.fail("Failed loading file, will create new instance. error:\(appErr) path:\(path.absoluteString)")
                // Create new instance
                result = AppSettings()
                _ = result?.saveToJSON(path, prettyPrint: Debug.IS_DEBUG)
            }
        }
        
        _shared = result
        return result!
    }
    
    private init() {
        _isLoading = false
        general = AppSettingsGeneral()
        stats = AppSettingsStats()
        debug = Debug.IS_DEBUG ? AppSettingsDebug() : nil
        dlog?.info("Init \(String(memoryAddressOf: self))")
    }
    
    deinit {
        dlog?.info("deinit \(String(memoryAddressOf: self))")
    }
    // MARK: Codable
    func encode(to encoder: Encoder) throws {
        var cont = encoder.container(keyedBy: CodingKeys.self)
        try cont.encode(general, forKey: CodingKeys.general)
        try cont.encode(stats, forKey: CodingKeys.stats)
        if Debug.IS_DEBUG {
            try cont.encode(debug, forKey: CodingKeys.debug)
        }
        
        if other.count > 0 {
            var sub = cont.nestedUnkeyedContainer(forKey: .other)
            try sub.encode(dic: other, encoder:encoder)
        }
    }
    
    required init(from decoder: Decoder) throws {
        _isLoading = true
        _changes = []
        debug = nil
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        general = try values.decode(AppSettingsGeneral.self, forKey: CodingKeys.general)
        stats = try values.decode(AppSettingsStats.self, forKey: CodingKeys.stats)
        if Debug.IS_DEBUG {
            debug = try values.decodeIfPresent(AppSettingsDebug.self, forKey: CodingKeys.debug) ?? AppSettingsDebug()
        }
        
        if values.allKeys.contains(.other) {
            var sub = try values.nestedUnkeyedContainer(forKey: .other)
            let strAny = try sub.decodeStringAnyDict(decoder: decoder)
            if Debug.IS_DEBUG && sub.count != strAny.count {
                dlog?.info("Failed decoding some StringLosslessConvertible. SUCCESSFUL keys: \(strAny.keysArray.descriptionsJoined). Find which key is missing.")
            }
            for (key, val) in strAny {
                if let val = val as? AnyCodable {
                    other[key] = val
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: 0.05) {
            self._isLoading = false
        }
    }
}
