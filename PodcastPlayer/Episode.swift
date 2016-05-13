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
            prepareFileName()
            prepareFilePath()
            status = fileExists() ? DownloadStatus.Finished
                                  : DownloadStatus.NotStarted
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
    
    
    /** Retrieves the unique file name for the current url from user defaults.
        Creates that in case of a previously unknown episode url. */
    func prepareFileName() {
        if url.isEmpty {
            return
        }
        
        let episodesToFilesMappingKey = "episodesAndTheirFiles"
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.valueForKey(episodesToFilesMappingKey) == nil {
            defaults.setValue(Dictionary<String, String>(), forKey: episodesToFilesMappingKey)
        }
        var episodesToFiles = defaults.valueForKey(episodesToFilesMappingKey) as! Dictionary<String, String>
        
        if episodesToFiles[url] == nil {
            episodesToFiles[url] = NSUUID().UUIDString + "." + (NSURL(string: url)?.pathExtension)!
            defaults.setValue(episodesToFiles, forKey: episodesToFilesMappingKey)
        }
        fileName = episodesToFiles[url]!
    }
    
    
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
            
            self.status = DownloadStatus.InProgress
            guard let episodeFileData = NSData(contentsOfURL: NSURL(string: self.url)!) else {
                self.status = DownloadStatus.NotStarted
                return
            }
            let success = episodeFileData.writeToFile(self.filePath, atomically: true)
            self.status = success ? DownloadStatus.Finished
                                  : DownloadStatus.NotStarted
            if success {
                // exclude downloaded file from iCloud backup
                do {
                    let fileUrl = NSURL(fileURLWithPath: self.filePath)
                    try fileUrl.setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey)
                } catch {
                    debugPrint(error)
                }
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
        } catch {
            debugPrint(error)
        }
    }

    
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
        
        if fileExists() {
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
            
            return
        }
        
        // create folder if needed
        do {
            let fileManager = NSFileManager.defaultManager()
            try fileManager.createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            debugPrint(error)
        }
    }

}
