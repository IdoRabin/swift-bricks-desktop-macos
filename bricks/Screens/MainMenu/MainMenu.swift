//
//  MainMenu.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import AppKit

class MainMenu : NSMenu {
    fileprivate let dlog : DSLogger? = nil // DLog.forClass("MainMenu")
    
    enum Category : Int, Hashable {
        // Groups
        case allTopItems
        case allLeafItems
        
        // Main Menu items
        case app
        case file
        case edit
        case view
        case layer
        case window
        case help
    }
    
    // Bricks menu
    @IBOutlet weak var bricksTopMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksAboutMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksPreferencesMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksServicesMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksServicesSubmenu: NSMenu!
    @IBOutlet weak var   bricksHideMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksHideOthersMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksShowAllMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksQuitMnuItem: NSMenuItem!
    
    // File menu
    @IBOutlet weak var fileTopMnuItem: NSMenuItem!
    @IBOutlet weak var   fileNewMnuItem: NSMenuItem!
    @IBOutlet weak var   fileOpenMnuItem: NSMenuItem!
    @IBOutlet weak var   fileOpenRecentMnuItem: NSMenuItem!
    @IBOutlet weak var   fileOpenRecentSubmenu: NSMenu!
    @IBOutlet weak var      fileClearRecentsMenuItem: NSMenuItem!
    @IBOutlet weak var   fileCloseMnuItem: NSMenuItem!
    @IBOutlet weak var   fileCloseAllMnuItem: NSMenuItem!
    @IBOutlet weak var   fileSaveMnuItem: NSMenuItem!
    @IBOutlet weak var   fileSaveAsMnuItem: NSMenuItem!
    @IBOutlet weak var   fileDuplicateMnuItem: NSMenuItem!
    @IBOutlet weak var   fileRenameMnuItem: NSMenuItem!
    @IBOutlet weak var   fileMoveToMnuItem: NSMenuItem!
    @IBOutlet weak var   fileRevertToToMnuItem: NSMenuItem?
    @IBOutlet weak var   fileRevertToSavedMnuItem: NSMenuItem!
    @IBOutlet weak var   fileShareMnuItem: NSMenuItem!
    @IBOutlet weak var   filePageSetupMnuItem: NSMenuItem!
    @IBOutlet weak var   filePrintMnuItem: NSMenuItem!
    
    // Edit menu
    @IBOutlet weak var editTopMnuItem: NSMenuItem!
    @IBOutlet weak var   editUndoMnuItem: NSMenuItem!
    @IBOutlet weak var   editRedoMnuItem: NSMenuItem!
    @IBOutlet weak var   editCutMnuItem: NSMenuItem!
    @IBOutlet weak var   editCopyMnuItem: NSMenuItem!
    @IBOutlet weak var   editPasteMnuItem: NSMenuItem!
    @IBOutlet weak var   editDeleteMnuItem: NSMenuItem!
    @IBOutlet weak var   editSelectAllMnuItem: NSMenuItem!
    @IBOutlet weak var   editFindMnuItem: NSMenuItem!
    @IBOutlet weak var   editFindSubmenu: NSMenu!
    @IBOutlet weak var     editFindFindMnuItem: NSMenuItem!
    @IBOutlet weak var     editFindNextMnuItem: NSMenuItem!
    @IBOutlet weak var     editFindPreviousMnuItem: NSMenuItem!
    
    // View menu
    @IBOutlet weak var viewTopMnuItem: NSMenuItem!
    @IBOutlet weak var   viewShowToolbarMnuItem: NSMenuItem!
    @IBOutlet weak var   viewCustomizeToolbarMnuItem: NSMenuItem!
    @IBOutlet weak var   viewShowProjectSidebarMnuItem: NSMenuItem!
    @IBOutlet weak var   viewShowUtilitySidebarMnuItem: NSMenuItem!
    @IBOutlet weak var   viewZoomMnuItem: NSMenuItem!
    @IBOutlet weak var   viewZoomSubmenu: NSMenu!
    @IBOutlet weak var      viewZoomInMnuItem: NSMenuItem!
    @IBOutlet weak var      viewZoomTo100MnuItem: NSMenuItem!
    @IBOutlet weak var      viewZoomOutMnuItem: NSMenuItem!
    @IBOutlet weak var      viewZoomToFitMnuItem: NSMenuItem!
    @IBOutlet weak var   viewEnterFullScreenMnuItem: NSMenuItem!
    
