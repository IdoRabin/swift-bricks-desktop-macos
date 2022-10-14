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

struct SettingsEnv: OptionSet, Codable {
    let rawValue: Int
    
    static let Server = SettingsEnv(rawValue: 1 << 0)
    static let Client = SettingsEnv(rawValue: 1 << 1)
    
    // All settings
    static let all: SettingsEnv = [.Server, .Client]
    
    static var CurrentEnv : SettingsEnv {
        #if VAPOR
        return .Server
        #else
        return .Client
        #endif
    }
    
    var isInCurrentEnv : Bool {
        return self.contains(Self.CurrentEnv)
    }
}

final class AppSettings : JSONFileSerializable {
    #if VAPOR
    static let FILENAME = AppConstants.BSERVER_APP_SETTINGS_FILENAME
    #else
    static let FILENAME = AppConstants.CLIENT_SETTINGS_FILENAME
    #endif
    
    static var _isLoaded : Bool = false
    static var _initingShared : Bool = false
    
    @SkipEncode private var _changes : [String] = []
    @SkipEncode private var _isLoading : Bool = false
    @SkipEncode private var _isBlockChanges : Bool = false
    
    struct AppSettingsClient : Codable {
        @AppSettable(name:"client.allowsAnalyze", default:true) var allowsAnalyze : Bool
        @AppSettable(name:"client.showsSplashScreenOnInit", default:true) var showsSplashScreenOnInit : Bool
        @AppSettable(name:"client.splashScreenCloseBtnWillCloseApp", default:true) var splashScreenCloseBtnWillCloseApp : Bool
        @AppSettable(name:"client.tooltipsShowKeyboardShortcut", default:true) var tooltipsShowKeyboardShortcut : Bool
    }
    
    struct AppSettingsServer : Codable {
        @AppSettable(name:"server.requestCount", default:0) var requestCount : UInt64
        @AppSettable(name:"server.requestSuccessCount", default:0) var requestSuccessCount : UInt64
        @AppSettable(name:"server.requestFailCount", default:0) var requestFailCount : UInt64
    }
    
    struct AppSettingsStats : Codable {
        @AppSettable(name:"stats.launchCount", default:0) var launchCount : Int
        @AppSettable(name:"stats.firstLaunchDate", default:Date()) var firstLaunchDate : Date
        @AppSettable(name:"stats.lastLaunchDate", default:Date()) var lastLaunchDate : Date
    }
    
    struct AppSettingsDebug : Codable {
        // All default values should be production values.
        @AppSettable(name:"debug.isSimulateNoNetwork", default:false) var isSimulateNoNetwork : Bool
    }
    
    private enum CodingKeys: String, CodingKey {
        case server = "server"
        case client = "client"
        case stats = "stats"
        case debug = "debug"
        case other = "other"
        
        static var all : [CodingKeys] = [.server, .client, .stats, .debug, .other]
        
        static func isOther(key:String)->Bool {
            let prx = key.lowercased().components(separatedBy: ".").first ?? key.lowercased()
            if let key = CodingKeys(stringValue: prx) {
                return (key == .other)
            } else {
                return true
            }
        }
    }
    
    var client : AppSettingsClient?
    var server : AppSettingsServer?
    var stats : AppSettingsStats
    var debug : AppSettingsDebug?
    var other : [String:Any] = [:]
    
    var wasChanged : Bool {
        return _changes.count > 0
    }
    
    static var isLoaded : Bool {
        return Self._isLoaded
    }
    
    var isLoded : Bool {
        return Self.isLoaded && !_isLoading
    }
    
    // MARK: Private
    
    fileprivate static func noteChange(_ change:String, newValue:AnyCodable) {
        AppSettings.shared.noteChange(change, newValue:newValue)
    }
    
    static private func pathToSettingsFile()->URL? {
        guard var path = FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory,
                                                   in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            return nil
        }
        
        // App Name:
        let defaultName = (SettingsEnv.CurrentEnv == .Server) ? "BServer" : "Bricks"
        let appName = (Bundle.main.bundleName ?? defaultName).capitalized.replacingOccurrences(of: .whitespaces, with: "_")
        path = path.appendingPathComponent(appName)
        
        // Create folder if needed
        if !FileManager.default.fileExists(atPath: path.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
            } catch let error {
                dlog?.warning("pathToSettingsFile failed crating /\(appName)/ folder. error: " + error.localizedDescription)
                return nil
            }
        }
        
        path = path.appendingPathComponent(self.FILENAME).appendingPathExtension("json")
        return path
    }
    
    static private func registerIffyCodables() {
        
        // Client:
        #if !VAPOR
        StringAnyDictionary.registerClass(PreferencesVC.PreferencesPage.self)
        #endif
        
        // Server:
        #if VAPOR
//          StringAnyDictionary.registerClass(?? .... )
        #endif
        
        // All Builds:
        StringAnyDictionary.registerClass([String:String].self) // see UnkeyedEncodingContainerEx
    }
    
    // MARK: Public
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
    
    func blockChanges(block:(_ settings : AppSettings)->Void) {
        self._isBlockChanges = true
        block(self)
        self._isBlockChanges = false
        self.saveIfNeeded()
    }
    
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
    private static var _shared : AppSettings? = nil
    public static var shared : AppSettings {
        var result : AppSettings? = nil
        
        if let shared = _shared {
            return shared
        } else if let path = pathToSettingsFile() {
            
            if !_initingShared {
                _initingShared = true
                
                Self.registerIffyCodables()
                
                //  Find setings file in app folder (icloud?)
                let res = Self.loadFromJSON(path)

                switch res {
                case .success(let instance):
                    result = instance
                    Self._isLoaded = true
                    dlog?.success("loaded from: \(path.absoluteString) other: \(instance.other.keysArray.descriptionsJoined)")
                case .failure(let error):
                    let appErr = AppError(error: error)
                    dlog?.fail("Failed loading file, will create new instance. error:\(appErr) path:\(path.absoluteString)")
                     // Create new instance
                     result = AppSettings()
                     _ = result?.saveToJSON(path, prettyPrint: Debug.IS_DEBUG)
                }
            } else {
                dlog?.warning(".shared Possible timed recursion! stack: " + Thread.callStackSymbols.descriptionLines)
            }
        }
        
        _shared = result
        return result!
    }
    
    private init() {
        _isLoading = false
        
        #if VAPOR
        server = AppSettingsServer()
        client = nil
        #else
        client = AppSettingsClient()
        server = nil
        #endif
        
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
        
        if SettingsEnv.CurrentEnv == .Server {
            try cont.encode(server, forKey: CodingKeys.server)
        }
        if SettingsEnv.CurrentEnv == .Client {
            try cont.encode(client, forKey: CodingKeys.client)
        }
        
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
        Self._isLoaded = false
        _changes = []
        debug = nil
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if SettingsEnv.CurrentEnv == .Server {
            server = try values.decodeIfPresent(AppSettingsServer.self, forKey: CodingKeys.server)
        } else {
            server = nil
        }
        
        if SettingsEnv.CurrentEnv == .Client {
            client = try values.decodeIfPresent(AppSettingsClient.self, forKey: CodingKeys.client)
        } else {
            client = nil
        }
        
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

