//
//  AppStr.swift
//  grafo
//
//  Created by Ido on 25/10/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("AppStr")

protocol Localizable {
    var key : String {get}
}

#if !CALL_BLOCK_EXTENSION
fileprivate var AppStringsTodo : AppStringsTodoList? = IS_DEBUG ?  AppStringsTodoList() : nil
#endif

enum AppStr : Localizable {
    
    // Common
    case OK    // "OK" // OK button
    case DELETE    // "Delete" // / Delete button
    case CANCEL    // "Cancel" // Cancel button
    case REMOVE    // "Remove" // Remove button
    case ABORT    // "Abort" // Abort button (aborts syncing phone contacts with Facebook)
    
    case TRY_AGAIN    // "Try Again" // Try Again button (tries again to receive some data from the internet)
    case BACK    // "Back" // Back button
    case DONE    // "Done" // Done Button
    case EDIT    // "Edit" // Edit button
    case CLOSE    // "Close" // Close button (closes an alert / window)
    case NEXT    // "Next" // Next button
    case COPY    // "Copy"
    case CONTINUE // "Continue"
    case CONTACTS    // "Contacts" // As for your phone contacts (contact list).
    case SUGGESTIONS    // "Suggestions" // Referes to suggestions of matching Facebook profile for a contact.
    case MORE    // "More" // As for More options, More contacts, More settings etc.
    case SETTINGS    // "Settings" // General application settings.
    case ABOUT    // "About" // About this application / version
    case RESET    // "Reset" // As for reset settings, reset to defaults, etc.
    case SELECT_ALL    // "Select All" // Button - Select all items in a list
    case CLEAR    // "Clear" // Button - Clear selection (the opposite of the Select All button)
    case SETTINGS_ON    // "On" // Indicates that some settings are ON
    case SETTINGS_OFF    // "Off" // Indicates that some settings are OFF
    case REMIND_ME_LATER    // "Remind Me Later" // Button - The user choose he wants us to remind him later something (rate the app, birthday reminder, sync reminder, etc).
    case INVITE    // "Invite" // Button - Invite a friends to use the app.
    case LOGIN    // "Login" // Button - Login
    case LOGOUT    // "Logout" // Button - Logout from your Facebook account
    case GIVEN_NAME    // "Given Name" // User's given (first) name
    case FAMILY_NAME    // "Family Name" // User's family (last) name
    case VERSION    // "Version" // Version
    case TERMS_OF_USE    // "Terms of Use" // Terms of Use (for this app)
    case PRIVACY_POLICY    // "Privacy Policy" // Privacy Policy (for this app)
    case CONNECT    // "Connect" // Button - For example connect to your social network account.
    case LATER    // "Later" // Button title - perform the action later
    case YES    // "yes" // Yes - for settings, example: Is Backup Enabled: Yes
    case NO    // "no" // No - for settings, example: Is Backup Enabled: No
    case OTHER    // "Other" // Button - As for other options the user can choose from.
    case UPDATING    // "Updating" // A view is currently being updated.
    case ACCEPT    // "Accept" // Accept button title (user grants permission for a setting)
    case DECLINE    // "Decline" // Decline button title (user prohibits permission for a setting)
    case UPGRADE    // "Upgrade" // Button or title that calls the user to "upgrade" functionality (purchase of premium) // Android: "upgrade"
    case MY_PROFILE    // "My Profile" // Title: My Profile
    case UNNAMED // "Unnamed" // an unnamed element will have this title / name
    case UNSAVED // "Unsaved" // an un-saved file - was never saved into a file.
    case SAVE
    case SAVE_DOT_DOT
    case SAVE_AS
    case SAVE_AS_DOT_DOT
    case DUPLICATE
    case RENAME_DOT_DOT
    case MOVE_TO_DOT_DOT
    case REVERT_TO_DOT_DOT
    case OPEN
    case UNTITLED // "Untitled" // an untitled (no filename yet) document / element - will display this title
    
    // Progress / loading
    case PLEASE_WAIT    // "Please Wait" // Message displayed to the user while some operation is in progress
    case PLEASE_WAIT_DOT_DOT    // "Please Wait.." // Message displayed to the user while some operation is in progress
    case PLEASE_WAIT_A_MOMENT_DOT_DOT    // "Please wait a moment..." // Tells the user to wait a moment until an opertation is complete
    case LOADING // "Loading"
    case LOADING_DOT_DOT // "Loading.."
    case LOADING_X_DOT_DOT_FORMAT // "Loading X.."
    case PENDING // "Pending"
    case SUCCESS // "Success"
    case FAILED // "Failed"
    case USER_CANCELED // "User canceled"
    