    // Layer menu
    @IBOutlet weak var layerTopMnuItem: NSMenuItem!
    @IBOutlet weak var   layerAddMenuItem: NSMenuItem!
    @IBOutlet weak var   layerDeleteMenuItem: NSMenuItem!
    @IBOutlet weak var   layerEditMenuItem: NSMenuItem!
    @IBOutlet weak var   layerLockMenuItem: NSMenuItem!
    @IBOutlet weak var   layerShowHideMenuItem: NSMenuItem!
    @IBOutlet weak var   layerHideOthersMenuItem: NSMenuItem!
    @IBOutlet weak var   layerShowAllMenuItem: NSMenuItem!
    
    // Window menu
    @IBOutlet weak var windowTopMnuItem: NSMenuItem!
    @IBOutlet weak var   windowMinimizeMnuitem: NSMenuItem!
    @IBOutlet weak var   windowZoomMnuItem: NSMenuItem!
    @IBOutlet weak var   windowBringAllToFrontMnuItem: NSMenuItem!
    
    // help menu
    @IBOutlet weak var helpTopMnuItem: NSMenuItem!
    @IBOutlet weak var   helpMnuItem: NSMenuItem!
    @IBOutlet weak var   helpTooltipsShowKeyboardShortcutsMnuItem: NSMenuItem!
    
    private(set) var menuItems : [Category:[NSMenuItem]] = [:]
    
    var allLeafItems : [NSMenuItem] {
        if menuItems[.allLeafItems]?.count ?? 0 == 0 {
            self.recalcLeafItems()
        }
        return menuItems[.allLeafItems] ?? []
    }
    
    var unhookedSystemItems : [NSMenuItem]? = Debug.IS_DEBUG ? [] : nil
    
    enum State {
        enum StateSimplified : Int {
            case disabled
            case splashScreen
            case document
            case documentWithModal
            
            var isEnabled : Bool {
                return self != .disabled
            }
        }
        
        case disabled
        case splashScreen
        case document
        case documentWithModal(String)
        var simplified : StateSimplified {
            switch self {
            case .disabled : return .disabled
            case .splashScreen: return .splashScreen
            case .document: return .document
            case .documentWithModal: return .documentWithModal
            }
        }
        
        var isEnabled : Bool {
            return self.simplified != .disabled
        }
    }
    
    // MARK: Privarte properties
    private(set) var state : State = .disabled {
        didSet {
            if state.simplified != oldValue.simplified {
                dlog?.info("state didSet \(state)")
            }
        }
    }

    /// All menu items that represent the doc windows (expected to be in the window submenu's bottom)
    private var docWindowsItems : [NSMenuItem] {
        guard let submenu = windowTopMnuItem.submenu else {
            return []
        }
        
        var result : [NSMenuItem] = submenu.items.filter({ menuItem in
            return "\(type(of: menuItem))" == "NSWindowRepresentingMenuItem"
        })
        
        if result.count == 0, let index = submenu.items.firstIndex(of: windowBringAllToFrontMnuItem) {
            result = Array(submenu.items.suffix(from: index))
        }
        return result
    }
    
    // MARK: Private funcs
    
