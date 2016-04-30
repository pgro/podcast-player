//
//  Episode.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation

class Episode {
    var title = ""
    var description = ""
    var url = "" {
        didSet {
            prepareFileName()
        }
    }
    var date = ""
    var fileName = ""
    
    
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
}
