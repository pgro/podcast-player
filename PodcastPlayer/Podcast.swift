//
//  Podcast.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.05.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation


class Podcast {
    let feedUrl: String
    var title = ""
    var imageUrl = ""
    var episodes = Array<Episode>()
    
    init(feedUrl: String) {
        self.feedUrl = feedUrl
    }
    
    func retrieveEpisodes() {
        let parser = PodcastXmlParser(podcast: self)
        episodes = parser.parseEpisodes()
    }
}