    private func hookupMenuSystemItem(_ item:NSMenuItem)->Bool {
        guard item.action != nil || self.allLeafItems.contains(item) else {
            return false
        }
        
        let actionDesc = item.action.descOrNil
        switch actionDesc {
        // File
        case "closeAll:": fileCloseAllMnuItem = item
        case "duplicateDocument:": fileDuplicateMnuItem = item
        case "renameDocument:": fileRenameMnuItem = item
        case "moveDocument:": fileMoveToMnuItem = item
        case "revertDocumentToSaved:": fileRevertToSavedMnuItem = item
        case "showAboutPanel:": bricksAboutMnuItem = item
        case "showPreferencesMenuAction:": bricksPreferencesMnuItem = item
        case "clearRecentDocuments:": fileOpenRecentMnuItem = item
        case "newDocument:": fileNewMnuItem = item
        case "openDocument:": fileOpenMnuItem = item
        case "performClose:": fileCloseMnuItem = item
        case "saveDocument:": fileSaveMnuItem = item
        case "saveDocumentAs:": fileSaveAsMnuItem = item
            // Revert To" is unknown. action: submenuAction:
            // "Move To…" is unknown. action: moveDocument:
            // "Duplicate" is unknown. action: duplicateDocument:
            // "Rename…" is unknown. action: renameDocument:
            // case "submenuAction:": break // ??
            // case "startDictation:": break
            // case "orderFrontCharacterPalette:": break
        // case "toggleFullScreen:": viewEnterFullScreenMnuItem = item
            // case "makeKeyAndOrderFront:": break
        case "submenuAction:":
            if item.hasSubmenu && menuItems[.allTopItems]?.contains(item) ?? false == false, let parent = item.menu {
                
                dlog?.info("CHECKING menu [\(parent.title)]:[\(item.title)]) items: \(item.submenu?.items.count ?? 0)")
            }
        default:
            // dlog?.note("unknown SystemItem:\(actionDesc)")
            unhookedSystemItems?.append(item)
            break
        }
        return false
    }
    
