//
//  MainViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 01.05.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var waitingIndicator: UIActivityIndicatorView!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedEpisodesSegue" {
            navigationItem.title = "Podcast Episodes"
            let controller = segue.destinationViewController as? PodcastEpisodesViewController
            controller?.waitingIndicator = waitingIndicator
            return
        }
    }
}
