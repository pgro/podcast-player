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
    
    
    func filePath(_ url: String, completion: @escaping (_ filePath: String) -> Void) {
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
            completion(path)
            return
        }
        
        //TODO: improve download handling
        DispatchQueue.global().async {
            if !self.download(url, path: path) {
                return
            }
            DispatchQueue.main.async {
                completion(path)
            }
        }
    }
    
    
    private func download(_ url: String, path: String) -> Bool {
        // create folder if needed
        do {
            let fileManager = FileManager.default
            try fileManager.createDirectory(atPath: rootFolder(),
                                                  withIntermediateDirectories: true,
                                                  attributes: nil)
        } catch {
            debugPrint(error)
            return false
        }
        
        // save file locally
        guard let fileData = try? Data(contentsOf: URL(string: url)!) else {
            debugPrint("couldn't download file from url: " + url)
            return false
        }
        let success = (try? fileData.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil
        if !success {
            debugPrint("couldn't write file to: " + path)
            return false
        }
        
        self.excludeFromBackup(path)
        self.assureBackupExclusion(path)
        return true
    }
    
    
    private func storeNewFileName(_ url: String) {
        var entries = loadRootEntry()
        // create new unique file name
        entries[url] = UUID().uuidString + "." +
            URL(string: url)!.pathExtension
        saveRootEntry(entries)
    }
    
    private func rootFolder() -> String {
        var folderPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        folderPath = folderPath + "/cache/"
        return folderPath
    }
    
    private func fileExists(_ filePath: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath)
    }
    
    
    // MARK: - settings handling
    
    private func loadRootEntry() -> Dictionary<String, String> {
        let defaults = UserDefaults.standard
        if defaults.value(forKey: rootKey) == nil {
            defaults.setValue(Dictionary<String, String>(), forKey: rootKey)
        }
        
        let entries = defaults.value(forKey: rootKey) as! Dictionary<String, String>
        return entries
    }
    
    private func saveRootEntry(_ entry: Dictionary<String, String>) {
        let defaults = UserDefaults.standard
        defaults.setValue(entry, forKey: rootKey)
    }
    
    
    // MARK: - iCloud backup exclusion
    
    /** Assures that the file (if existing) is excluded from iCloud backup. */
    private func assureBackupExclusion(_ filePath: String) {
        if !fileExists(filePath) {
            return
        }
        
        do {
            let fileUrl = URL(fileURLWithPath: filePath)
            var value: AnyObject?
            try (fileUrl as NSURL).getResourceValue(&value, forKey: .isExcludedFromBackupKey)
            let isExcluded = value as? NSNumber
            assert(isExcluded != nil && isExcluded!.boolValue,
                   "cached file must be excluded from iCloud backup")
        } catch {
            debugPrint(error)
        }
    }
    
    /** Excludes the (downloaded) file from iCloud backup. */
    private func excludeFromBackup(_ filePath: String) {
        do {
            let fileUrl = URL(fileURLWithPath: filePath)
            try (fileUrl as NSURL).setResourceValue(NSNumber(value: true), forKey: .isExcludedFromBackupKey)
        } catch {
            debugPrint(error)
        }
    }
}
