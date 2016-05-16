//
//  Episode.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation


enum DownloadStatus {
    case NotStarted
    case InProgress
    case Finished
}

protocol EpisodeDelegate: class {
    func episode(episode: Episode, didChangeStatus status: DownloadStatus)
}

class Episode {
    var title = ""
    var description = ""
    var url = "" {
        didSet {
            settings = SettingsManager(episodeUrl: url)
            fileName = settings!.loadFileName()
            prepareFilePath()
            status = fileExists() ? DownloadStatus.Finished
                                  : DownloadStatus.NotStarted
            isRemoved = settings!.loadIsRemoved()
        }
    }
    var date = ""
    var duration = ""
    var fileName = ""
    var filePath = ""
    var status = DownloadStatus.NotStarted {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.episode(self, didChangeStatus: self.status)
            }
        }
    }
    weak var delegate: EpisodeDelegate?
    var settings: SettingsManager?
    var isRemoved = false {
        didSet {
            settings?.saveIsRemoved(isRemoved)
        }
    }


// MARK: - actions with file
    
    func download() {
        if status == DownloadStatus.InProgress {
            // download is already in progress -> nothing to do
            return
        }
        
        /* download selected podcast episode (if necessary)
         * and update the cell status accordingly */
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if self.fileExists() {
                self.status = DownloadStatus.Finished
                return
            }
            
            self.isRemoved = false
            self.status = DownloadStatus.InProgress
            guard let episodeFileData = NSData(contentsOfURL: NSURL(string: self.url)!) else {
                self.status = DownloadStatus.NotStarted
                return
            }
            let success = episodeFileData.writeToFile(self.filePath, atomically: true)
            self.status = success ? DownloadStatus.Finished
                                  : DownloadStatus.NotStarted
            if success {
                self.excludeFromBackup()
            }
        }
    }
    
    func delete() {
        if status != .Finished {
            // file not available -> nothing to do
            return
        }
        
        assert(fileExists(), "file must exist")
        do {
            try NSFileManager.defaultManager().removeItemAtPath(filePath)
            status = .NotStarted
            isRemoved = true
        } catch {
            debugPrint(error)
        }
    }


// MARK: - file path handling
    
    func folderPathForEpisodes() -> String {
        var folderPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        folderPath = folderPath.stringByAppendingString("/episodes")
        return folderPath
    }
    
    func fileExists() -> Bool {
        let fileManager = NSFileManager.defaultManager()
        return fileManager.fileExistsAtPath(filePath)
    }
    
    func prepareFilePath() {
        let folderPath = folderPathForEpisodes()
        filePath = folderPath.stringByAppendingString("/" + fileName)
        
        assureBackupExclusion()
        
        // create folder if needed
        do {
            let fileManager = NSFileManager.defaultManager()
            try fileManager.createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            debugPrint(error)
        }
    }


// MARK: - iCloud backup exclusion

    /** Assures that the episode file (if existing) is excluded from iCloud backup. */
    func assureBackupExclusion() {
        if !fileExists() {
            return
        }
        
        do {
            let fileUrl = NSURL(fileURLWithPath: filePath)
            var value: AnyObject?
            try fileUrl.getResourceValue(&value, forKey: NSURLIsExcludedFromBackupKey)
            let isExcluded = value as? NSNumber
            assert(isExcluded != nil && isExcluded!.boolValue,
                   "downloaded podcast episode must be excluded from iCloud backup")
        } catch {
            debugPrint(error)
        }
    }
    
    /** Excludes the (downloaded) file from iCloud backup. */
    func excludeFromBackup() {
        do {
            let fileUrl = NSURL(fileURLWithPath: self.filePath)
            try fileUrl.setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey)
        } catch {
            debugPrint(error)
        }
    }
}
