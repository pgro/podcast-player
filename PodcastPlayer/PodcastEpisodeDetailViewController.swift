//
//  PodcastEpisodeDetailViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 05.05.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit

class PodcastEpisodeDetailViewController: UIViewController {
    var episode: Episode?
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = episode?.title
        self.dateLabel.text = episode?.date
        self.descriptionLabel.text = episode?.description
    }
}
