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
        
        playerObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1),
                                                         queue: DispatchQueue.main)
        { [weak self] (time) in
            self?.playbackProgressDidChange(time)
        } as AnyObject?
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playbackDidEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
        player?.currentItem?.addObserver(self, forKeyPath: keepUpKey, options: .new, context: &kvoContext)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            debugPrint(error)
        }
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kvoContext && keyPath == keepUpKey {
            guard let keepUp = player?.currentItem?.isPlaybackLikelyToKeepUp else {
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
        
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        player?.removeTimeObserver(playerObserver!)
        player?.currentItem?.removeObserver(self, forKeyPath: keepUpKey, context: &kvoContext)
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.endReceivingRemoteControlEvents()
        
        savePlaybackProgress()
        saveVolume()
    }
    
    func appDidEnterBackground() {
        savePlaybackProgress()
        saveVolume()
    }
    
    
    func initAssetAndProgress() {
        var url = URL(string: episode!.url)
        if episode!.fileExists() {
            url = URL(fileURLWithPath: episode!.filePath)
        }
        
        let asset = player?.currentItem?.asset as? AVURLAsset
        if asset == nil || asset!.url.absoluteString != url?.absoluteString {
            player?.pause()
            let playerItem = AVPlayerItem(url: url!)
            player?.replaceCurrentItem(with: playerItem)
            
            playbackProgressSlider.isEnabled = false
            playButton.isEnabled = false
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
    
    
    @IBAction func togglePlayback(_ sender: AnyObject) {
        isPlaying = !isPlaying
        
        // set pause/play icon via Font Awesome
        let title = isPlaying ? "" : ""
        playButton.setTitle(title, for: .normal)
        
        if isPlaying {
            player?.play()
        } else {
            player?.pause()
            savePlaybackProgress()
        }
        
        updateRemoteControlProgress()
    }
    
    
    @IBAction func changeVolume(_ sender: AnyObject) {
        player?.volume = volumeSlider.value
    }
    
    func convertTimeToString(_ totalSeconds: Double) -> String {
        let hours = Int(totalSeconds / 3600)
        let minutes = Int(totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        let string = String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        return string
    }
    
    
    // MARK: - playback progress handling
    
    func playbackProgressDidChange(_ time: CMTime) {
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
    
    @IBAction func updatePlaybackProgress(_ sender: AnyObject) {
        let total = player?.currentItem?.asset.duration.seconds
        let newPosition = Double(playbackProgressSlider.value) * total!
        player?.seek(to: CMTimeMake(Int64(newPosition), 1))
        positionLabel.text = convertTimeToString(newPosition)
        updateRemoteControlProgress()
    }
    
    func updatePlaybackProgressInGui() {
        let total = player?.currentItem?.asset.duration.seconds
        let current = self.player?.currentItem?.currentTime().seconds
        self.playbackProgressSlider.value = Float(current! / total!)
        let newPosition = Double(playbackProgressSlider.value) * total!
        positionLabel.text = convertTimeToString(newPosition)
        updateRemoteControlProgress()
    }
    
    @IBAction func startPlaybackProgressUpdate(_ sender: AnyObject) {
        isPlaybackProgressSliderTouched = true
    }
    @IBAction func endPlaybackProgressUpdate(_ sender: AnyObject) {
        isPlaybackProgressSliderTouched = false
    }
    
    
    func updatePlaybackProgressAndDuration() {
        DispatchQueue.global().async {
            [weak self] in
            /* retrieve duration asynchronous so the GUI is not blocked
             * when the asset needs to be retrieved from a remote URL */
            let total = self?.player?.currentItem?.asset.duration.seconds
            
            DispatchQueue.main.async {
                self?.durationLabel.text = self?.convertTimeToString(total!)
                
                self?.updatePlaybackProgressForCurrentPlaybackRate()
                
                self?.waitingIndicator.stopAnimating()
                self?.playbackProgressSlider.isEnabled = true
                self?.playButton.isEnabled = true
                
                self?.initRemoteControlInfo()
            }
        }
    }
    
    func updatePlaybackProgressForCurrentPlaybackRate() {
        if player?.rate == 1 {
            updatePlaybackProgressInGui()
            togglePlayback(self)
        } else {
            playbackProgressSlider.value = retrievePlaybackProgress()
            updatePlaybackProgress(self)
        }
    }
    
    
    // MARK: load from/save to user defaults
    
    /** saves progress percentage per episode url */
    func savePlaybackProgress() {
        episode?.settings?.savePlaybackProgress(playbackProgressSlider.value)
    }
    
    func retrievePlaybackProgress() -> Float {
        let progress = episode?.settings?.loadPlaybackProgress()
        return progress!
    }
    
    
    // MARK: -
    
    func saveVolume() {
        let defaults = UserDefaults.standard
        defaults.setValue(volumeSlider.value, forKey: volumeKey)
    }
    
    func restoreVolume() {
        let defaults = UserDefaults.standard
        if defaults.value(forKey: volumeKey) != nil {
            volumeSlider.value = defaults.value(forKey: volumeKey) as! Float
            changeVolume(self)
        }
    }
    
    
    // MARK: - iOS system player/playback info
    
    override func remoteControlReceived(with event: UIEvent?) {
        switch event!.subtype {
        case .remoteControlPlay:
            togglePlayback(self)
            break
        case .remoteControlPause:
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
                              MPMediaItemPropertyPlaybackDuration : NSNumber(value: Float(total!))] as [String : Any]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        updateRemoteControlProgress()
        updateRemoteControlArtwork(coverImageView.image)
    }
    
    func updateRemoteControlProgress() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return
        }
        
        let rate = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: rate)
        
        let total = player?.currentItem?.asset.duration.seconds
        let newPosition = Double(playbackProgressSlider.value) * total!
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: newPosition)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateRemoteControlArtwork(_ image: UIImage?) {
        if image == nil {
            return
        }
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return
        }
        let artwork = MPMediaItemArtwork(image: image!)
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
