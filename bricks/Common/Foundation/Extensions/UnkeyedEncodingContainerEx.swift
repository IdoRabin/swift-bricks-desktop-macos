//
//  UnkeyedEncodingContainerEx.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import Foundation
import AppKit
// see also NSColorEx.swift for NSColor.hexString() etc..

fileprivate let dlog : DSLogger? = DLog.forClass("decodeStringAnyDict")

typealias LosslessStrEnum = LosslessStringConvertible & Codable

extension UnkeyedEncodingContainer {
    
    mutating func encode(dic:[String:Any], encoder:Encoder) throws {
        for (key, value) in dic {
            switch value {
            case let val as UInt: try self.encode("\(key) : UInt = \(val)")
            case let val as UInt8: try self.encode("\(key) : Int = \(val)")
            case let val as UInt16: try self.encode("\(key) : Int = \(val)")
            case let val as UInt32: try self.encode("\(key) : Int = \(val)")
            case let val as UInt64: try self.encode("\(key) : Int = \(val)")
                
            case let val as Int: try self.encode("\(key) : UInt = \(val)")
            case let val as Int8: try self.encode("\(key) : UInt8 = \(val)")
            case let val as Int16: try self.encode("\(key) : UInt16 = \(val)")
            case let val as Int32: try self.encode("\(key) : UInt32 = \(val)")
            case let val as Int64: try self.encode("\(key) : UInt64 = \(val)")
                
            case let val as Float: try self.encode("\(key) : Float = \(val)")
            case let val as Double: try self.encode("\(key) : Double = \(val)")
            
            case let val as Date: try self.encode("\(key) : Date = \(val.timeIntervalSince1970)")
            case let val as NSColor: try self.encode("\(key) : NSColor = \(val.hexString() ?? "null")")
            case let val as UUID: try self.encode("\(key) : UUID = \(val.uuidString)")
            
            case let val as LosslessStrEnum:
                let typeStr = String(reflecting:type(of: value))
                let valDesc = val.description
                try self.encode("\(key) : \(typeStr) = .\(valDesc)")
                
            case let val as LosslessStringConvertible:
                let typeStr = String(reflecting:type(of: value))
                let valDesc = val.description
                try self.encode("\(key) : \(typeStr) = \(valDesc)")
                
            case let val as String:
                try self.encode("\(key) : String = \(val)")
                
            case let val as Codable:
                
                let typeStr = String(reflecting:type(of: value))
                dlog?.warning("to support [String:Any] dictionary encodings, type [\(typeStr)] should support LosslessStrEnum or LosslessStringConvertible in order to support encoding value :\(val)")
                
            default:
                break
            }
        }
    }
}

fileprivate var codingRegisteredIffyClasses : [String:Decodable.Type] = [:]

typealias StringAnyDictionary = Dictionary<String, Any>
class StringAny {
    
}
extension StringAnyDictionary {
    static func registerClass(_ avalue:Any) {
        if let val = avalue as? Decodable.Type {
            let type = String(reflecting:avalue)
            codingRegisteredIffyClasses[type] = val
        }
    }
    
    func registerClass(_ avalue:Any) {
        Self.registerClass(avalue)
    }
}

extension UnkeyedDecodingContainer {
    
    mutating private func decode(decoder:Decoder, key:String, typeName:String, value:String) throws ->Any? {
        
        switch typeName {
        case "UInt": return UInt(value)
        case "UInt8": return UInt8(value)
        case "UInt16": return UInt16(value)
        case "UInt32": return UInt32(value)
        case "UInt64": return UInt64(value)
        case "Int": return Int(value)
        case "Int8": return Int8(value)
        case "Int16": return Int16(value)
        case "Int32": return Int32(value)
        case "Int64": return Int64(value)
        case "Float": return Float(value)
        case "Double": return Double(value)
        case "Date": return Date(timeIntervalSince1970: TimeInterval(value)!)
        case "NSColor": if value != "null" { return value.colorFromHex()! }
        case "UUID": return UUID(uuidString: value)
        default:
            if let aatype = codingRegisteredIffyClasses[typeName] as? LosslessStringConvertible.Type {
                let val = aatype.init(value.trimmingPrefix("."))
                dlog?.successOrFail(condition: val != nil, items: "decode: \(aatype) val:\(val.descOrNil)")
                return val
            } else if let aatype = codingRegisteredIffyClasses[typeName] {
                let val = try aatype.init(from:decoder)
                dlog?.info("did decode: \(aatype) val:\(val)")
                return val
            } else {
                dlog?.note("\(key) failed parsing \(typeName) = \(value)")
            }
            break
        }
        return nil
    }
    
    mutating func decodeStringAnyDict(decoder:Decoder) throws ->[String:Any] {
        var result : [String:Any] = [:]

        if let count = self.count {
            for _ in 0..<count {
                
                let str : String = try self.decode(String.self)
                let parts = str.components(separatedBy: " = ")
                let keyEx = parts[0]
                let value = parts.suffix(from: 1).joined(separator: " = ")
                let keyParts = keyEx.components(separatedBy: " : ")
                let key = keyParts[0]
                let typeName = keyParts.suffix(from: 1).joined(separator: " : ")
                if let anyVal = try decode(decoder:decoder, key: key, typeName: typeName, value: value) {
                    result[key] = anyVal
                    dlog?.success("key [\(key)] : [\(type(of: anyVal))] = [\(anyVal)]")
                } else {
                    dlog?.warning("could not decode(key:typeName:value:) key [\(key)] : [\(typeName))] = [\(value)]")
                }
            }
        }
        
        return result
    }
}
