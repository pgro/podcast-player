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
        guard let fileName = entries[url] else {
            //TODO: error handling
            return
        }
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
    
    
    private func download(_ urlString: String, path: String) -> Bool {
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
        guard let url = URL(string: urlString),
            let fileData = try? Data(contentsOf: url) else {
            debugPrint("couldn't download file from url: " + urlString)
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
            (URL(string: url)?.pathExtension ?? "mp3")
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
        guard let entries = defaults.value(forKey: rootKey) as? Dictionary<String, String> else {
            let emptyRoot = Dictionary<String, String>()
            defaults.setValue(emptyRoot, forKey: rootKey)
            return emptyRoot
        }
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
            assert(isExcluded(value),
                   "cached file must be excluded from iCloud backup")
        } catch {
            debugPrint(error)
        }
    }
    
    private func isExcluded(_ settingsValue: AnyObject?) -> Bool {
        guard let isExcluded = settingsValue as? NSNumber else { return false }
        return isExcluded.boolValue
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
