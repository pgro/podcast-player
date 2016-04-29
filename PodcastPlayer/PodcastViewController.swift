//
//  ViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit

class PodcastViewController: UIViewController {
    var episodes = Array<Episode>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let parser = PodcastXmlParser()
        episodes = parser.parseEpisodes()
    }
    
}
