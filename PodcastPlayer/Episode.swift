//
//  Episode.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation


enum DownloadStatus {
    case notStarted
    case inProgress
    case finished
}

protocol EpisodeDelegate: class {
    func episode(_ episode: Episode, didChangeStatus status: DownloadStatus)
    func episode(_ episode: Episode, didChangeIsRemoved isRemoved: Bool)
}

class Episode {
    var author = ""
    var title = ""
    var description = ""
    var url = "" {
        didSet {
            settings = SettingsManager(episodeUrl: url)
            guard let settings = self.settings else { return }
            fileName = settings.loadFileName()
            prepareFilePath()
            status = fileExists() ? DownloadStatus.finished
                                  : DownloadStatus.notStarted
            isRemoved = settings.loadIsRemoved()
        }
    }
    var date = ""
    var duration = ""
    var fileName = ""
    var filePath = ""
    var status = DownloadStatus.notStarted {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.episode(self, didChangeStatus: self.status)
            }
        }
    }
    weak var delegate: EpisodeDelegate?
    var settings: SettingsManager?
    var isRemoved = false {
        didSet {
            settings?.saveIsRemoved(isRemoved)
            DispatchQueue.main.async {
                self.delegate?.episode(self, didChangeIsRemoved: self.isRemoved)
            }
        }
    }


// MARK: - actions with file
    
    func download() {
        if status == DownloadStatus.inProgress {
            // download is already in progress -> nothing to do
            return
        }
        
        /* download selected podcast episode (if necessary)
         * and update the cell status accordingly */
        DispatchQueue.global().async {
            if self.fileExists() {
                self.status = DownloadStatus.finished
                return
            }
            
            self.isRemoved = false
            self.status = DownloadStatus.inProgress
            guard let url = URL(string: self.url),
                let episodeFileData = try? Data(contentsOf: url) else {
                self.status = DownloadStatus.notStarted
                return
            }
            let success = (try? episodeFileData.write(to: URL(fileURLWithPath: self.filePath), options: [.atomic])) != nil
            self.status = success ? DownloadStatus.finished
                                  : DownloadStatus.notStarted
            if success {
                self.excludeFromBackup()
            }
        }
    }
    
    func delete() {
        if status != .finished {
            isRemoved = true
            return
        }
        
        assert(fileExists(), "file must exist")
        do {
            try FileManager.default.removeItem(atPath: filePath)
            status = .notStarted
            isRemoved = true
        } catch {
            debugPrint(error)
        }
    }


// MARK: - file path handling
    
    func folderPathForEpisodes() -> String {
        var folderPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        folderPath = folderPath + "/episodes"
        return folderPath
    }
    
    func fileExists() -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath)
    }
    
    func prepareFilePath() {
        let folderPath = folderPathForEpisodes()
        filePath = folderPath + ("/" + fileName)
        
        assureBackupExclusion()
        
        // create folder if needed
        do {
            let fileManager = FileManager.default
            try fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
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
            let fileUrl = URL(fileURLWithPath: filePath)
            var value: AnyObject?
            try (fileUrl as NSURL).getResourceValue(&value, forKey: .isExcludedFromBackupKey)
            assert(isExcluded(value),
                   "downloaded podcast episode must be excluded from iCloud backup")
        } catch {
            debugPrint(error)
        }
    }
    
    private func isExcluded(_ settingsValue: AnyObject?) -> Bool {
        guard let isExcluded = settingsValue as? NSNumber else { return false }
        return isExcluded.boolValue
    }
    
    /** Excludes the (downloaded) file from iCloud backup. */
    func excludeFromBackup() {
        do {
            let fileUrl = URL(fileURLWithPath: filePath)
            try (fileUrl as NSURL).setResourceValue(NSNumber(value: true), forKey: .isExcludedFromBackupKey)
        } catch {
            debugPrint(error)
        }
    }
}
