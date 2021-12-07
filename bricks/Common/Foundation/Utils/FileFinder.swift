//
//  FileFinder.swift
//  Bricks
//
//  Created by Ido Rabin on 18/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//
import Foundation
import Cocoa

typealias FileFinderCompletion = (_ foundFiles:[URL]?, _ error: Error?)->Void

class FileFinder {
    
    // MARK: Private
    private class func fileNamePassTest(fileName:URL, extensions:[String]? = nil, prefixes:[String]? = nil, suffixes:[String]? = nil, containing:[String]? = nil)->Bool {
        var result = false
        if !result, let extensions = extensions {
            let fileExtension = fileName.pathExtension
            if extensions.contains(fileExtension) {
                result = true
            }
        }
        
        if !result, let prefixes = prefixes {
            for prefix in prefixes {
                if fileName.lastPathComponent.hasPrefix(prefix) {
                    result = true
                    break
                }
            }
        }
        
        if !result, let suffixes = suffixes {
            for suffix in suffixes {
                if fileName.lastPathComponent.hasSuffix(suffix) {
                    result = true
                    break
                }
            }
        }
        
        if !result, let containing = containing {
            for contain in containing {
                if fileName.lastPathComponent.contains(contain) {
                    result = true
                    break
                }
            }
        }
        
        return result
    }
    
    typealias FileFinderRecord = (path:URL, isFolder:Bool, isPackage:Bool, isHidden:Bool)
    class func listFiles(rootPath:URL, recourseSubfolders:Bool, includeHidden:Bool, includeFolders:Bool) throws ->[FileFinderRecord] {
        let fileManager = FileManager.default
        var resultRecords : [FileFinderRecord] = []
        var resultError : Error? = nil
        
        var keys : [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey]
        if includeHidden {keys.append(URLResourceKey.isHiddenKey)}
        var options : FileManager.DirectoryEnumerationOptions = []
        if !includeFolders {options.update(with:.skipsHiddenFiles)}
        if !recourseSubfolders {options.update(with: .skipsSubdirectoryDescendants)}
        
        let enumerator : FileManager.DirectoryEnumerator? = fileManager.enumerator(at: rootPath.standardizedFileURL, includingPropertiesForKeys: keys, options: options) { (url, error) -> Bool in
            DLog.util.note("[FileFinder] listFiles enumerator error:\(error.localizedDescription) for \(url.absoluteString)")
            resultError = error
            return true
        }
        
        if let error = resultError {
            throw error
        }
        
        var stop = false
        while !stop, let element = enumerator?.nextObject() as? URL {
            
            var add = true
            do {
                let keys = try element.resourceValues(forKeys: [.isHiddenKey, .isSymbolicLinkKey, .isRegularFileKey, .isDirectoryKey, .isPackageKey, .isAliasFileKey])
                if keys.isSymbolicLink ?? false == true ||
                    keys.isAliasFile ?? false == true {
                    // We do not include symbolic links or aliases
                    add = false
                }
                
                if (keys.isDirectory ?? false  && !includeFolders) {
                    add = false
                }
                
                if (keys.isHidden ?? false  && !includeHidden) {
                    add = false
                }
                
                if add {
                    let record = FileFinderRecord(path:element,
                                                  isFolder:keys.isDirectory ?? false,
                                                  isPackage:keys.isPackage ?? false,
                                                  isHidden:keys.isHidden ?? false)
                    resultRecords.append(record)
                }
            } catch let error {
                DLog.util.warning("[FileFinder] enumerator attributesOfItem failed:\(error.localizedDescription) for \(element.absoluteString)")
                stop = true
                throw error
            }
        }
        
        return resultRecords
    }
    
    private class func findFiles(rootPath:URL, extensions:[String]? = nil, prefixes:[String]? = nil, suffixes:[String]? = nil, containing:[String]? = nil, allowHidden:Bool = false, stopOnFirstFound : Bool = false, inThread:Bool = true, completion:@escaping FileFinderCompletion) {
        if inThread {
            DispatchQueue.notMainIfNeeded {
                findFiles(rootPath:rootPath, extensions: extensions, prefixes:prefixes, suffixes:suffixes, containing:containing, allowHidden:allowHidden, stopOnFirstFound:stopOnFirstFound, inThread: false, completion: completion)
            }
            return
        }
        
        let fileManager = FileManager.default
        var resultURLs : [URL] = []
        var resultError : Error? = nil
        
        let options : FileManager.DirectoryEnumerationOptions = allowHidden ? [] : FileManager.DirectoryEnumerationOptions.skipsHiddenFiles
        
        //let includeSubFolders = true
        // The enumerated recurses into sub folders and their sub folders as well.
        let enumerator = fileManager.enumerator(at: rootPath.standardizedFileURL,
                                                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                                                options: options) { (url, error) -> Bool in
                                                    DLog.util.note("[FileFinder] findFiles enumerator error:\(error.localizedDescription) for \(url.absoluteString)")
            resultError = error
            return true // Error handled
        }
        //}
        
        var stop = false
        while !stop, let element = enumerator?.nextObject() as? URL {
            
            //var isDirectory: ObjCBool = false
            //fileManager.fileExists(atPath: element.path, isDirectory: &isDirectory)
            //if isDirectory.boolValue {
                //DLog.util.info("subfolder \(element.absoluteString)")
            //}
            //else
            //{
                // DLog.util.info("file \(element.absoluteString)")
                if self.fileNamePassTest(fileName: element, extensions: extensions, prefixes: prefixes, suffixes: suffixes, containing: containing) {
                    resultURLs.append(element)
                    if stopOnFirstFound {
                        stop = true
                    }
                }
            //}
        }
        
        completion(resultURLs, resultError)
    }
    
    // MARK: Public
    class func findFiles(rootPath:URL, extensions:[String], allowHidden:Bool = false, stopOnFirstFound : Bool = false, inThread:Bool = true, completion:@escaping FileFinderCompletion) {
        self.findFiles(rootPath: rootPath, extensions: extensions, prefixes:nil, suffixes:nil, containing:nil, allowHidden:allowHidden, stopOnFirstFound: stopOnFirstFound, inThread: inThread, completion: completion)
    }
    
    class func findFiles(rootPath:URL, prefixes:[String], allowHidden:Bool = false, stopOnFirstFound : Bool = false, inThread:Bool = true, completion:@escaping FileFinderCompletion) {
        self.findFiles(rootPath: rootPath, extensions:nil, prefixes:prefixes, suffixes:nil, containing:nil, allowHidden:allowHidden, stopOnFirstFound: stopOnFirstFound, inThread: inThread, completion: completion)
    }
    
    class func findFiles(rootPath:URL, suffixes:[String], allowHidden:Bool = false, stopOnFirstFound : Bool = false, inThread:Bool = true, completion:@escaping FileFinderCompletion) {
        self.findFiles(rootPath: rootPath, extensions:nil, prefixes:nil, suffixes:suffixes, containing:nil, allowHidden:allowHidden, stopOnFirstFound: stopOnFirstFound, inThread: inThread, completion: completion)
    }
    
    class func findFiles(rootPath:URL, containing:[String], allowHidden:Bool = false, stopOnFirstFound : Bool = false, inThread:Bool = true, completion:@escaping FileFinderCompletion) {
        self.findFiles(rootPath: rootPath, extensions:nil, prefixes:nil, suffixes:nil, containing:containing, allowHidden:allowHidden, stopOnFirstFound: stopOnFirstFound, inThread: inThread, completion: completion)
    }
}
