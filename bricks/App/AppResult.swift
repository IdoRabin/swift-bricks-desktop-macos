//
//  AppResult.swift
//  XPlan
//
//  Created by Ido on 08/11/2021.
//

import Foundation

public enum AppResultUpdates : CustomStringConvertible {
    case noChanges
    case newData
    
    public var description: String {
        switch self {
        case .newData: return "AppResultUpdates.newData"
        case .noChanges: return "AppResultUpdates.noChanges"
        }
    }
}

public enum AppResultAcceptDecline : CustomStringConvertible {
    case accept
    case decline
    
    public var description: String {
        switch self {
        case .accept: return "AppResultAcceptDecline.accept"
        case .decline: return "AppResultAcceptDecline.decline"
        }
    }
}


typealias AppResultAcceptedDeclined = Result<AppResultAcceptDecline, AppError>
typealias AppResultAcceptedDeclinedBlock = (AppResultAcceptedDeclined)->Void

typealias AppResultUpdated = Result<AppResultUpdates, AppError>
typealias AppResultUpdatedBlock = (AppResultUpdated)->Void

typealias AppResult = Result<Any, AppError>
typealias AppResultBlock = (AppResult)->Void


func AppResultOrErr(_ result:Any?, error:AppError)->AppResult {
    if let result = result {
        return AppResult.success(result)
    } else {
        return AppResult.failure(error)
    }
}
