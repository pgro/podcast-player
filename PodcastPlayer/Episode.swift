//
//  Episode.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation


enum Status {
    case NeedsDownload
    case IsDownloading
    case FinishedDownload
}

class Episode {
    var title = ""
    var description = ""
    var url = "" {
        didSet {
            prepareFileName()
            status = prepareEpisodeFilePath().status == PathStatus.Exists
                                                ? Status.FinishedDownload
                                                : Status.NeedsDownload
        }
    }
    var date = ""
    var fileName = ""
    var status = Status.NeedsDownload
    
    
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
        if status == Status.IsDownloading {
            // download is already in progress -> nothing to do
            return
        }
        
        /* download selected podcast episode (if necessary)
         * and update the cell status accordingly */
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let result = self.prepareEpisodeFilePath()
            if result.status == PathStatus.Exists {
                self.status = Status.FinishedDownload
                return
            }
            if result.status == PathStatus.Error {
                self.status = Status.NeedsDownload
                return
            }
            
            self.status = Status.IsDownloading
            let episodeFileData = NSData(contentsOfURL: NSURL(string: self.url)!)
            // TODO: avoid iCloud backup
            let success = episodeFileData?.writeToFile(result.path!, atomically: true)
            self.status = (success != nil) ? Status.FinishedDownload
                                           : Status.NeedsDownload
        }
    }
    

    // MARK: - episode file path handling
    
    func folderPathForEpisodes() -> String {
        var folderPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        folderPath = folderPath.stringByAppendingString("/episodes")
        return folderPath
    }
    
    
    enum PathStatus {
        case Error
        case Exists
        case IsFree
    }
    
    /** Returns the target path for download when it is available
     or nil if it was already downloaded (i.e. file exists)
     or if an error occured. */
    func prepareEpisodeFilePath() -> (status: PathStatus, path: String?) {
        let folderPath = folderPathForEpisodes()
        let path = folderPath.stringByAppendingString("/" + fileName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            return (PathStatus.Exists, nil)
        }
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            debugPrint(error)
            return (PathStatus.Error, nil)
        }
        
        return (PathStatus.IsFree, path)
    }

}
