//
//  AppAlertMacOSDialog.swift
//  Bricks
//
//  Created by Ido on 29/04/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("AppAlertMacOSDialog")
class AppAlertMacOSDialog : AppAlertPresenter {
    
    private func isDestructive( _ str:String)->Bool {
        let strLow = str.lowercased()
        let possibles = [AppStr.DELETE.localized(), AppStr.REMOVE.localized()].lowercased
        for possible in possibles {
            if strLow.contains(possible) {
                return true
            }
        }
        return false
    }
    
    func present(title: String, message: String?, titles: [String], hostVC: NSViewController?, presentationComplete: AlertEmptyCompletion?, completion: AlertCompletion?) {
        guard let window = hostVC?.view.window else {
            return
        }
        
        // present a macOS dialog alert
        let alert = NSAlert()
        var style : NSAlert.Style = .informational
        
        // Bold title Under the image:
        alert.messageText = title
        
        // Running text:
        if let message = message {
            alert.informativeText = message
        }
        
        var buttonTitles = titles
        
        // Seems like setting a button to destructive only works when the button is not the first one (and thus not the blue highlighted button). For everyone curious, this is how it could look in code:
        if isDestructive(titles.first ?? "") {
            buttonTitles = titles.reversed()
        }
        
        // Add the button using the titles:
        for title in buttonTitles {
            let button = alert.addButton(withTitle: title)
            if isDestructive(title) {
                button.hasDestructiveAction = true
                button.wantsLayer = true
                
                // button.layer?.backgroundColor = NSColor.appFailureRed.cgColor
                style = .warning
            }
        }
        
        alert.alertStyle = style
        alert.beginSheetModal(for: window) { response in
            var idx : Int? = nil
            switch response /* as! NSModalResponse */ {
            case NSApplication.ModalResponse.alertFirstButtonReturn: idx = 0
            case NSApplication.ModalResponse.alertSecondButtonReturn: idx = 1
            case NSApplication.ModalResponse.alertThirdButtonReturn: idx = 3
            default: break
            }
            if let idx = idx, idx >= 0, idx < alert.buttons.count {
                let title = alert.buttons[idx].title
                dlog?.info("User selected button: [\(title)]")
                completion?(title)
            } else {
                dlog?.warning("Unknown alert button tapped!")
                completion?(AppStr.UNTITLED.localized())
            }
        }
    }

}
