//
//  AppCommand.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import Foundation
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("CmdCenter")

enum AppCommandCategory {
    case app
    case file
    case edit
    case layer
    case view
    case window
    case help
    case misc
}

protocol AppCommand : Command, AnyObject {
    
    // MARK: AppCommand requires:
    static var category : AppCommandCategory { get }
    static var keyboardShortcut : KeyboardShortcut { get }
    static var buttonTitle : String { get }
    static var buttonImageName : String? { get }
    static var menuTitle : String? { get }
    // TODO: In the future /* weak */ static var menuRepresentation : MNMenuItem? { get set}
    static var tooltipTitle : String? { get }
    
    // MARK: Has default implementaions
    static var tooltipTitleFull : String { get }
    var dlog : DSLogger? { get }
    
    var category : AppCommandCategory { get }
}

extension AppCommand /* default implementation */ {
    
    static var tooltipTitleFull : String {
        let title = tooltipTitle ?? buttonTitle
        if AppSettings.shared.client!.tooltipsShowKeyboardShortcut, keyboardShortcut.isEmpty == false {
            return title + " " + keyboardShortcut.displayString
        }
        return title
    }
    
    var category : AppCommandCategory {
        return Self.category
    }
    
    var dlog : DSLogger? {
        if Debug.IS_DEBUG {
            return DLog.forClass("\(Self.self)")
        }
        return nil
    }
}

extension Array where Element == AppCommand.Type {
    var typeNames : [String] {
        return self.map { cmd in
            return cmd.typeName
        }
    }
}

protocol DocCommand : AppCommand {
    var docID : BrickDocUID { get }
    var doc: BrickDoc? { get }
    override /* weak */ var receiver : CommandReciever? { get set }
}

extension DocCommand {
    var doc: BrickDoc? {
        if let receiver = receiver as? BrickDoc {
            return receiver
        } else {
            let doc = BrickDocController.shared.document(for: docID)
            receiver = doc
            return doc
        }
    }
    
    var docWC  : DocWC? {
        return doc?.windowControllers.first(where: { wc in
            wc is DocWC
        }) as? DocWC
    }
}

class CommandCenter {
    
    // MARK: Singleton
    public static let shared = CommandCenter()
    private init() {
    }
    
    func registerCommandType(_ cmd: Command.Type)->Bool {
        dlog?.info("registerCommandType \(cmd)")
        return true
    }
}
