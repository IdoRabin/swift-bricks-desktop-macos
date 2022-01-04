//
//  DocWC+TabGroups.swift
//  Bricks
//
//  Created by Ido on 04/01/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocWC+Tabs")

extension DocWC /* + TabGroups */ {
    
    // MARK: Properites
    var tabGroupIdentifier : NSWindow.TabbingIdentifier? {
        return self.window?.tabGroup?.identifier.components(separatedBy: ".").last
    }
    
    var tabGroupSelectedWindow : NSWindow? {
        self.window?.tabGroup?.selectedWindow
    }
    
    // MARK: Private
    private static func internal_updateSelectedInTabGroups(wcs:[DocWC]) {
        var result : [NSWindow.TabbingIdentifier:(BrickDocUID , String)] = Self.appTabGroupSelections
        var didFindMainWindow = false
        for wc in wcs {
            if let selectedWC = wc.tabGroupSelectedWindow?.windowController as? DocWC, let selectedDoc = selectedWC.document as? BrickDoc {
                let docTuple : (BrickDocUID , String) = (selectedDoc.id, selectedDoc.displayName)
                result[selectedWC.tabGroupIdentifier!] = docTuple
                
                // Change currently selected doc:
                if selectedWC.window?.isMainWindow ?? false {
                    BrickDocController.shared.curDocWC = selectedWC
                    didFindMainWindow = true
                }
            }
        }
        if !didFindMainWindow {
            BrickDocController.shared.curDocWC = nil
        }
        
        Self.appTabGroupSelections = result
        //dlog?.info("updateSelectedInTabGroups selections: \(result)")
    }
    
    private static func internal_updateTabGroups(wcs:[DocWC]) {
        var result : [NSWindow.TabbingIdentifier:[BrickDocUID : String]] = Self.appTabGroups
        for wc in wcs {
            if let tabId = wc.tabGroupIdentifier, let doc = wc.document as? BrickDoc {
                var docsByIds : [BrickDocUID : String] = result[tabId] ?? [:]
                docsByIds[doc.id] = doc.displayName
                result[tabId] = docsByIds
            }
        }
        Self.appTabGroups = result
        //dlog?.info("DidChangeTabGroup new TabGroups: \(result)")
    }
    
    // MARK: Public
    
    static func updateSelectedInTabGroups() {
        DispatchQueue.mainIfNeeded {
            //dlog?.info("updateSelectedInTabGroups")
            internal_updateSelectedInTabGroups(wcs: BricksApplication.shared.findPresentedWCsOfType(DocWC.self))
        }
    }
    
    static func updateTabGroups() {
        DispatchQueue.mainIfNeeded {
            //dlog?.info("updateTabGroups")
            internal_updateTabGroups(wcs: BricksApplication.shared.findPresentedWCsOfType(DocWC.self))
        }
    }
    
    func setupTabGroupObserving() {
        // selectedWindow
        self._selectedTabObservation = window?.observe(\.tabGroup?.selectedWindow, options: []) { window, change in
            if let wc = window.windowController as? DocWC {
                // accessing tabGroup can change tabGroup and cause recursion, schedule on runloop
                TimedEventFilter.shared.filterEvent(key: "DocWC.DicChangeSelectedTab", threshold: 0.05, accumulating: wc) { wcs in
                    Self.internal_updateSelectedInTabGroups(wcs: wcs ?? [])
                }
            }
        }
        
        // Tab group
        self._tabObservation = window?.observe(\.tabGroup, options: []) { window, change in
            if let wc = window.windowController as? DocWC {
                // accessing tabGroup can change tabGroup and cause recursion, schedule on runloop
                 // dlog?.info("DidChangeTabGroup object:\(window) change:\(change)")
                TimedEventFilter.shared.filterEvent(key: "DocWC.DidChangeTabGroup", threshold: 0.05, accumulating: wc) { wcs in
                    Self.internal_updateTabGroups(wcs: wcs ?? [])
                }
            }
        }
    }
}
