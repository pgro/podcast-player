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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEpisodeFileNameSaving() {
        // the file name must be the same for the same url during different retrievals
        let testUrl = "http://test.xyz/abc.mp3"
        
        let episode1 = Episode()
        episode1.url = testUrl
        
        let settings = SettingsManager(episodeUrl: testUrl)
        
        XCTAssertEqual(episode1.fileName, settings.loadFileName())
        XCTAssertFalse(episode1.fileName.isEmpty)
    }
    
}
