//
//  PodcastPlayerTests.swift
//  PodcastPlayerTests
//
//  Created by Peter Großmann on 15.05.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import XCTest
@testable import PodcastPlayer


class PodcastPlayerTests: XCTestCase {
    let testUrl = "http://test.xyz/abc.mp3"
    
    override func setUp() {
        super.setUp()
        
        // clear settings
        let settings = SettingsManager(episodeUrl: testUrl)
        settings.saveEpisodeEntry(DictionaryOfDictionaries.Value())
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEpisodeFileNameSaving() {
        // the file name must be the same for the same url during different retrievals
        
        let episode1 = Episode()
        episode1.url = testUrl
        
        let settings = SettingsManager(episodeUrl: testUrl)
        
        XCTAssertEqual(episode1.fileName, settings.loadFileName())
        XCTAssertFalse(episode1.fileName.isEmpty)
    }
    
    func testPlaybackProgressSaving() {
        let progress: Float = 0.123456
        
        let episode1 = Episode()
        episode1.url = testUrl
        
        let settings = SettingsManager(episodeUrl: testUrl)
        settings.savePlaybackProgress(progress)
        
        XCTAssertEqual(episode1.settings?.loadPlaybackProgress(),
                       settings.loadPlaybackProgress())
        XCTAssertEqual(progress,
                       settings.loadPlaybackProgress())
    }
    
}
