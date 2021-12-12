//
//  MainMenu.swift
//  Bricks
//
//  Created by Ido on 08/12/2021.
//

import AppKit

class MainMenu : NSMenu {
    fileprivate let dlog : DSLogger? = DLog.forClass("MainMenu")
    
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
    @IBOutlet weak var   fileSaveMnuItem: NSMenuItem!
    @IBOutlet weak var   fileSaveAsMnuItem: NSMenuItem!
    @IBOutlet weak var   fileRevertToSavedMnuItem: NSMenuItem!
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
    
    var topMnuItems    : [NSMenuItem] = []
    var bricksMnuItems : [NSMenuItem] = []
    var fileMnuItems   : [NSMenuItem] = []
    var editMnuItems   : [NSMenuItem] = []
    var viewMnuItems   : [NSMenuItem] = []
    var windowMnuItems   : [NSMenuItem] = []
    var layerMnuItems   : [NSMenuItem] = []
    var helpMnuItems   : [NSMenuItem] = []
    var allLeafItems    : [NSMenuItem] = []
    
    enum State {
        enum StateSimplified : Int {
            case disabled
            case splashScreen
            case document
            case documentWithModal
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
    }
    
    var state : State = .disabled {
        didSet {
            if state.simplified != oldValue.simplified {
                dlog?.info("state didSet \(state)")
            }

            switch state {
            case .disabled:
                self.disableAll(except: [bricksQuitMnuItem, bricksAboutMnuItem])
                
            case .splashScreen:
                let enabledItems : [NSMenuItem]  = [bricksAboutMnuItem, bricksPreferencesMnuItem, bricksHideMnuItem,
                                                    helpTooltipsShowKeyboardShortcutsMnuItem]
                self.disableAll(except:enabledItems)
            case .document:
                self.disableAll(except: [])
            case .documentWithModal(let string):
                switch string {
                default:
                    self.disableAll(except: [])
                }
            }
        }
    }
    
    func localize(menu:NSMenu, depth:Int = 0) {
        guard depth < 10 else {
            dlog?.warning("localize recursion is > 10 depth. @ menu : \(menu.title)")
            return
        }
        // TODO: Associate AppCommands to all menu items
        for item in menu.items {
            let skip = item.isSeparatorItem
            if !skip {
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
                case   bricksPreferencesMnuItem: title = AppStr.PREFERENCES.localized()
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
                case   fileSaveMnuItem: title = AppStr.SAVE.localized()
                case   fileSaveAsMnuItem: title = AppStr.SAVE_AS_DOT_DOT.localized()
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
                case   viewShowProjectSidebarMnuItem:   title = AppStr.SHOW_PROJECTS_SIDEBAR.localized() //+ AppStr.HIDE_PROJECTS_SIDEBAR.localized()
                case   viewShowUtilitySidebarMnuItem:   title = AppStr.SHOW_UTILITY_SIDEBAR.localized() //+ AppStr.HIDE_UTILITY_SIDEBAR.localized()
                case   viewZoomMnuItem, viewZoomSubmenu:
                          title = AppStr.ZOOM.localized()
                          note = curZoomTitle
                case      viewZoomInMnuItem:    title = AppStr.ZOOM_IN.localized()
                case      viewZoomTo100MnuItem: title = AppStr.ZOOM_TO_100_PRC.localized()
                case      viewZoomOutMnuItem:   title = AppStr.ZOOM_OUT.localized()
                case      viewZoomToFitMnuItem: title = AppStr.ZOOM_TO_FIT.localized()
                case   viewEnterFullScreenMnuItem:  title = AppStr.ENTER_FULL_SCREEN.localized() //+ AppStr.EXIT_FULL_SCREEN.localized()
                    
                case layerTopMnuItem: title = AppStr.LAYER.localized()
                case layerAddMenuItem: title = AppStr.ADD.localized()
                case layerDeleteMenuItem: title = AppStr.DELETE_FORMAT_DOT_DOT.formatLocalized(curLayerName)
                case layerEditMenuItem: title = AppStr.EDIT_FORMAT_DOT_DOT.formatLocalized(curLayerName)
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
                    if title.count == 0 {
                        dlog?.note("Localized title for \"\(item.title)\" is unknown \(type(of: item))")
                    }
                    break
                }

                if let cmd = cmd, let item = item as? MNMenuItem {
                    item.associatedCommand = cmd
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
                    self.localize(menu: submenu, depth: depth + 1)
                }
            }
        }
    }
    
    private static func internal_items(menu:NSMenu,conformingToTest test:(NSMenuItem)->Bool, recursive:Bool = true, depth:Int = 0)->[NSMenuItem] {
        guard depth < 127 else {
            return []
        }
        
        var result : [NSMenuItem] = []
        for item in menu.items {
            if test(item) {
                result.append(item)
            }
            
            if item.hasSubmenu && recursive {
                let subsz = self.internal_items(menu: item.submenu!, conformingToTest: test, recursive: recursive, depth: depth + 1)
                result.append(contentsOf: subsz)
            }
        }
        
        return result
    }
    
