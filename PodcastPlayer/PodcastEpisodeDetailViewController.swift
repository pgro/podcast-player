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
    let volumeKey = "volume"
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playbackProgressSlider: UISlider!
    var isPlaybackProgressSliderTouched = false
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var speakerIconView: UILabel!
    @IBOutlet weak var waitingIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = episode?.title
        self.dateLabel.text = episode?.date
        self.descriptionLabel.text = episode?.description
        
        var url = NSURL(string: episode!.url)
        if episode!.fileExists() {
            url = NSURL(fileURLWithPath: episode!.filePath)
        }
        let playerItem = AVPlayerItem(URL: url!)
        self.player.replaceCurrentItemWithPlayerItem(playerItem)
        
        self.player.volume = volumeSlider.value
        updatePlaybackProgressAndDuration()
        restoreVolume()
        
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
                                                         selector: #selector(appDidEnterBackground),
                                                         name: UIApplicationDidEnterBackgroundNotification,
                                                         object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        player.removeTimeObserver(playerObserver!)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        savePlaybackProgress()
        saveVolume()
    }
    
    func appDidEnterBackground() {
        savePlaybackProgress()
        saveVolume()
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
    
    func convertTimeToString(totalSeconds: Double) -> String {
        let hours = Int(totalSeconds / 3600)
        let minutes = Int(totalSeconds % 3600 / 60)
        let seconds = Int(totalSeconds % 60)
        let string = String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        return string
    }
    

// MARK: - playback progress handling
    
    func playbackProgressDidChange(time: CMTime) {
        if isPlaybackProgressSliderTouched {
            return
        }
        
        let total = player.currentItem?.asset.duration.seconds
        let new = time.seconds
        playbackProgressSlider.value = Float(new / total!)
        positionLabel.text = convertTimeToString(new)
    }
    
    func playbackDidEnd(notification: NSNotification) {
        if isPlaying {
            togglePlayback(self)
        }
    }
    
    @IBAction func updatePlaybackProgress(sender: AnyObject) {
        let total = player.currentItem?.asset.duration.seconds
        let newPosition = Double(playbackProgressSlider.value) * total!
        player.seekToTime(CMTimeMake(Int64(newPosition), 1))
        positionLabel.text = convertTimeToString(newPosition)
        isPlaybackProgressSliderTouched = false
    }
    
    @IBAction func startPlaybackProgressUpdate(sender: AnyObject) {
        isPlaybackProgressSliderTouched = true
    }
    

// MARK: load from/save to user defaults
    
    /** saves progress percentage per episode url */
    func savePlaybackProgress() {
        episode?.settings?.savePlaybackProgress(playbackProgressSlider.value)
    }
    
    func updatePlaybackProgressAndDuration() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            /* retrieve duration asynchronous so the GUI is not blocked
             * when the asset needs to be retrieved from a remote URL */
            let total = self.player.currentItem?.asset.duration.seconds
            
            dispatch_async(dispatch_get_main_queue()) {
                self.durationLabel.text = self.convertTimeToString(total!)
                
                self.playbackProgressSlider.value = self.retrievePlaybackProgress()
                self.updatePlaybackProgress(self)
                
                self.waitingIndicator.stopAnimating()
            }
        }
    }
    
    func retrievePlaybackProgress() -> Float {
        let progress = episode?.settings?.loadPlaybackProgress()
        return progress!
    }
    
    
// MARK: -
    
    func saveVolume() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(volumeSlider.value, forKey: volumeKey)
    }
    
    func restoreVolume() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.valueForKey(volumeKey) != nil {
            volumeSlider.value = defaults.valueForKey(volumeKey) as! Float
            changeVolume(self)
        }
    }
}
