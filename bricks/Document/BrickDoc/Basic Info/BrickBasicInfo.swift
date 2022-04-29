//
//  BrickBasicInfo.swift
//  Bricks
//
//  Created by Ido Rabin on 11/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation

struct BrickBasicInfo : Codable, CustomDebugStringConvertible, Hashable, BUIDable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var debugDescription: String {
        get {
            let formatter = DateFormatter.formatterByDateFormatString("dd/MM/yy HH:mm:ss.SSS")
            return "BrickBasicInfo \(displayName ?? "< untitled >" ) \(formatter.string(from: self.creationDate)) \(id)"
        }
    }
    
    var creationDate:Date
    var creatingUserId:UserUID? = nil
    var lastOpenedDate:Date? = nil
    var lastClosedDate:Date? = nil
    var lastModifiedDate:Date? = nil
    var lastSavedDate:Date? = nil
    var shouldRestoreOnInit:Bool = false
    
    // MARK: Identifiable / BUIDable
    var id : BrickDocUID
    
    private var _displayName : String? = nil
    var filePath : URL? = nil
    var templateType : BrickTemplateType = .unknown
    var versionControlType : BrickVersionControlType = .none
    var projectVersionControlPath : URL? = nil
    var projectFolderPath : URL? = nil
    var projectFilePath : URL? = nil
    
    public var displayName : String? {
        get {
            return self._displayName
        }
        set {
            let fileExtension = BrickDoc.extension() ?? AppConstants.BRICK_FILE_EXTENSION
            self._displayName = newValue?.trimmingSuffix("." + fileExtension)
        }
    }
    
    
    init() {
        self.id = BrickDocUID(uid: UUID()) // UUID.init()
        self.creationDate = Date()
        self.lastModifiedDate = nil
        self.lastOpenedDate = nil
        self.filePath = nil
        self.templateType = .unknown
    }
}

// Sort by date in an array
extension Array where Element == BrickBasicInfo {
    func sortedByDate()->[BrickBasicInfo] {
        return self.sorted(by: { (infoA, infoB) -> Bool in
            if let a = infoA.lastModifiedDate, let b = infoB.lastModifiedDate {
                return a > b
            }
            
            if let a = infoA.lastClosedDate, let b = infoB.lastOpenedDate {
                return a > b
            }
            
            if let a = infoA.lastOpenedDate, let b = infoB.lastOpenedDate {
                return a > b
            }
            
            return infoA.creationDate > infoB.creationDate
        })
    }
}

// Sort by date in a dictionary
extension Dictionary where Value == BrickBasicInfo {
    func valuesSortedByDate()->[BrickBasicInfo] {
        return self.valuesArray.sortedByDate()
    }
}
