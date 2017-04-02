//
//  SettingsManager.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 14.05.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation


typealias DictionaryOfDictionaries = Dictionary<String, Dictionary<String, Any>>

/*
 Settings for episodes are mapped like this:
 "http://www.sample.xyz/episode1.mp3"   --> "fileName" -> "123.mp3"
                                            "duration" -> "02:03:02"
 "http://www.sample.xyz/episode2.mp3"   --> "fileName" -> "124.mp3"
                                            "duration" -> "01:03:00"
 */


class SettingsManager {
    let episodeUrl: String
    private let episodesRootKey = "episodesSettings"
    private let playbackProgressKey = "relativePlaybackProgress"
    private let isRemovedKey = "isRemoved"
    
    init(episodeUrl: String) {
        assert(!episodeUrl.isEmpty, "url must not be empty")
        self.episodeUrl = episodeUrl
    }
    
    
    /** Retrieves the unique file name for the current url.
        Creates (and saves) it in case of a previously unknown url. */
    func loadFileName() -> String {
        let fileNameKey = "fileName"
        var episodeEntry = loadEpisodeEntry()
        guard let fileName = episodeEntry[fileNameKey] as? String else {
            let fileExtension = URL(string: episodeUrl)?.pathExtension ?? "mp3"
            let newFileName = UUID().uuidString + "." + fileExtension
            episodeEntry[fileNameKey] = newFileName
            saveEpisodeEntry(episodeEntry)
            return newFileName
        }
        return fileName
    }
    
    
    func loadPlaybackProgress() -> Float {
        var episodeEntry = loadEpisodeEntry()
        guard let progress = episodeEntry[playbackProgressKey] as? Float else {
            let newValue: Float = 0
            episodeEntry[playbackProgressKey] = newValue
            saveEpisodeEntry(episodeEntry)
            return newValue
        }
        return progress
    }
    
    func savePlaybackProgress(_ value: Float) {
        var episodeEntry = loadEpisodeEntry()
        episodeEntry[playbackProgressKey] = value
        saveEpisodeEntry(episodeEntry)
    }
    
    func loadIsRemoved() -> Bool {
        var episodeEntry = loadEpisodeEntry()
        guard let isRemoved = episodeEntry[isRemovedKey] as? Bool else {
            let newValue = false
            episodeEntry[isRemovedKey] = newValue
            saveEpisodeEntry(episodeEntry)
            return newValue
        }
        return isRemoved
    }
    
    func saveIsRemoved(_ value: Bool) {
        var episodeEntry = loadEpisodeEntry()
        episodeEntry[isRemovedKey] = value
        saveEpisodeEntry(episodeEntry)
    }
    
    
// MARK: - root and episode settings entry
    
    private func loadRootEntry() -> DictionaryOfDictionaries {
        let defaults = UserDefaults.standard
        // maps episodes by their stream urls to a dictionary with settings for each
        guard let episodes = defaults.value(forKey: episodesRootKey) as? DictionaryOfDictionaries else {
            let newRoot = DictionaryOfDictionaries()
            defaults.setValue(newRoot, forKey: episodesRootKey)
            return newRoot
        }
        return episodes
    }
    
    private func saveRootEntry(_ entry: DictionaryOfDictionaries) {
        let defaults = UserDefaults.standard
        defaults.setValue(entry, forKey: episodesRootKey)
    }
    
    
    private func loadEpisodeEntry() -> DictionaryOfDictionaries.Value {
        var episodes = loadRootEntry()
        
        guard let episode = episodes[episodeUrl] else {
            let newEntry = DictionaryOfDictionaries.Value()
            episodes[episodeUrl] = newEntry
            return newEntry
        }
        return episode
    }
    
    func saveEpisodeEntry(_ entry: DictionaryOfDictionaries.Value) {
        var episodes = loadRootEntry()
        episodes[episodeUrl] = entry
        saveRootEntry(episodes)
    }
}