    // Date / time
    case YEAR    // "Year" // Word for one single year
    case MONTH    // "Month" // Word for one single month
    case MONTHS_FORMAT    // "%zd Months" // Word for a few months. Example: "7 Months"
    case DAYS_FORMAT    // "%zd Days" // Word for a few days. Example: "7 Days"
    case LAST_UPDATED_AT_FORMAT    // "Last updated at %@" // Present a last updated date / time for a data field
    case GOT_IT    // "Got it!" // Usually a button title to dismiss a dialog // android
    
    // Errors
    case OOPS_EXCL_POINT // "Oops!"
    case SOMETHING_WENT_WRONG // "Something went wrong"
    case AN_ERROR_HAS_OCCURES // "An Error has occured"
    case ERROR_FORMAT // "Error %@"
    
    // Layers actions
    case LOCK
    case UNLOCK
    case ADD_NEW
    
    // Menu
    // App menu
    case ABOUT_APP_FORMAT
    case PREFERENCES
    case PREFERENCES_DOT_DOT
    case SERVICES
    case HIDE_APP_FORMAT
    case HIDE_OTHERS
    case SHOW_ALL
    case QUIT_APP_FORMAT

    // "File" menu
    case FILE
    case   NEW_PROJECT_DOT_DOT
    case   OPEN_PROJECT_DOT_DOT
    case   OPEN_RECENT
    case   CLEAR_MENU
    case   CLOSE_FORMAT
    case   CLOSE_ALL
    case   REVERT_TO_SAVED_DOT_DOT
    case   PAGE_SETUP_DOT_DOT
    case   PRINT_DOT_DOT
    
    // Edit menu
    case   UNDO_FORMAT
    case   REDO_FORMAT
    case   CUT
    case   PASTE
    case   FIND
    case   FIND_DOT_DOT
    case   FIND_NEXT
    case   FIND_PREVIOUS
    
    // "View" menu
    case VIEW
    case   SHOW_TOOLBAR
    case   HIDE_TOOLBAR
    case   CUSTEMIZE_TOOLBAR_DOT_DOT
    case   SHOW_PROJECTS_SIDEBAR
    case   HIDE_PROJECTS_SIDEBAR
    case   SHOW_UTILITY_SIDEBAR
    case   HIDE_UTILITY_SIDEBAR
    case   ZOOM
    case   ZOOM_IN
    case   ZOOM_TO_100_PRC
    case   ZOOM_OUT
    case   ZOOM_TO_FIT
    case   ENTER_FULL_SCREEN
    case   EXIT_FULL_SCREEN
    
    // "Window" menu
    case WINDOW
    case   MINIMIZE
    case   BRING_ALL_TO_FRONT
    
    // "Help" menu
    case HELP
    case DOCUMENTATION
    case SUPPORT
    case KEY_BINDINGS_APPEAR_IN_TOOLTIPS
    
    // "Layer" menu
    case LAYER
    case ADD
    case DELETE_FORMAT_DOT_DOT
    case EDIT_FORMAT_DOT_DOT
    case SHOW
    case HIDE
    
    // Splash screen
    case PRESENT_SPLASH_SCREEN
    case PRODUCT_NAME // product name
    case START_A_NEW_PROJECT_DOT_DOT
    case OPEN_AN_EXISTING_PROJECT_DOT_DOT
    case COPYRIGHT_COMPANY_W_YEAR_FORMAT // "Copyright © %@ Bricks Biz Ltd." should be year string
    case COPYRIGHT_COMPANY_W_YEAR_FORMAT_LONG // "Copyright © %@ Bricks Biz Ltd. All rights reserved. Logo and other icons are trademarks of Bricks Biz Ltd." should be year string
    case SHOW_THIS_WINDOW_ON_STARTUP // "" for checkboxes
    
    // TOOLBAR
    case PROJECT
    case PROGRESS
    case TASKS
    case PROPERTIES
    case GENERATE
    case GENERATE_TOOLTIP
    case STOP_GENERATION
    case STOP_GENERATION_TOOLTIP
    
    // Tooltips
    case ADD_NEW_PLAN_LAYER_TOOLTIP
    case DELETE_SELECTED_LAYER_FROM_PLAN_TOOLTIP
    case EDIT_SELECTED_LAYER_TOOLTIP
    
    // Preferences
    case GENERAL
    case ACCOUNTS
    case KEY_BINDINGS
    case GENERAL_PREFERENCES_TOOLTIP
    case ACCOUNTS_PREFERENCES_TOOLTIP
    case KEY_BINDINGS_PREFERENCES_TOOLTIP
    
    var key : String {
        return String(describing: self)
    }
    
    static let DEBUG_FIND_UNTRANSLATED = true
    static let DEBUG_LOG_UNTRANSLATED = false
    
    public static func bool( _ condition : Bool, `true` whenTrue: AppStr, `false` whenFalse :AppStr)->AppStr {
        return condition ? whenTrue : whenFalse
    }
    
