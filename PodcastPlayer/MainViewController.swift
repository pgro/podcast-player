//
//  MainViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 01.05.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedEpisodesSegue" {
            navigationItem.title = "Podcast Episodes"
            return
        }
    }
}
