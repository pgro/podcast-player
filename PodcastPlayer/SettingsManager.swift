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
        if episodeEntry[fileNameKey] == nil {
            episodeEntry[fileNameKey] = UUID().uuidString + "." +
                                        URL(string: episodeUrl)!.pathExtension
            saveEpisodeEntry(episodeEntry)
        }
        
        let fileName = episodeEntry[fileNameKey] as! String
        return fileName
    }
    
    
    func loadPlaybackProgress() -> Float {
        var episodeEntry = loadEpisodeEntry()
        if episodeEntry[playbackProgressKey] == nil {
            episodeEntry[playbackProgressKey] = Float(0)
            saveEpisodeEntry(episodeEntry)
        }
        
        let progress = episodeEntry[playbackProgressKey] as! Float
        return progress
    }
    
    func savePlaybackProgress(_ value: Float) {
        var episodeEntry = loadEpisodeEntry()
        episodeEntry[playbackProgressKey] = value
        saveEpisodeEntry(episodeEntry)
    }
    
    func loadIsRemoved() -> Bool {
        var episodeEntry = loadEpisodeEntry()
        if episodeEntry[isRemovedKey] == nil {
            episodeEntry[isRemovedKey] = false
            saveEpisodeEntry(episodeEntry)
        }
        
        let isRemoved = episodeEntry[isRemovedKey] as! Bool
        return isRemoved
    }
    
    func saveIsRemoved(_ value: Bool) {
        var episodeEntry = loadEpisodeEntry()
        episodeEntry[isRemovedKey] = value
        saveEpisodeEntry(episodeEntry)
    }
    
    
// MARK: - root and episode settings entry
    
    private func loadRootEntry() ->DictionaryOfDictionaries {
        let defaults = UserDefaults.standard
        if defaults.value(forKey: episodesRootKey) == nil {
            defaults.setValue(DictionaryOfDictionaries(), forKey: episodesRootKey)
        }
        
        // maps episodes by their stream urls to a dictionary with settings for each
        let episodes = defaults.value(forKey: episodesRootKey) as! DictionaryOfDictionaries
        
        return episodes
    }
    
    private func saveRootEntry(_ entry: DictionaryOfDictionaries) {
        let defaults = UserDefaults.standard
        defaults.setValue(entry, forKey: episodesRootKey)
    }
    
    
    private func loadEpisodeEntry() ->DictionaryOfDictionaries.Value {
        var episodes = loadRootEntry()
        
        if episodes[episodeUrl] == nil {
            episodes[episodeUrl] = DictionaryOfDictionaries.Value()
        }
        return episodes[episodeUrl]!
    }
    
    func saveEpisodeEntry(_ entry: DictionaryOfDictionaries.Value) {
        var episodes = loadRootEntry()
        episodes[episodeUrl] = entry
        saveRootEntry(episodes)
    }
}