    public static func localize(_ key : String, tableName: String = "Localizable")->String {
        #if CALL_BLOCK_EXTENSION
            return key
        #else
            var result = NSLocalizedString(key, tableName: tableName, value: key, comment: "")
            if result != "" && result != key {
                if IS_DEBUG && AppStr.DEBUG_FIND_UNTRANSLATED == true {
                    result = "▹\(result)◃"
                }
                
                return result
            }
        
            #if DEBUG
            result = "⚠️\(key)⚠️"
            #endif
        
            return result
        #endif
    }
    
    // Detect if a strng contains formattting patterns
    private static func isFormatStr(string:String, key:String)->Bool {
        
        // Format - convension is that key should contain the word "format" or "fmt"
        if key.contains("FROMAT") ||
            string.contains("FMT"){
            return true
        }
        
        if string.contains("%@") ||
            string.contains("%@") ||
            string.contains("%zd") ||
            string.contains("%ld") ||
            string.contains("%d") ||
            string.contains("%f") ||
            string.contains("%0.2f") ||
            string.contains("%1") ||
            string.contains("%2") ||
            string.contains("%3") ||
            string.contains("%4") {
            return true
        }
        
        return false
    }
    
    fileprivate func getLocalized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        var defaultVal = self.key
        
        #if CALL_BLOCK_EXTENSION
            return key
        #else
            #if DEBUG
            defaultVal = "⚠️\(self.key)⚠️"
            #endif
        
            var result = NSLocalizedString(self.key, tableName: tableName, value: defaultVal, comment: "")
        
            #if DEBUG
            if result == defaultVal {
                _ = AppStringsTodo?.todo(translate: self.key, "")
                if Self.DEBUG_LOG_UNTRANSLATED {
                    dlog?.warning("TODO TRANSLATE NOT Localized. \(self.key) is not localized!")
                }
            } else if result.count == 0 {
                _ = AppStringsTodo?.todo(translate: self.key, "")
                if Self.DEBUG_LOG_UNTRANSLATED {
                    dlog?.warning("TODO TRANSLATE Localized but empty: \(self.key) returns count == 0!")
                }
                result = defaultVal
            } else {
                AppStringsTodo?.seemsTranslated(key)
            }
            #endif
        
            if IS_DEBUG && AppStr.DEBUG_FIND_UNTRANSLATED == true {
                result = "▹\(result)◃"
            }
        
            return result
        #endif
    }
    
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        
        let result = getLocalized(bundle:bundle, tableName:tableName)
        
        #if DEBUG
        if AppStr.isFormatStr(string: result, key: self.key) {
            dlog?.raiseAssertFailure("AppString \(self.key) = \"\(result)\" is a format string used as a regular string!")
        }
        #endif
        
        return result
    }
    
    func formatLocalized(_ args:CVarArg..., bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        var formatString = self.getLocalized(bundle: bundle, tableName: tableName)
        
        #if DEBUG
        if formatString.hasPrefix("▹⚠️") && formatString.hasSuffix("⚠️◃") && formatString.contains("FORMAT") {
            for _ in 0..<args.count {
                formatString = formatString.appending(" %@")
            }
        }
        
        if !AppStr.isFormatStr(string: formatString, key: self.key) {
            dlog?.raiseAssertFailure("AppString \(self.key) = \"\(formatString)\" is NOT a format string used as a format string!")
        }
        #endif
        
        return withVaList(args) {
            NSString(format: formatString, locale: Locale.current, arguments: $0)
            } as String
    }
    
    static func todoList() {
        #if !CALL_BLOCK_EXTENSION
        AppStringsTodo?.todoList()
        #endif
    }
    
    static func clearTodoList() {
        #if !CALL_BLOCK_EXTENSION
        AppStringsTodo?.clearTodoList()
        #endif
    }
}

