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
    @IBOutlet weak var   bricksServicesSubmenu: NSMenu!
    @IBOutlet weak var   bricksHideMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksHideOthersMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksShowAllMnuItem: NSMenuItem!
    @IBOutlet weak var   bricksQuitMnuItem: NSMenuItem!
    
    // File menu
    @IBOutlet weak var fileTopMnuItem: NSMenuItem!
    @IBOutlet weak var   fileNewMnuItem: NSMenuItem!
    @IBOutlet weak var   fileOpenMnuItem: NSMenuItem!
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
    @IBOutlet weak var   editFindSubmenu: NSMenu!
    @IBOutlet weak var     editFindFindMnuItem: NSMenuItem!
    @IBOutlet weak var     editFindNextMnuItem: NSMenuItem!
    @IBOutlet weak var     editFindPreviousMnuItem: NSMenuItem!
    
    // View menu
    @IBOutlet weak var viewTopMenuItem: NSMenuItem!
    @IBOutlet weak var   viewShowToolbarMnuItem: NSMenuItem!
    @IBOutlet weak var   viewCustomizeToolbarMnuItem: NSMenuItem!
    @IBOutlet weak var   viewShowProjectSidebarMnuItem: NSMenuItem!
    @IBOutlet weak var   viewShowUtilitySidebarMnuItem: NSMenuItem!
    @IBOutlet weak var   viewZoomSubmenu: NSMenu!
    @IBOutlet weak var      viewZoomInMnuItem: NSMenuItem!
    @IBOutlet weak var      viewZoomTo100MnuItem: NSMenuItem!
    @IBOutlet weak var      viewZoomOutMnuItem: NSMenuItem!
    @IBOutlet weak var      viewZoomToFitMnuItem: NSMenuItem!
    @IBOutlet weak var   viewEnterFullScreenMnuItem: NSMenuItem!
    
    // Layer menu
    @IBOutlet weak var layerTopMenuItem: NSMenuItem!
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
    @IBOutlet weak var helpTopMenuItem: NSMenuItem!
    @IBOutlet weak var   helpMenuItem: NSMenuItem!
    
    var topMnuItems    : [NSMenuItem] = []
    var bricksMnuItems : [NSMenuItem] = []
    var fileMnuItems   : [NSMenuItem] = []
    var editMnuItems   : [NSMenuItem] = []
    var viewMnuItems   : [NSMenuItem] = []
    var windowMnuItems   : [NSMenuItem] = []
    var layerMnuItems   : [NSMenuItem] = []
    var helpMnuItems   : [NSMenuItem] = []
    
    enum State {
        case splashScreen
        case project
        case projectModal(String)
        case appPreferences
    }
    
    var state : State = .projectModal("disableAll") {
        didSet {
            dlog?.info("state didSet \(state)")
            switch state {
            case .splashScreen:
                self.disableAll(except: [bricksTopMnuItem, fileTopMnuItem, helpTopMenuItem, layerTopMenuItem])
            case .project:
                self.disableAll(except: [])
            case .projectModal(let string):
                switch string {
                default:
                    self.disableAll(except: [])
                }
            case .appPreferences:
                self.disableAll(except: [])
            }
        }
    }
    
    func localize() {
        for item in topMnuItems {
            var title = "❌Unknown❌"
            switch item {
            case bricksTopMnuItem: title = AppStr.BRICKS.localized()
            case fileTopMnuItem: title = AppStr.FILE.localized()
            case editTopMnuItem: title = AppStr.EDIT.localized()
            case viewTopMenuItem: title = AppStr.VIEW.localized()
            case windowTopMnuItem: title = AppStr.WINDOW.localized()
            case helpTopMenuItem: title = AppStr.HELP.localized()
            default:
                break
            }
            
            dlog?.info("setting title: \(title)")
            item.title = title
            if item.hasSubmenu {
                item.submenu?.title = title
            }
        }
    }
    
    // MARK: Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        AppDelegate.shared.mainMenu = self
        
        topMnuItems = [bricksTopMnuItem, fileTopMnuItem, editTopMnuItem, viewTopMenuItem, windowTopMnuItem, helpTopMenuItem]
        bricksMnuItems = [bricksAboutMnuItem, bricksPreferencesMnuItem, bricksHideMnuItem, bricksHideOthersMnuItem, bricksShowAllMnuItem, bricksQuitMnuItem
        ]
        fileMnuItems = [fileTopMnuItem, fileNewMnuItem, fileOpenMnuItemfileClearRecentsMenuItem
        ]
        editMnuItems = [
        ]
        viewMnuItems = [
        ]
        windowMnuItems = [
        ]
        layerMnuItems = [
        ]
        helpMnuItems = [
        ]
        
        DispatchQueue.main.async {
            self.localize()
        }
    }
    
    // MARK: state changes
    func determineState() {
        let windowCount = NSApplication.shared.windows.count
        let topVC = NSApplication.shared.orderedWindows.first?.contentViewController
        dlog?.info("determineState windows:\(windowCount) topVC:\(topVC.self.descOrNil)")
        switch (windowCount, topVC) {
        case (1, is SplashVC):
            self.state = .splashScreen
        default:
            dlog?.info("unknown state")
            self.state = .projectModal("disableAll")
        }
    }
    
    private func setEnabled(_ enabled:Bool, items:[NSMenuItem] = [], except:[NSMenuItem]) {
        for item in items {
            if !except.contains(item) {
                item.isEnabled = enabled
            }
        }
    }
    
    private func setAllEnabled(_ enabled:Bool, except:[NSMenuItem] = []) {
        self.setEnabled(enabled, items: topMnuItems, except: except)
    }
    
    func disableAll(except:[NSMenuItem] = []) {
        self.setAllEnabled(false, except: except)
    }
    
    func enableAll(except:[NSMenuItem] = []) {
        self.setAllEnabled(true, except: except)
    }
}
