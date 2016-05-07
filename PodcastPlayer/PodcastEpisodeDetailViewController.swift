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
    var playerObserver: AnyObject?
    let episodePlaybackProgressKey = "episodePlaybackProgress"
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playbackProgressSlider: UISlider!
    var isPlaybackProgressSliderTouched = false
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var speakerIconView: UILabel!
    
    
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
        
        self.player.volume = volumeSlider.value
        restorePlaybackPogress()
        
        playerObserver = self.player.addPeriodicTimeObserverForInterval(CMTimeMake(1, 1),
                                                                        queue: dispatch_get_main_queue())
        { [weak self] (time) in
            self?.playbackProgressDidChange(time)
        }
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(playbackDidEnd),
                                                         name: AVPlayerItemDidPlayToEndTimeNotification,
                                                         object: playerItem)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(savePlaybackPogress),
                                                         name: UIApplicationDidEnterBackgroundNotification,
                                                         object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        player.removeTimeObserver(playerObserver!)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        savePlaybackPogress()
    }
    
    
    @IBAction func togglePlayback(sender: AnyObject) {
        self.isPlaying = !self.isPlaying
        
        // set pause/play icon via Font Awesome
        let title = self.isPlaying ? "" : ""
        self.playButton.setTitle(title, forState: UIControlState.Normal)
        
        if self.isPlaying {
            self.player.play()
        } else {
            self.player.pause()
        }
    }
    
    @IBAction func changeVolume(sender: AnyObject) {
        player.volume = volumeSlider.value
        // set respective speaker icon via Font Awesome
        speakerIconView.text = volumeSlider.value == 0 ? "" : ""
    }
    

// MARK: - playback progress handling
    
    func playbackProgressDidChange(time: CMTime) {
        if isPlaybackProgressSliderTouched {
            return
        }
        
        let total = player.currentItem?.asset.duration.seconds
        let new = time.seconds
        playbackProgressSlider.value = Float(new / total!)
    }
    
    func playbackDidEnd(notification: NSNotification) {
        if isPlaying {
            togglePlayback(self)
        }
    }
    
    @IBAction func updatePlaybackProgress(sender: AnyObject) {
        let total = player.currentItem?.asset.duration.seconds
        let newPosition = playbackProgressSlider.value * Float(total!)
        player.seekToTime(CMTimeMake(Int64(newPosition), 1))
        isPlaybackProgressSliderTouched = false
    }
    
    @IBAction func startPlaybackProgressUpdate(sender: AnyObject) {
        isPlaybackProgressSliderTouched = true
    }
    

// MARK: load from/save to user defaults
    
    /** saves progress percentage per episode url */
    func savePlaybackPogress() {
        var episodesToProgress = retrieveProgressStorage()
        let url = episode!.url
        episodesToProgress[url] = playbackProgressSlider.value
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(episodesToProgress, forKey: episodePlaybackProgressKey)
    }
    
    func restorePlaybackPogress() {
        let episodesToProgress = retrieveProgressStorage()
        let url = episode!.url
        if episodesToProgress[url] != nil {
            playbackProgressSlider.value = episodesToProgress[url]!
            updatePlaybackProgress(self)
        }
    }
    
    func retrieveProgressStorage() -> Dictionary<String, Float> {
        // ensure that the respective dictionary is already in the defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.valueForKey(episodePlaybackProgressKey) == nil {
            defaults.setValue(Dictionary<String, Float>(), forKey: episodePlaybackProgressKey)
        }
        
        let episodesToProgress = defaults.valueForKey(episodePlaybackProgressKey) as! Dictionary<String, Float>
        return episodesToProgress
    }
}
