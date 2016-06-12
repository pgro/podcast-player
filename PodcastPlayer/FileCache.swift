//
//  FileCache.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 12.06.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation


class FileCache {
    private let rootKey = "CacheMappings"
    
    
    func filePath(url: String, completion: (filePath: String) -> Void) {
        var entries = loadRootEntry()
        
        if entries[url] == nil {
            storeNewFileName(url)
        }
        
        entries = loadRootEntry()
        let fileName = entries[url]!
        let path = rootFolder() + fileName
        //TODO: check for download in progress
        if fileExists(path) {
            assureBackupExclusion(path)
            completion(filePath: path)
            return
        }
        
        //TODO: improve download handling
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if !self.download(url, path: path) {
                return
            }
            dispatch_async(dispatch_get_main_queue()) {
                completion(filePath: path)
            }
        }
    }
    
    
    private func download(url: String, path: String) -> Bool {
        // create folder if needed
        do {
            let fileManager = NSFileManager.defaultManager()
            try fileManager.createDirectoryAtPath(rootFolder(),
                                                  withIntermediateDirectories: true,
                                                  attributes: nil)
        } catch {
            debugPrint(error)
            return false
        }
        
        // save file locally
        guard let fileData = NSData(contentsOfURL: NSURL(string: url)!) else {
            debugPrint("couldn't download file from url: " + url)
            return false
        }
        let success = fileData.writeToFile(path, atomically: true)
        if !success {
            debugPrint("couldn't write file to: " + path)
            return false
        }
        
        self.excludeFromBackup(path)
        self.assureBackupExclusion(path)
        return true
    }
    
    
    private func storeNewFileName(url: String) {
        var entries = loadRootEntry()
        // create new unique file name
        entries[url] = NSUUID().UUIDString + "." +
            NSURL(string: url)!.pathExtension!
        saveRootEntry(entries)
    }
    
    private func rootFolder() -> String {
        var folderPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        folderPath = folderPath + "/cache/"
        return folderPath
    }
    
    private func fileExists(filePath: String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        return fileManager.fileExistsAtPath(filePath)
    }
    
    
    // MARK: - settings handling
    
    private func loadRootEntry() -> Dictionary<String, String> {
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.valueForKey(rootKey) == nil {
            defaults.setValue(Dictionary<String, String>(), forKey: rootKey)
        }
        
        let entries = defaults.valueForKey(rootKey) as! Dictionary<String, String>
        return entries
    }
    
    private func saveRootEntry(entry: Dictionary<String, String>) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(entry, forKey: rootKey)
    }
    
    
    // MARK: - iCloud backup exclusion
    
    /** Assures that the file (if existing) is excluded from iCloud backup. */
    private func assureBackupExclusion(filePath: String) {
        if !fileExists(filePath) {
            return
        }
        
        do {
            let fileUrl = NSURL(fileURLWithPath: filePath)
            var value: AnyObject?
            try fileUrl.getResourceValue(&value, forKey: NSURLIsExcludedFromBackupKey)
            let isExcluded = value as? NSNumber
            assert(isExcluded != nil && isExcluded!.boolValue,
                   "cached file must be excluded from iCloud backup")
        } catch {
            debugPrint(error)
        }
    }
    
    /** Excludes the (downloaded) file from iCloud backup. */
    private func excludeFromBackup(filePath: String) {
        do {
            let fileUrl = NSURL(fileURLWithPath: filePath)
            try fileUrl.setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey)
        } catch {
            debugPrint(error)
        }
    }
}