    func items(conformingToTest test:(NSMenuItem)->Bool, recursive:Bool = true)->[NSMenuItem] {
        return Self.internal_items(menu:self, conformingToTest: test, recursive: recursive, depth: 0)
    }
    
    func item(withCommand cmd:Command.Type)->NSMenuItem? {
        return self.items { item in
            return (item as? MNMenuItem)?.associatedCommand == cmd
        }.first
    }
    
    func item(withId id:String)->NSMenuItem? {
        return self.items { item in
            item.identifier?.rawValue == id
        }.first
    }
    
    func items(withIdFragments fragments: [String], caseSensitive:Bool = false)->[NSMenuItem] {
        let frags = caseSensitive ? fragments : fragments.compactMap({ str in
            str.lowercased()
        })
        
        return self.items { item in
            if let idr = item.identifier {
                var id = idr.rawValue
                if caseSensitive == false {
                    id = id.lowercased()
                }
                return id.contains(allOf: frags)
            }
            return false
        }
    }
    
    // toggleTrailingSidebarMenuItemID
    
    // MARK: Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        DispatchQueue.main.async {
             AppDelegate.shared.mainMenu = self
        }
        
        topMnuItems = [
            bricksTopMnuItem, fileTopMnuItem, editTopMnuItem, viewTopMnuItem, windowTopMnuItem, helpTopMnuItem]
        
        bricksMnuItems = [bricksAboutMnuItem, bricksPreferencesMnuItem, bricksServicesMnuItem, bricksHideMnuItem, bricksHideOthersMnuItem, bricksShowAllMnuItem, bricksQuitMnuItem
        ]
        fileMnuItems = [
            fileNewMnuItem, fileOpenMnuItem, fileClearRecentsMenuItem, fileCloseMnuItem, fileSaveMnuItem, fileSaveAsMnuItem, fileRevertToSavedMnuItem, filePageSetupMnuItem, filePrintMnuItem
        ]
        editMnuItems = [
            editUndoMnuItem, editRedoMnuItem, editCutMnuItem, editCopyMnuItem, editPasteMnuItem, editDeleteMnuItem, editSelectAllMnuItem, editFindFindMnuItem, editFindNextMnuItem, editFindPreviousMnuItem
        ]
        viewMnuItems = [
            viewShowToolbarMnuItem, viewCustomizeToolbarMnuItem, viewShowProjectSidebarMnuItem, viewShowUtilitySidebarMnuItem, viewZoomMnuItem, viewZoomInMnuItem, viewZoomTo100MnuItem, viewZoomOutMnuItem, viewZoomToFitMnuItem, viewEnterFullScreenMnuItem
        ]
        layerMnuItems = [
            layerAddMenuItem, layerDeleteMenuItem, layerEditMenuItem, layerLockMenuItem, layerShowHideMenuItem, layerHideOthersMenuItem, layerShowAllMenuItem
        ]
        windowMnuItems = [
            windowMinimizeMnuitem, windowZoomMnuItem, windowBringAllToFrontMnuItem,
        ]
        
        helpMnuItems = [
            helpMnuItem, helpTooltipsShowKeyboardShortcutsMnuItem
        ]
        
        DispatchQueue.main.async {
            self.localize(menu: self)
            self.recalcLeafItems()
        }
    }
    
    func recalcLeafItems() {
        
        allLeafItems.removeAll()
        func addLeafItems(_ xitems:[NSMenuItem], depth:Int = 0) {
            guard depth < 127 else {
                return
            }
            
            for item in xitems {
                if item.hasSubmenu == false {
                    allLeafItems.append(item)
                } else {
                    addLeafItems(item.submenu?.items ?? [], depth: depth + 1)
                }
            }
        }
        addLeafItems(topMnuItems, depth: 0)
    }
    
    // MARK: state changes
    func determineState() {
        let hasSplash = BricksApplication.shared.isViewControllerExistsOfClass(SplashVC.self)
        let hasDocument = BrickDocController.shared.documents.count == 0 || BricksApplication.shared.isViewControllerExistsOfClass(DocumentVC.self)
        
        var result : State = .splashScreen
        if hasSplash {
            if hasDocument {
                // Hide splash
                result = .document
            } else {
                result = .splashScreen
            }
        } else if hasDocument {
            result = .document
        } else {
            result = .disabled
        }
        
        // Change state
        self.state = result
    }
    
    private func setEnabled(_ enabled:Bool, items:[NSMenuItem] = [], except:[NSMenuItem]) {
        for item in items {
            var isEnable = (except.contains(item)) ? !enabled : enabled
            if isEnable, let item = item as? MNMenuItem, let cmd = item.associatedCommand {
                isEnable = BrickDocController.shared.isAllowed(commandType: cmd)
            }
            item.isEnabled = isEnable
        }
    }
    
    private func setAllEnabled(_ enabled:Bool, except:[NSMenuItem] = []) {
        self.setEnabled(enabled, items: allLeafItems, except: except)
    }
    
    func disableAll(except:[NSMenuItem] = []) {
        self.setAllEnabled(false, except: except)
    }
    
    func enableAll(except:[NSMenuItem] = []) {
        self.setAllEnabled(true, except: except)
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
