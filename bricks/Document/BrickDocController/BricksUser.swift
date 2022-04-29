//
//  BricksUser.swift
//  Bricks
//
//  Created by Ido on 06/04/2022.
//

import Foundation

typealias UserResult = Result<BricksUser?, AppError>
typealias UserResultBlock = (UserResult)->Void

class BricksUser : BUIDable, CodableHashable, CustomStringConvertible {
    
    static let UNNAMED_USER_STRING = AppStr.UNNAMED.localized()
    var name : String = AppStr.UNNAMED.localized()
    var id : UserUID
    
    static func == (lhs: BricksUser, rhs: BricksUser) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
    
    init(id newId:UserUID?, name newName:String) {
        id = newId ?? UserUID()
        name = newName
    }
    
    var description: String {
        return "<\(id) [\(name.description)]>"
    }
}