    private func setup(menu:NSMenu, depth:Int = 0) {

        guard depth < 10 else {
            dlog?.warning("localize recursion is > 10 depth. @ menu : \(menu.title)")
            return
        }
        
        // TODO: Associate AppCommands to all menu items
        for item in menu.items {
            let skip = item.isSeparatorItem
            if !skip {
                
                if self.hookupMenuSystemItem(item) {
                    // dlog?.info("Hooked up menu item:\(item.action.descOrNil)")
                }
                
                var title = ""
                let productName = AppStr.PRODUCT_NAME.localized()
                let curProjectName = ""
                let actionToUndoTitle = ""
                let actionToRedoTitle = ""
                let curZoomTitle = "100%"
                let curLayerName = ""
                var note = "" // trailing after the menu item name, in a smaller font size and grey color
                var cmd : AppCommand.Type? = nil
                
                switch item {
                case bricksTopMnuItem: title = AppStr.PRODUCT_NAME.localized()
                case   bricksAboutMnuItem: cmd = CmdAboutPanel.self  //  AppStr.ABOUT_APP_FORMAT.formatLocalized(productName)
                case   bricksPreferencesMnuItem: cmd = CmdPreferencesPanel.self // AppStr.PREFERENCES.localized()
                case   bricksServicesMnuItem: title = AppStr.SERVICES.localized()
                case   bricksHideMnuItem: title = AppStr.HIDE_APP_FORMAT.formatLocalized(productName)
                case   bricksHideOthersMnuItem: title = AppStr.HIDE_OTHERS.localized()
                case   bricksShowAllMnuItem: title = AppStr.SHOW_ALL.localized()
                case   bricksQuitMnuItem: title = AppStr.QUIT_APP_FORMAT.formatLocalized(productName)
                    
                case fileTopMnuItem: title = AppStr.FILE.localized()
                case   fileNewMnuItem: cmd = CmdNewProject.self//title = AppStr.NEW_PROJECT_DOT_DOT.localized()
                case   fileOpenMnuItem: title = AppStr.OPEN_PROJECT_DOT_DOT.localized()
                case   fileOpenRecentMnuItem, fileOpenRecentSubmenu:
                          title = AppStr.OPEN_RECENT.localized()
                case      fileClearRecentsMenuItem: title = AppStr.CLEAR_MENU.localized()
                case   fileCloseMnuItem: title = AppStr.CLOSE_FORMAT.formatLocalized(curProjectName)
                case   fileCloseAllMnuItem: title = AppStr.CLOSE_ALL.localized()
                case   fileSaveMnuItem: title = AppStr.SAVE.localized()
                case   fileSaveAsMnuItem: title = AppStr.SAVE_AS_DOT_DOT.localized()
                case   fileDuplicateMnuItem: title = AppStr.DUPLICATE.localized()
                case   fileRenameMnuItem: title = AppStr.RENAME_DOT_DOT.localized()
                case   fileMoveToMnuItem: title = AppStr.MOVE_TO_DOT_DOT.localized()
                case   fileRevertToToMnuItem: title = AppStr.REVERT_TO_DOT_DOT.localized()
                case   fileRevertToSavedMnuItem: title = AppStr.REVERT_TO_SAVED_DOT_DOT.localized()
                case   filePageSetupMnuItem: title = AppStr.PAGE_SETUP_DOT_DOT.localized()
                case   filePrintMnuItem: title = AppStr.PRINT_DOT_DOT.localized()
                    
                case editTopMnuItem: title = AppStr.EDIT.localized()
                case   editUndoMnuItem: title = AppStr.UNDO_FORMAT.formatLocalized(actionToUndoTitle)
                case   editRedoMnuItem: title = AppStr.REDO_FORMAT.formatLocalized(actionToRedoTitle)
                case   editCutMnuItem: title = AppStr.CUT.localized()
                case   editCopyMnuItem: title = AppStr.COPY.localized()
                case   editPasteMnuItem: title = AppStr.PASTE.localized()
                case   editDeleteMnuItem: title = AppStr.DELETE.localized()
                case   editSelectAllMnuItem: title = AppStr.SELECT_ALL.localized()
                case   editFindMnuItem, editFindSubmenu:
                    title = AppStr.FIND.localized()
                case     editFindFindMnuItem: title = AppStr.FIND_DOT_DOT.localized()
                case     editFindNextMnuItem: title = AppStr.FIND_NEXT.localized()
                case     editFindPreviousMnuItem: title = AppStr.FIND_PREVIOUS.localized()
                    
                case viewTopMnuItem: title = AppStr.VIEW.localized()
                case   viewShowToolbarMnuItem:  title = AppStr.SHOW_TOOLBAR.localized()
                case   viewCustomizeToolbarMnuItem: title = AppStr.CUSTEMIZE_TOOLBAR_DOT_DOT.localized()
                case   viewShowProjectSidebarMnuItem: title = AppStr.SHOW_PROJECTS_SIDEBAR.localized() //+ AppStr.HIDE_PROJECTS_SIDEBAR.localized()
                case   viewShowUtilitySidebarMnuItem: title = AppStr.SHOW_UTILITY_SIDEBAR.localized() //+ AppStr.HIDE_UTILITY_SIDEBAR.localized()
                case   viewZoomMnuItem, viewZoomSubmenu:
                          title = AppStr.ZOOM.localized()
                          note = curZoomTitle
                case      viewZoomInMnuItem:    title = AppStr.ZOOM_IN.localized()
                case      viewZoomTo100MnuItem: title = AppStr.ZOOM_TO_100_PRC.localized()
                case      viewZoomOutMnuItem:   title = AppStr.ZOOM_OUT.localized()
                case      viewZoomToFitMnuItem: title = AppStr.ZOOM_TO_FIT.localized()
                // DO NOT! case   viewEnterFullScreenMnuItem:  title = AppStr.ENTER_FULL_SCREEN.localized() //+ AppStr.EXIT_FULL_SCREEN.localized()
                    
                case layerTopMnuItem: title = AppStr.LAYER.localized()
                case layerAddMenuItem: cmd = CmdLayerAdd.self // AppStr.ADD.localized()
                case layerDeleteMenuItem: cmd = CmdLayerRemove.self // title = AppStr.DELETE_FORMAT_DOT_DOT.formatLocalized(curLayerName)
                case layerEditMenuItem: cmd = CmdLayerEdit.self // AppStr.EDIT_FORMAT_DOT_DOT.formatLocalized(curLayerName)
                case layerLockMenuItem: title = AppStr.LOCK.localized() //+ AppStr.UNLOCK.localized()
                case layerShowHideMenuItem: title = AppStr.SHOW.localized() //+ AppStr.HIDE.localized()
                case layerHideOthersMenuItem: title = AppStr.HIDE_OTHERS.localized()
                case layerShowAllMenuItem: title = AppStr.SHOW_ALL.localized()
                    
                case windowTopMnuItem: title = AppStr.WINDOW.localized()
                case   windowMinimizeMnuitem: title = AppStr.MINIMIZE.localized()
                case   windowZoomMnuItem: title = AppStr.ZOOM.localized()
                case   windowBringAllToFrontMnuItem: title = AppStr.BRING_ALL_TO_FRONT.localized()
                    
                case helpTopMnuItem: title = AppStr.HELP.localized()
                case helpMnuItem: title = AppStr.DOCUMENTATION.localized() // + AppStr.SUPPORT.localized
                case helpTooltipsShowKeyboardShortcutsMnuItem: title = AppStr.KEY_BINDINGS_APPEAR_IN_TOOLTIPS.localized()
                default:
                    title = "" // ❌Unknown❌"
                    if item.menu == fileOpenRecentSubmenu {
                        if item == fileOpenRecentSubmenu.items.last {
                            // Clear menu item is last
                            title = AppStr.CLEAR_MENU.localized()
                        }
                    }
                    if title.count == 0, unhookedSystemItems != nil  {
                        unhookedSystemItems?.append(item)
                         // dlog?.note("Localized title for \"\(item.title)\" is unknown. action: \(item.action.descOrNil)")
                    }
                    break
                }

                if let cmd = cmd, let item = item as? MNMenuItem {
                    item.associatedCommand = cmd
                    // TODO: Should we link the menu item with the command?
                    // cmd.menuRepresentation = item
                } else if title.count > 0 {
                    if note.count != 0 {
                        let attributes = item.attributedTitle?.attributes(at: 0, effectiveRange: nil)
                        let attr = NSMutableAttributedString(string: title + String.NBSP + String.NBSP + String.NBSP + note, attributes: attributes)
                        attr.setAtttibutesForStrings(matching: note, attributes: [.font:NSFont.systemFont(ofSize: 10)])
                        item.attributedTitle = attr
                    } else {
                        item.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    if note.count > 0 {
                        item.keyEquivalent = note
                    }
                }
                
                if item.hasSubmenu, let submenu = item.submenu {
                    submenu.title = title
                    self.setup(menu: submenu, depth: depth + 1)
                }
            }
        }
        
        if depth == 0 {
            unhookedSystemItems = unhookedSystemItems?.uniqueElements()
        }
    }
    
    private func setEnabled(_ enabled:Bool, items:[NSMenuItem] = [], except:[NSMenuItem]) {

        for item in items {
            var isEnable = (except.contains(item)) ? !enabled : enabled
            if isEnable, let item = item as? MNMenuItem, let cmd = item.associatedCommand, let result = BrickDocController.shared.isAllowed(commandType: cmd, context: "MainMenu.setEnabledforMenuItems").asOptionalBool {
                isEnable = result
            }
            item.isEnabled = isEnable
        }
    }
    
    private func setAllEnabled(_ enabled:Bool, except:[NSMenuItem] = []) {

        self.setEnabled(enabled, items: allLeafItems, except: except)
    }
    
    private func disableAll(except:[NSMenuItem] = []) {
        self.setAllEnabled(false, except: except)
    }
    
    private func enableAll(except:[NSMenuItem] = []) {

        self.setAllEnabled(true, except: except)
    }
    
    // MARK: Public
    
    func updateWindowsDynamicMenuItems() {
        
        // Updates the menu items correlated with the document windows (NSWindowRepresentingMenuItem)
        let items = self.docWindowsItems
        for item in items {
            if let window = item.target as? NSWindow, let docWC = window.windowController as? DocWC, let doc = docWC.document as? BrickDoc {
                item.image = doc.docSaveState.iconImage.scaledToFit(boundingSizes: 22)
            }
        }
    }
    
    func recalcLeafItems() {

        var newItems : [NSMenuItem] = []
        func addLeafItems(_ xitems:[NSMenuItem], depth:Int = 0) {
            guard depth < 127 else {
                return
            }
            
            for item in xitems {
                if item.hasSubmenu == false {
                    newItems.append(item)
                } else {
                    addLeafItems(item.submenu?.items ?? [], depth: depth + 1)
                }
            }
        }
        addLeafItems(menuItems[.allTopItems] ?? [], depth: 0)
        menuItems[.allLeafItems] = newItems
    }
    
    // MARK: Update menu using the current Doc:
                        
    func updateMenuItems(categories:Set<MainMenu.Category>, context:String) {
        var items : [NSMenuItem] = []
        for category in categories {
            items.append(contentsOf: self.menuItems[category] ?? [])
        }
        self.updateMenuItems(items, context: context)
    }
    
    // MARK: Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        DispatchQueue.main.async {
             AppDelegate.shared.mainMenu = self
        }
        
