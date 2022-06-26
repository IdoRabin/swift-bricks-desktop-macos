//
//  AppAlertButtonsStyle.swift
//  Bricks
//
//  Created by Ido on 29/04/2022.
//

import AppKit

enum AppAlertBtnsStyle {
    case yesNo
    case okCancel
    case nextCancel
    case continueCancel
    case tryAgainOrCancel
    case nextAbort
    
    var buttonTitles : (yes:String, no:String) {
        get {
            var result : (yes:String, no:String) = (yes:"ok", no:"cancel")
            switch self {
            case .yesNo:
                result.yes = AppStr.YES.localized()
                result.no = AppStr.NO.localized()
            case .okCancel:
                result.yes = AppStr.OK.localized()
                result.no = AppStr.CANCEL.localized()
            case .nextCancel:
                result.yes = AppStr.NEXT.localized()
                result.no = AppStr.CANCEL.localized()
            case .continueCancel:
                result.yes = AppStr.CONTINUE.localized()
                result.no = AppStr.CANCEL.localized()
            case .tryAgainOrCancel:
                result.yes = AppStr.TRY_AGAIN.localized()
                result.no = AppStr.CANCEL.localized()
            case .nextAbort:
                result.yes = AppStr.NEXT.localized()
                result.no = AppStr.ABORT.localized()
            }
            return result
        }
    }
}
