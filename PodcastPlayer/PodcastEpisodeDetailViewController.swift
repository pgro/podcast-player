//
//  PodcastEpisodeDetailViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 05.05.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit
import AVFoundation

class PodcastEpisodeDetailViewController: UIViewController {
    var episode: Episode?
    var isPlaying = false
    var player = AVPlayer()
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = episode?.title
        self.dateLabel.text = episode?.date
        self.descriptionLabel.text = episode?.description
        self.durationLabel.text = episode?.duration
        
        let result = episode?.prepareEpisodeFilePath()
        let fileUrl = NSURL(fileURLWithPath: result!.path!)
        let playerItem = AVPlayerItem(URL: fileUrl)
        self.player.replaceCurrentItemWithPlayerItem(playerItem)
    }
    
    
    @IBAction func togglePlayback(sender: AnyObject) {
        self.isPlaying = !self.isPlaying
        
        let title = self.isPlaying ? "pause" : "play"
        self.playButton.setTitle(title, forState: UIControlState.Normal)
        
        if self.isPlaying {
            self.player.play()
        } else {
            self.player.pause()
        }
    }
}