// Todo:
#if !CALL_BLOCK_EXTENSION
fileprivate class AppStringsTodoList : NSObject { // AppDelegateObserver ?
    
    var cacheTodoTranslete : [String:String] = [:]
    var cacheLock = NSRecursiveLock()
    override init() {
        super.init()
        _ = self.todoLoad()
        // AppDelegate.shared.observers.add(observer: self)
    }
    
    deinit {
        _ = self.todoLoad()
        // AppDelegate.shared.observers.remove(observer: self)
    }
    
    /// Allows to quickly add to the project strings that are not yet translated, but in a syntax very close to the eventual syntax
    ///
    /// - Parameters:
    ///   - key: future key for the localized string
    ///   - value: future value for the localized display string in a single language
    /// - Returns: A display string
    func todo(translate key:String, _ value :String)->String {
        #if DEBUG
        var result : String = value
        cacheLock.lock {
            if let val = cacheTodoTranslete[key] {
                result = val
            }
            
            if (!key.contains("_") && AppStr.DEBUG_LOG_UNTRANSLATED) {
                dlog?.warning("TODO TRANSLATE REQUIRES DOMAIN prefix with underscore for: [\(key)]")
            }
            
            cacheTodoTranslete[key] = value
        }
        return result
        #else
        dlog?.warning("todo(translate: in release mode!")
        return value
        #endif
    }
    
    func seemsTranslated(_ key:String) {
        cacheLock.lock {
            cacheTodoTranslete[key] = nil
        }
    }
    
    /// List all strings that appeared DURING RUNTIME that are not yet translated
    func todoList() {
        
        #if DEBUG
        
        var found : [String] = []
        cacheLock.lock {
            for item in cacheTodoTranslete {
                let defaultVal = "⚠️\(item.key)⚠️"
                let translated = NSLocalizedString(item.key, tableName: "Localizable", bundle: .main, value: "", comment: "")
                if translated != defaultVal && translated.count > 0 && !translated.contains("⚠️") {
                    found.append(item.key)
                }
            }
            
            if found.count > 0 {
                for key in found {
                    self.seemsTranslated(key)
                }
                self.todoSave()
            }
            
            if self.cacheTodoTranslete.count > 0 {
                dlog?.todo("todo list for AppStrings:")
                for item in cacheTodoTranslete {
                    let str = item.value.replacingOccurrences(ofFromTo: ["\n":"\\n",
                                                                         "\"":"\\\""])
                    DLog.info(" \"" + item.key + "\" = \"" + str + "\";")
                }
            }
        }
        #endif
    }
    
    func clearTodoList() {
        cacheLock.lock {
            cacheTodoTranslete.removeAll()
        }
        self.todoSave()
    }
    
    fileprivate typealias StringStringDictionary = [String:String]
    
    @discardableResult
    fileprivate func todoLoad()->Bool {

        // .libraryDirectory -- not accessible to user by Files app
        // .cachesDirectory -- not accessible to user by Files app, for caches and temps
        // .documentDirectory -- accessible to user by Files app
        
        #if DEBUG
        guard var documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return false}
        documentUrl.appendPathComponent("Debug")
        documentUrl.appendPathComponent("todoTranslate.dictionaty")
        if FileManager.default.fileExists(atPath: documentUrl.path) {
            var result = false
            cacheLock.lock {
                do {
                    let data = try Data.init(contentsOf: documentUrl)
                    
                        cacheTodoTranslete = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:String]
                    dlog?.info("DEBUG loaded \(cacheTodoTranslete.count) todo strings")
                    result = true
                }
                catch let error {
                    // does nothing
                    let appErr = AppError(error: error)
                    dlog?.warning("DEBUG \(self) failed loading from ...\(documentUrl.lastPathComponents(count: 2)) error:\(appErr)")
                }
            }
            return result
        }
        #endif
        return false
    }
    
    @discardableResult
    fileprivate func todoSave()->Bool {
        #if DEBUG
        // .libraryDirectory -- not accessible to user by Files app
        // .cachesDirectory -- not accessible to user by Files app, for caches and temps
        // .documentDirectory -- accessible to user by Files app
        guard var documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return false}
        documentUrl.appendPathComponent("Debug")
        var result : Bool = false
        cacheLock.lock {
            do {
                if !FileManager.default.fileExists(atPath: documentUrl.path) {
                    try FileManager.default.createDirectory(atPath: documentUrl.path, withIntermediateDirectories: false, attributes: nil)
                }
                
                documentUrl.appendPathComponent("todoTranslate.dictionaty")
                // NSKeyedArchiver.archiveRootObject(cacheTodoTranslete, toFile: documentUrl.path)
                let data = try JSONSerialization.data(withJSONObject: cacheTodoTranslete, options: JSONSerialization.WritingOptions.sortedKeys)
                try data.write(to: documentUrl)
                
                dlog?.info("DEBUG \(self) saved to ...\(documentUrl.lastPathComponents(count: 2))")
                result = true
            } catch let error {
                let appErr = AppError(error: error)
                dlog?.warning("DEBUG \(self) failed saving to ...\(documentUrl.lastPathComponents(count: 2)) error:\(appErr)")
                result = false
            }
        }
        return result
        #else
        return true
        #endif
    }
    
//    public func applicationDidEnterBackground(_ application: UIApplication) {
//        _ = self.todoSave()
//    }
//
//    public func applicationWillTerminate(_ application: UIApplication) {
//        _ = self.todoSave()
//    }
//
//    public func applicationWillResignActive(_ application: UIApplication) {
//        _ = self.todoSave()
//    }
//
//    public func applicationDidBecomeActive(_ application: UIApplication) {
//        self.todoList()
//    }
}
#endif
