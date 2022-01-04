//
//  BrickDocController+Menu.swift
//  Bricks
//
//  Created by Ido on 04/01/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDocController+Menu")

extension BrickDocController /* main menu */ {
    // MARK: Private funcs
    func determineNewMenuState()->MainMenu.State {
        var result : MainMenu.State = .disabled
//        let hasSplash = BricksApplication.shared.isViewControllerExistsOfClass(SplashVC.self)
//        let hasDocument = BrickDocController.shared.documents.count == 0 || BricksApplication.shared.isViewControllerExistsOfClass(DocVC.self)
//
//        var result : State = .splashScreen
//        if hasSplash {
//            if hasDocument {
//                // Hide splash
//                result = .document
//            } else {
//                result = .splashScreen
//            }
//        } else if hasDocument {
//            result = .document
//        } else {
//            result = .disabled
//        }
        return result
    }
    
    // MARK: Public Menu-related funcs
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // dlog?.info("validateMenuItem \(menuItem)")
        if let menuItem = menuItem as? MNMenuItem, let cmd = menuItem.associatedCommand {
            return self.isAllowed(commandType: cmd, context: "validateMenuItem(noDoc))")
        } else if menuItem.title.count > 0 && menuItem.action != nil {
            if let res = self.isAllowedNativeAction(menuItem.action, context: "validateMenuItem(noDoc)") {
                return res
            }
        }
        return super.validateMenuItem(menuItem)
    }
    
    func invalidateMenu(context:String) {
        TimedEventFilter.shared.filterEvent(key: "invalidateMenu", threshold: 0.06, accumulating: context) { contexts in
            if let menu = self.menu {
                //dlog?.info("invalidateMenu \(menu.basicDesc) contexts: \(contexts?.descriptionsJoined ?? "<nil>" )")
                
                // Set new menu state if needed
                let newState = self.determineNewMenuState()
                if menu.state.simplified != newState.simplified {
                    dlog?.info("new menu state:\(newState)")
//                    menu.state = newState
//
//                    // Calc all menu items using the state:
//                    menu.recalcLeafItems()
//
//                    switch newState {
//                    case .disabled:
//                        let except = [menu.bricksMnuItems,
//                                      [menu.fileNewMnuItem], [menu.fileOpenMnuItem],
//                                      menu.helpMnuItems].compactMap( { $0 } )
//                        menu.setAllEnabled(false, except: except)
//                    default:
//                        break
//                    }
//
//                    for menuItem in menu.allLeafItems {
//
////                        if let doc = self.curDoc {
////                            menuItem.isEnabled = self.validateMenuItem(doc: doc, menuItem: menuItem)
////                        } else {
////                            menuItem.isEnabled = self.validateMenuItem(menuItem)
////                        }
//                    }
//
//                    if let wc = self.curDocWC {
//                        wc.updateToolbarVisible()
//                    } else {
//
//                    }
                }
            }
        }
    }
    
    
}
