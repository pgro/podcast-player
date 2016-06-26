//
//  PodcastEpisodeDetailViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 05.05.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class PodcastEpisodeDetailViewController: UIViewController {
    var episode: Episode?
    var podcast: Podcast?
    var isPlaying = false
    var player: AVPlayer?
    var playerObserver: AnyObject?
    let volumeKey = "volume"
    let keepUpKey = "playbackLikelyToKeepUp"
    private var kvoContext = 0
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playbackProgressSlider: UISlider!
    var isPlaybackProgressSliderTouched = false
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var waitingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var coverImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = episode?.title
        dateLabel.text = episode?.date
        descriptionLabel.text = episode?.description
        loadImage()
        
        player?.volume = volumeSlider.value
        restoreVolume()
        initAssetAndProgress()
        
        playerObserver = player?.addPeriodicTimeObserverForInterval(CMTimeMake(1, 1),
                                                                        queue: dispatch_get_main_queue())
        { [weak self] (time) in
            self?.playbackProgressDidChange(time)
        }
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(playbackDidEnd),
                                                         name: AVPlayerItemDidPlayToEndTimeNotification,
                                                         object: player?.currentItem)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(appDidEnterBackground),
                                                         name: UIApplicationDidEnterBackgroundNotification,
                                                         object: nil)
        player?.currentItem?.addObserver(self, forKeyPath: keepUpKey, options: .New, context: &kvoContext)
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            debugPrint(error)
        }
    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kvoContext && keyPath == keepUpKey {
            guard let keepUp = player?.currentItem?.playbackLikelyToKeepUp else {
                return
            }
            if keepUp {
                waitingIndicator.stopAnimating()
                if isPlaying {
                    isPlaying = false
                    togglePlayback(self)
                }
            } else {
                waitingIndicator.startAnimating()
            }
            return
        }
        
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        player?.removeTimeObserver(playerObserver!)
        player?.currentItem?.removeObserver(self, forKeyPath: keepUpKey, context: &kvoContext)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        
        savePlaybackProgress()
        saveVolume()
    }
    
    func appDidEnterBackground() {
        savePlaybackProgress()
        saveVolume()
    }
    
    
    func initAssetAndProgress() {
        var url = NSURL(string: episode!.url)
        if episode!.fileExists() {
            url = NSURL(fileURLWithPath: episode!.filePath)
        }
        
        let asset = player?.currentItem?.asset as? AVURLAsset
        if asset == nil || asset!.URL.absoluteString != url?.absoluteString {
            player?.pause()
            let playerItem = AVPlayerItem(URL: url!)
            player?.replaceCurrentItemWithPlayerItem(playerItem)
            
            playbackProgressSlider.enabled = false
            playButton.enabled = false
        }
        updatePlaybackProgressAndDuration()
    }
    
    func loadImage() {
        podcast?.loadImage() { filePath in
            guard let image = UIImage(contentsOfFile: filePath) else {
                return
            }
            self.coverImageView.image = image
            self.updateRemoteControlArtwork(image)
        }
    }
    
    
    @IBAction func togglePlayback(sender: AnyObject) {
        isPlaying = !isPlaying
        
        // set pause/play icon via Font Awesome
        let title = isPlaying ? "" : ""
        playButton.setTitle(title, forState: UIControlState.Normal)
        
        if isPlaying {
            player?.play()
        } else {
            player?.pause()
            savePlaybackProgress()
        }
        
        updateRemoteControlProgress()
    }
    
    
    @IBAction func changeVolume(sender: AnyObject) {
        player?.volume = volumeSlider.value
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
        
        let total = player?.currentItem?.asset.duration.seconds
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
        let total = player?.currentItem?.asset.duration.seconds
        let newPosition = Double(playbackProgressSlider.value) * total!
        player?.seekToTime(CMTimeMake(Int64(newPosition), 1))
        positionLabel.text = convertTimeToString(newPosition)
        updateRemoteControlProgress()
    }
    
    @IBAction func startPlaybackProgressUpdate(sender: AnyObject) {
        isPlaybackProgressSliderTouched = true
    }
    @IBAction func endPlaybackProgressUpdate(sender: AnyObject) {
        isPlaybackProgressSliderTouched = false
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
            let total = self.player?.currentItem?.asset.duration.seconds
            
            dispatch_async(dispatch_get_main_queue()) {
                self.durationLabel.text = self.convertTimeToString(total!)
                
                self.playbackProgressSlider.value = self.retrievePlaybackProgress()
                self.updatePlaybackProgress(self)
                
                self.waitingIndicator.stopAnimating()
                self.playbackProgressSlider.enabled = true
                self.playButton.enabled = true
                
                self.initRemoteControlInfo()
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


// MARK: - iOS system player/playback info

    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        switch event!.subtype {
        case .RemoteControlPlay:
            togglePlayback(self)
            break
        case .RemoteControlPause:
            togglePlayback(self)
            break
        default:
            break
        }
    }
    
    func initRemoteControlInfo() {
        let total = player?.currentItem?.asset.duration.seconds
        let nowPlayingInfo = [MPMediaItemPropertyArtist : episode!.author,
                              MPMediaItemPropertyTitle : episode!.title,
                              MPMediaItemPropertyPlaybackDuration : NSNumber(float: Float(total!))]
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
        updateRemoteControlProgress()
        updateRemoteControlArtwork(coverImageView.image)
    }
    
    func updateRemoteControlProgress() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo else {
            return
        }
        
        let rate = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(double: rate)
        
        let total = player?.currentItem?.asset.duration.seconds
        let newPosition = Double(playbackProgressSlider.value) * total!
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(double: newPosition)
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateRemoteControlArtwork(image: UIImage?) {
        if image == nil {
            return
        }
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo else {
            return
        }
        let artwork = MPMediaItemArtwork(image: image!)
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
    }
}
