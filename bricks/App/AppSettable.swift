//
//  AppSettable.swift
//  Bricks
//
//  Created by Ido on 07/07/2022.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("AppSettable")

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
        if AppSettings.sharedWasLoaded {
            // dlog?.info("searching for [\(newName)] in \(AppSettings.shared.other.keysArray.descriptionsJoined)")
            if let loadedVal = AppSettings.shared.other[newName] as? T {
                self._value = loadedVal
                dlog?.success("found and set for [\(newName)] in \(AppSettings.shared.other.keysArray.descriptionsJoined)")
            } else {
                if Debug.IS_DEBUG && AppSettings.shared.other[newName] != nil {
                    dlog?.warning("failed cast \(AppSettings.shared.other[newName].descOrNil) as \(T.self)")
                }
                
                self._value = wrappedValue
            }
        } else {
            self._value = wrappedValue
        }
        
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
