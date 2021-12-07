//
//  AppSettings.swift
//  Bricks
//
//  Created by Ido Rabin on 24/07/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("AppSettings")

final class AppSettings : JSONFileSerializable {
    static let FILENAME = AppConstants.SETTINGS_FILENAME
    
    @SkipEncode private var _changes : [String] = []
    @SkipEncode private var _isLoading : Bool = false
    
    struct AppSettingsGeneral : Codable {
        @AppSettable(true,   name:"general.allowsAnalyze") var allowsAnalyze : Bool
        @AppSettable(true,   name:"general.showsSplashScreenOnInit") var showsSplashScreenOnInit : Bool
        @AppSettable(true,   name:"general.splashScreenCloseBtnWillCloseApp") var splashScreenCloseBtnWillCloseApp : Bool
    }
    
    struct AppSettingsStats : Codable {
        @AppSettable(0,      name:"state.launchCount") var launchCount : Int
        @AppSettable(Date(), name:"state.firstLaunchDate") var firstLaunchDate : Date
        @AppSettable(Date(), name:"state.lastLaunchDate") var lastLaunchDate : Date
    }
    
    struct AppSettingsDebug : Codable {
        // All default values should be production values.
        @AppSettable(false,   name:"debug.isSimulateNoNetwork") var isSimulateNoNetwork : Bool
    }
    
    private enum CodingKeys: String, CodingKey {
        case general = "general"
        case stats = "stats"
        case debug = "debug"
    }
    var general : AppSettingsGeneral
    var stats : AppSettingsStats
    var debug : AppSettingsDebug?
    
    var wasChanged : Bool {
        return _changes.count > 0
    }
    
    // MARK: Private
    fileprivate func noteChange(_ change:String, newValue:Any) {
        guard _isLoading == false else {
            return
        }
        dlog?.info("changed: \(change)")
        _changes.append(change + " = \(newValue)")
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
    
    fileprivate static func noteChange(_ change:String, newValue:Any) {
        AppSettings.shared.noteChange(change, newValue:newValue)
    }
    
    static private func pathToSettingsFile()->URL? {
        guard let path = FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            return nil
        }
        return path.appendingPathComponent(self.FILENAME).appendingPathExtension("json")
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
            _ = self.saveToJSON(path, prettyPrint: IS_DEBUG)
            UserDefaults.standard.synchronize()
        }
    }
    
    // MARK: Singleton
    private static var _shared : AppSettings? = nil
    public static var shared : AppSettings {
        var result : AppSettings? = nil
        if let shared = _shared {
            return shared
        } else if let path = pathToSettingsFile() {
            
            //  Find setings file in app folder (icloud?)
            let res = Self.loadFromJSON(path)
            
            switch res {
            case .success(let instance):
                result = instance
                // dlog?.success("loaded from: \(path.absoluteString)")
            case .failure(let error):
                let appErr = AppError(error: error)
                dlog?.fail("Failed loading file, will create new instance. error:\(appErr) path:\(path.absoluteString)")
                // Create new instance
                result = AppSettings()
                _ = result?.saveToJSON(path, prettyPrint: IS_DEBUG)
            }
        }
        
        _shared = result
        return result!
    }
    
    private init() {
        dlog?.info("Init")
        _isLoading = false
        general = AppSettingsGeneral()
        stats = AppSettingsStats()
        debug = IS_DEBUG ? AppSettingsDebug() : nil
    }
    
    // MARK: Codable
    func encode(to encoder: Encoder) throws {
        var cont = encoder.container(keyedBy: CodingKeys.self)
        try cont.encode(general, forKey: CodingKeys.general)
        try cont.encode(stats, forKey: CodingKeys.stats)
        if IS_DEBUG {
            try cont.encode(debug, forKey: CodingKeys.debug)
        }
    }
    
    required init(from decoder: Decoder) throws {
        _isLoading = true
        _changes = []
        debug = nil
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        general = try values.decode(AppSettingsGeneral.self, forKey: CodingKeys.general)
        stats = try values.decode(AppSettingsStats.self, forKey: CodingKeys.stats)
        if IS_DEBUG {
            debug = try values.decodeIfPresent(AppSettingsDebug.self, forKey: CodingKeys.debug) ?? AppSettingsDebug()
        }
        DispatchQueue.main.asyncAfter(delayFromNow: 0.05) {
            self._isLoading = false
        }
    }
}

// MARK: AppSettable protocol - depends on AppSettings
@propertyWrapper
struct AppSettable<T:Equatable & Codable> : Codable {

    // MARK: properties
    private var _value : T
    var wrappedValue : T {
        get {
            return _value
        }
        set {
            let oldValue = _value
            let newValue = newValue
            if newValue != oldValue {
                _value = newValue
                let changedKey = name.count > 0 ? "\(self.name)" : "\(self)"
                AppSettings.shared.noteChange(changedKey, newValue: newValue)
            }
        }
    }

    @SkipEncode var name : String = ""
    
    init(_ wrappedValue:T, name newName:String) {
        self._value = wrappedValue
        self.name = newName
    }
    
    // MARK: AppSettable: Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self._value = try container.decode(T.self)
        
        self.name = container.codingPath.compactMap({ key in
            return key.stringValue
        }).joined(separator: ".")
    }
    
    // MARK: AppSettable: Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_value)
    }
    
}
