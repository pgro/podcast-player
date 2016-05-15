//
//  SettingsManager.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 14.05.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation


typealias DictionaryOfDictionaries = Dictionary<String, Dictionary<String, String>>

/*
 Settings for episodes are mapped like this:
 "http://www.sample.xyz/episode1.mp3"   --> "fileName" -> "123.mp3"
                                            "duration" -> "02:03:02"
 "http://www.sample.xyz/episode2.mp3"   --> "fileName" -> "124.mp3"
                                            "duration" -> "01:03:00"
 */


class SettingsManager {
    let episodeUrl: String
    
    init(episodeUrl: String) {
        assert(!episodeUrl.isEmpty, "url must not be empty")
        self.episodeUrl = episodeUrl
    }
    
    
    func retrieveRootEntry() ->DictionaryOfDictionaries.Value {
        let episodesRootKey = "episodesSettings"
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.valueForKey(episodesRootKey) == nil {
            defaults.setValue(DictionaryOfDictionaries(), forKey: episodesRootKey)
        }
        
        // maps episodes by their stream urls to a dictionary with settings for each
        var episodes = defaults.valueForKey(episodesRootKey) as! DictionaryOfDictionaries
        
        if episodes[episodeUrl] == nil {
            episodes[episodeUrl] = DictionaryOfDictionaries.Value()
        }
        return episodes[episodeUrl]!
    }
    
    /** Retrieves the unique file name for the current url.
        Creates it in case of a previously unknown url. */
    func retrieveFileName() -> String {
        let fileNameKey = "fileName"
        
        var episodeEntry = retrieveRootEntry()
        if episodeEntry[fileNameKey] == nil {
            episodeEntry[fileNameKey] = NSUUID().UUIDString + "." +
                                        NSURL(string: episodeUrl)!.pathExtension!
        }
        
        let fileName = episodeEntry[fileNameKey]!
        return fileName
    }
}
