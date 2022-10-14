//
//  PreferencesVC.swift
//  Bricks
//
//  Created by Ido on 11/12/2021.
//

import AppKit
// import Codextended

fileprivate let dlog : DSLogger? = DLog.forClass("PreferencesVC")

class PreferencesVC : NSPageController {
    
    // MARK: Properties:
    private var DEBUG_DRAWING = Debug.IS_DEBUG && true
    private var isAppearing : Bool = true
    
    fileprivate func updatePageIndex() {
        if let index = PreferencesPage.allValidPages.firstIndex(of: lastSelectedPreferencesPage) {
            self.selectedIndex = Int(index.magnitude)
            self.title = lastSelectedPreferencesPage.displayString
            self.view.window?.title = lastSelectedPreferencesPage.displayString
        }
    }
    
    fileprivate var lastSelectedToolbarItemID : NSToolbarItem.Identifier? = nil
    @AppSettable(name:"preferences.lastSelectedPreferencesPage", default: .unknown) var lastSelectedPreferencesPage : PreferencesPage {
        didSet {
            self.updatePageIndex()
        }
    }
    
    // MARK: Enum PreferencesPage
    enum PreferencesPage : String, Equatable, LosslessStrEnum {
        case unknown
        case general
        case accounts
        case keybindings
        
        var asToolbarItemID : NSToolbarItem.Identifier? {
            guard self != .unknown else {
                return nil
            }
            
            return NSToolbarItem.Identifier(rawValue: self.rawValue + "ToolbarItemID")
        }
        
        init?(_ description: String) {
            self.init(rawValue: description)
        }
        
        var description: String {
            return self.rawValue
        }
        
        var asPageControllerVCID : NSPageController.ObjectIdentifier {
            switch self {
            case .unknown:
                return ""
            default:
                return "Prefs\(self.rawValue.capitalized)VCID"
            }
        }
        var displayString : String {
            switch self {
            case .unknown:   return AppStr.UNTITLED.localized()
            case .general:   return AppStr.GENERAL.localized()
            case .accounts:  return AppStr.ACCOUNTS.localized()
            case .keybindings: return AppStr.KEY_BINDINGS.localized()
            }
        }
        
        var displayTooltipString : String {
            var result : String = ""
            switch self {
            case .unknown:   result = AppStr.UNTITLED.localized()
            case .general:   result = AppStr.GENERAL_PREFERENCES_TOOLTIP.localized()
            case .accounts:  result = AppStr.ACCOUNTS_PREFERENCES_TOOLTIP.localized()
            case .keybindings: result = AppStr.KEY_BINDINGS_PREFERENCES_TOOLTIP.localized()
            }
            
            // TODO: Keyboard shortcut for mocing between tabs in the toolbar?
            //if AppSettings.shared.general.tooltipsShowKeyboardShortcut {
            //    result += " tab"
            //}
            return result
        }
        
        static var all : [PreferencesPage] = [.unknown, .general, .accounts, .keybindings]
        static var allValidPages : [PreferencesPage] = [.general, .accounts, .keybindings]
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.arrangedObjects = PreferencesPage.allValidPages
        dlog?.info("viewDidLoad ")
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.delegate = self
        
        if let toolbar = self.view.window?.toolbar {
            toolbar.delegate = self
            PreferencesPage.allValidPages.forEachIndex { index, page in
                if index < toolbar.items.count {
                    let item = toolbar.items[index]
                    item.target = self
                    item.action = #selector(toolbarItemSelected(_:))
                    item.label = page.displayString
                    item.paletteLabel = page.displayString
                    item.toolTip = page.displayTooltipString
                }
            }
            
            // dlog?.info("restore last selected preferences toolbar item: \(self.lastSelectedPreferencesPage)")
            if let toolbarItemID = self.lastSelectedPreferencesPage.asToolbarItemID {
                dlog?.info("last selected toolbar item: \(toolbarItemID.rawValue)")
                toolbar.selectedItemIdentifier = toolbarItemID
            } else {
                toolbar.selectedItemIdentifier = PreferencesPage.general.asToolbarItemID
                dlog?.info("last selected toolbar item: \(toolbar.selectedItemIdentifier.descOrNil) (DEFAULT)")
            }
            
        }
        self.view.window?.toolbar?.validateVisibleItems()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        dlog?.info("viewDidAppear")
        isAppearing = false
    }
    
    deinit {
        dlog?.info("deinit \(self.basicDesc)")
    }
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        dlog?.info("validateUserInterfaceItem \(item)")
        
        return true
    }
}

extension PreferencesVC : NSPageControllerDelegate {
    
    func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
        dlog?.info("pageController:didTransitionTo: \(object) \(self.selectedIndex) \(type(of: self.selectedViewController))")
    }
    
    func pageController(_ pageController: NSPageController, frameFor object: Any?) -> NSRect {
        return self.view.bounds.insetBy(dx: 20, dy: 20)
    }
    
    func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?) {
        // dlog?.info("pageController prepare viewController:\(type(of: viewController)) \(String(memoryAddressOf: viewController)) for: \(object)")
    }
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        guard let object = object as? PreferencesPage else {
            dlog?.warning("pageController:identifierFor: arranged objet \(object) is expected to be of type :\(PreferencesPage.self)")
            return PreferencesPage.general.asPageControllerVCID
        }
        return object.asPageControllerVCID
    }
    
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        let vc = AppStoryboard.onboarding.instantiateViewController(id: identifier)!
        
        if DEBUG_DRAWING {
            waitFor("vc \(identifier)", interval: 0.03, timeout: 0.1, testOnMainThread: {
                vc.isViewLoaded
            }, completion: { waitResult in
                DispatchQueue.mainIfNeeded {
                    vc.view.debugBorder(color: .cyan, width: 1)
                }
            }, logType: .allAfterFirstTest)
        }
        return vc
    }
}

extension PreferencesVC : NSToolbarDelegate {
    
    func didSelectToolbarItem(_ identifier: NSToolbarItem.Identifier?) {
        
        if lastSelectedToolbarItemID != identifier {
            lastSelectedToolbarItemID = identifier
            
            var selectedPreferencesPage : PreferencesPage = .general
            if let identifier = identifier {
                let str = identifier.rawValue.replacingOccurrences(ofFromTo: ["ToolbarItemID":""]).lowercased()
                if let page = PreferencesPage(rawValue: str) {
                    selectedPreferencesPage = page
                } else {
                    selectedPreferencesPage = .general
                    dlog?.note("Failed parsing toolbar item id: \(identifier) to enum PreferencesPage")
                }
            }
        
            if !isAppearing {
                self.lastSelectedPreferencesPage = selectedPreferencesPage
            } else {
                self.updatePageIndex()
            }
        }
    }
    
    @objc func toolbarItemSelected(_ toolbaritem: NSToolbarItem) {
        self.didSelectToolbarItem(toolbaritem.itemIdentifier)
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        dlog?.info("toolbarDefaultItemIdentifiers")
        return []
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        dlog?.info("toolbarAllowedItemIdentifiers")
        return []
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        self.didSelectToolbarItem(toolbar.selectedItemIdentifier)
        return []
    }
    
    
}

extension PreferencesVC : SinglyInstanced {
    static var isRequiresSingeInstance: Bool { return true }
}
