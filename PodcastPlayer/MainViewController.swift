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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedEpisodesSegue" {
            navigationItem.title = "Podcast Episodes"
            let controller = segue.destination as? PodcastEpisodesViewController
            controller?.waitingIndicator = waitingIndicator
            return
        }
    }
}