        menuItems[.allTopItems] = [
            bricksTopMnuItem, fileTopMnuItem, editTopMnuItem, layerTopMnuItem, viewTopMnuItem, windowTopMnuItem, helpTopMnuItem
        ]

        menuItems[.app] = [
            bricksAboutMnuItem, bricksPreferencesMnuItem, bricksServicesMnuItem, bricksHideMnuItem, bricksHideOthersMnuItem, bricksShowAllMnuItem, bricksQuitMnuItem
        ]
        menuItems[.file] = [
            fileNewMnuItem, fileOpenMnuItem, fileClearRecentsMenuItem, fileCloseMnuItem, fileSaveMnuItem, fileSaveAsMnuItem, fileRevertToSavedMnuItem, filePageSetupMnuItem, filePrintMnuItem
        ]
        menuItems[.edit] = [
            editUndoMnuItem, editRedoMnuItem, editCutMnuItem, editCopyMnuItem, editPasteMnuItem, editDeleteMnuItem, editSelectAllMnuItem, editFindFindMnuItem, editFindNextMnuItem, editFindPreviousMnuItem
        ]

        menuItems[.view] = [
            viewShowToolbarMnuItem, viewCustomizeToolbarMnuItem, viewShowProjectSidebarMnuItem, viewShowUtilitySidebarMnuItem, viewZoomMnuItem, viewZoomInMnuItem, viewZoomTo100MnuItem, viewZoomOutMnuItem, viewZoomToFitMnuItem, viewEnterFullScreenMnuItem
        ]
        menuItems[.layer] = [
            layerAddMenuItem, layerDeleteMenuItem, layerEditMenuItem, layerLockMenuItem, layerShowHideMenuItem, layerHideOthersMenuItem, layerShowAllMenuItem
        ]
        menuItems[.window] = [
            windowMinimizeMnuitem, windowZoomMnuItem, windowBringAllToFrontMnuItem,
        ]
        
