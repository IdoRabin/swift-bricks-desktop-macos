//
//  AppSandboxer.swift
//  Bricks
//
//  Created by Ido Rabin on 21/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation
import Cocoa

class AppSandboxer {
    
    static private var bookmarks = [URL: Data]()
    
    class func bookmarkPath() -> String
    {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var url = URL(fileURLWithPath: path)

        url = url.appendingPathComponent("Bookmarks.dict")
        return url.path
    }
    
    class func loadBookmarks()
    {
        let path = bookmarkPath()
        let url = NSURL(fileURLWithPath: path)
        
        do {
            let data = try Data(contentsOf: url as URL)
            if let bookmarks = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSURL.self, NSData.self], from: data) as? [URL:Data] {
                for bookmark in bookmarks
                {
                    restoreBookmark(bookmark)
                }
            } else {
                DLog.util["AppSandboxer"]?.warning("Bookmarks file not found!")
            }
        } catch let error {
            let appErr = AppError(error: error)
            DLog.util["AppSandboxer"]?.warning("loadBookmarks failed loading data from filer at: \(path). Error:\(appErr)")
        }
    }
    
    class func saveBookmarks()
    {
        let path = bookmarkPath()
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: bookmarks, requiringSecureCoding: true)
            try data.write(to: URL(fileURLWithPath: path))
        } catch let error {
            let appErr = AppError(error: error)
            DLog.util["AppSandboxer"]?.warning("Bookmarks failed creating data or saving to \(path) error: \(appErr)")
        }
    }
    
    class func storeBookmark(url: URL)
    {
        do
        {
            let data = try url.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            bookmarks[url] = data
        }
        catch
        {
            DLog.util["AppSandboxing"]?.warning("Error storing bookmarks")
        }
        
    }
    
    class func restoreBookmark(_ bookmark: (key: URL, value: Data))
    {
        let restoredUrl: URL?
        var isStale = false
        
        DLog.util["AppSandboxing"]?.info("Restoring \(bookmark.key)")
        do
        {
            restoredUrl = try URL.init(resolvingBookmarkData: bookmark.value, options: NSURL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        }
        catch
        {
            DLog.util["AppSandboxing"]?.warning("Error restoring bookmarks")
            restoredUrl = nil
        }
        
        if let url = restoredUrl
        {
            if isStale
            {
                DLog.util["AppSandboxing"]?.note("URL is stale \(url.absoluteString)")
            }
            else
            {
                if !url.startAccessingSecurityScopedResource()
                {
                    DLog.util["AppSandboxing"]?.warning("Couldn't access: \(url.path)")
                }
                else
                {
                    AppSandboxer.bookmarks[bookmark.key] = bookmark.value
                }
            }
        }
    }
    
    func allowFolder() -> URL?
    {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.begin
            { (result) -> Void in
                if result == NSApplication.ModalResponse.OK
                {
                    let url = openPanel.url
                    AppSandboxer.storeBookmark(url: url!)
                }
        }
        return openPanel.url
    }
}