        menuItems[.help] = [
            helpMnuItem, helpTooltipsShowKeyboardShortcutsMnuItem
        ]
        
        viewCustomizeToolbarMnuItem.isHidden = true
        
        DispatchQueue.main.async {
            self.setup(menu: self)
            self.recalcLeafItems()
        }
    }
}

extension MainMenu /* load from nib */ {
    
    @objc class func fromNib()-> MainMenu? {
        var contentViews : NSArray? = nil
        let name = String(describing: self)
        if Bundle.main.loadNibNamed(name, owner: nil, topLevelObjects: &contentViews), let contentViews = contentViews {
            return contentViews.first { anyItm in
                anyItm is Self
            } as? Self
        }
        return nil
    }
}


extension Array where Element : NSMenuItem {
    
    func filter(commands:[AppCommand.Type], recursive:Bool = false)->[NSMenuItem] {
        let cmdTypes = commands.typeNames
        return filter(conformingToTest: { item in
            if let item = item as? MNMenuItem, let cmd = item.associatedCommand, cmdTypes.contains(cmd.typeName) {
                return true
            }
            
            return false
        }, recursive: true)
    }
}

extension MainMenu /* updtes most important funcs */ {
    
    fileprivate func calcMenuState()->MainMenu.State {
        var newState : MainMenu.State = .disabled
        if BrickDocController.shared.documents.count > 0 && BrickDocController.shared.curDoc != nil {
            newState = .document
            if let curwc = BrickDocController.shared.curDocWC {
                if let sheets = curwc.windowIfLoaded?.sheetTitles, sheets.count > 0 {
                    newState = .documentWithModal(sheets.joined(separator: ", "))
                }
            }
            
        } else if BrickDocController.shared.curDoc == nil &&
            BrickDocController.shared.documents.count == 0 &&
            BricksApplication.shared.isViewControllerExistsOfClass(SplashVC.self) {
                newState = .splashScreen
        }
        return newState
    }
    
    
    /// Update and set the menu item's enabled state. Also returns the determined enabled state (if handled)
    /// - Parameters:
    ///   - item: menu item to update
    ///   - doc: currect document the menu item is relating to
    ///   - docWC: cur document window controller the document is relating to
    /// - Returns: true or false is the menu item was set to enabled or disabled, nil if the menu item was not handled
    @discardableResult
    func updateMenuItem(_ item:NSMenuItem, doc:BrickDoc?, docWC:DocWC?, context:String)->Bool? {
        let docVC = docWC?.docVC
        let hasDoc = doc != nil && docWC != nil
        let hasSelectedLayer = doc?.brick.layers.selectedLayers.count ?? 0 > 0
        var isEnabled = state.isEnabled
        var wasFound = true
        var titleChange : String? = nil
        
        switch item {
        // App / bricks menu
        case bricksAboutMnuItem:       isEnabled = true // Always enabled
        case bricksPreferencesMnuItem: isEnabled = true // Always enabled
        case bricksServicesMnuItem: isEnabled = true // Always enabled
        case bricksServicesSubmenu: isEnabled = true // Always enabled
        case bricksHideMnuItem: isEnabled = true // Always enabled
        case bricksHideOthersMnuItem: isEnabled = true // Always enabled
        case bricksShowAllMnuItem: isEnabled = true // Always enabled
        case bricksQuitMnuItem: isEnabled = true // Always enabled
        
        // File menu
        case fileOpenRecentMnuItem, fileClearRecentsMenuItem: isEnabled = isEnabled && AppDocumentHistory.shared.hasRecents
        case fileRevertToToMnuItem, fileRevertToSavedMnuItem: isEnabled = isEnabled && hasDoc
        case fileCloseMnuItem: isEnabled = isEnabled && hasDoc
        case fileCloseAllMnuItem: isEnabled = isEnabled && BrickDocController.shared.documents.count > 0
        //case fileSaveMnuItem: // Has command
        //case fileSaveAsMnuItem: // Has command
        case fileDuplicateMnuItem: isEnabled = isEnabled && (doc?.hasUnautosavedChanges == true || doc?.isDocumentEdited == true)
        case fileRenameMnuItem: isEnabled = isEnabled && (doc?.fileURL?.lastPathComponent != nil || doc?.brick.info.filePath?.lastPathComponent != nil || doc?.brick.info.displayName != nil)
        case fileMoveToMnuItem:isEnabled = isEnabled && doc?.brick.info.lastSavedDate != nil
        case fileRevertToToMnuItem: isEnabled = isEnabled && doc?.brick.info.lastSavedDate != nil
        case fileRevertToSavedMnuItem: isEnabled = isEnabled && doc?.brick.info.lastSavedDate != nil
        case fileShareMnuItem: return doc?.isDraft == false // ? Allows sharing an empty doc?! && doc?.docSaveState != .emptyAndUnsaved
        // case filePageSetupMnuItem: NSMenuItem!
        // case filePrintMnuItem: NSMenuItem!
            
            // View menu
        case viewTopMnuItem: isEnabled = isEnabled && hasDoc
        case   viewShowToolbarMnuItem: isEnabled = isEnabled && hasDoc
        case   viewCustomizeToolbarMnuItem: isEnabled = isEnabled && hasDoc && false // NOT Customizale
        case   viewShowProjectSidebarMnuItem:
            isEnabled = isEnabled && hasDoc
            titleChange = (docVC?.mnSplitView.isLeadingPanelCollapsed ?? true) ? AppStr.SHOW_PROJECTS_SIDEBAR.localized() : AppStr.HIDE_PROJECTS_SIDEBAR.localized()
            
        case   viewShowUtilitySidebarMnuItem:
            isEnabled = isEnabled && hasDoc
            titleChange = (docVC?.mnSplitView.isTrailingPanelCollapsed ?? true) ? AppStr.SHOW_UTILITY_SIDEBAR.localized() : AppStr.HIDE_UTILITY_SIDEBAR.localized()
            
        case   viewZoomMnuItem:
            isEnabled = isEnabled && hasDoc
            
//        case   viewZoomSubmenu: isEnabled = isEnabled && hasDoc
//        case      viewZoomInMnuItem: isEnabled = isEnabled && hasDoc
//        case      viewZoomTo100MnuItem: isEnabled = isEnabled && hasDoc
//        case      viewZoomOutMnuItem: isEnabled = isEnabled && hasDoc
//        case      viewZoomToFitMnuItem: isEnabled = isEnabled && hasDoc
        case   viewEnterFullScreenMnuItem:
            isEnabled = isEnabled && hasDoc
            titleChange = (docVC?.docWC?.window?.isFullScreen ?? false) ? AppStr.EXIT_FULL_SCREEN.localized() : AppStr.ENTER_FULL_SCREEN.localized()
            
            // Layer menu
        case layerTopMnuItem: isEnabled = isEnabled && hasDoc
        case   layerAddMenuItem:
            isEnabled = isEnabled && hasDoc
        case   layerDeleteMenuItem: isEnabled = isEnabled && hasDoc && hasSelectedLayer
        case   layerEditMenuItem: isEnabled = isEnabled && hasDoc && hasSelectedLayer
        case   layerLockMenuItem: isEnabled = isEnabled && hasDoc && hasSelectedLayer
        case   layerShowHideMenuItem: isEnabled = isEnabled && hasDoc && hasSelectedLayer
        case   layerHideOthersMenuItem:
            // Check if any non-selected layer
            isEnabled = isEnabled && hasDoc && hasSelectedLayer
        case   layerShowAllMenuItem: isEnabled = isEnabled && hasDoc && doc?.brick.layers.count ?? 0 > 0
//
//            // Window menu
//            @IBOutlet weak var windowTopMnuItem: NSMenuItem!
//            @IBOutlet weak var   windowMinimizeMnuitem: NSMenuItem!
//            @IBOutlet weak var   windowZoomMnuItem: NSMenuItem!
//            @IBOutlet weak var   windowBringAllToFrontMnuItem: NSMenuItem!
        
        // Help menu
        case helpTooltipsShowKeyboardShortcutsMnuItem: isEnabled = true // Alqyas enabled
            
        default:
            wasFound = false
            // dlog?.note("UpdateMenuItem - item not implemented:\(item.basicDesc) \(item.title) - \(item.toolTip.descOrNil)")
        }
        
        // Change title if needed
        if let titleChange = titleChange {
            item.title = titleChange
            item.view?.needsDisplay = true
        }
        
        // Change enabled using the associatedCommand or native action for the menu item:
        if isEnabled && wasFound {
            if let item = item as? MNMenuItem, let command = item.associatedCommand, let result = BrickDocController.shared.isAllowed(commandType: command, method: .execute, context: "updateMenuItem").asOptionalBool {
                isEnabled = isEnabled && result
            } else if item.action != nil, let isAllowed = BrickDocController.shared.isAllowedNativeAction(item.action, context: "updateMenuItem") {
                isEnabled = isEnabled && isAllowed
            }
        }
        
        // set enabled state
        item.isEnabled = isEnabled
    
        return wasFound ? item.isEnabled : nil
    }
    
    func updateMenuItems(_ items:[NSMenuItem]? = nil, context:String) {
        
        self.state = calcMenuState()
        
        var itemz : [NSMenuItem] = []
        if items?.count ?? 0 > 0 {
            itemz = items ?? []
            dlog?.info("updateMenuItems \(itemz.count) items. context: \(context)")
        } else {
            dlog?.info("updateMenuItems all items. context: \(context)")
            self.recalcLeafItems()
            itemz = self.allLeafItems
            
            // Submenu item holders that need to be updated as well
            itemz.append(contentsOf: [fileOpenRecentMnuItem, fileClearRecentsMenuItem,
                                      editFindMnuItem, viewZoomMnuItem, fileRevertToToMnuItem ?? fileRevertToSavedMnuItem])
        }
        
        // Get cur doc:
        // let curVC = BrickDocController.shared.curDocVC
        let curWC = BrickDocController.shared.curDocWC
        let curDoc = BrickDocController.shared.curDoc
        for item in itemz {
            self.updateMenuItem(item, doc: curDoc, docWC: curWC, context:context)
        }
    }

}
