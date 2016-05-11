//
//  PodcastEpisodeCell.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 30.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit

class PodcastEpisodeCell: UICollectionViewCell, EpisodeDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var downloadingIndicator: UIActivityIndicatorView!
    
    var episode: Episode? {
        didSet {
            episode?.delegate = self
            updateViewFromEpisode()
        }
    }

    
    @IBAction func downloadEpisode(sender: AnyObject) {
        switch episode!.status {
        case .NotStarted:
            episode?.download()
            break
        case .Finished:
            episode?.delete()
            break
        default:
            break
        }
    }
    

    func updateViewFromEpisode() {
        titleLabel.text = episode!.title
        descriptionLabel.text = episode!.description
        dateLabel.text = extractDate(episode!.date)
        updateViewFromStatus()
    }
    
    func updateViewFromStatus() {
        switch episode!.status {
        case .NotStarted:
            statusView.backgroundColor = UIColor.redColor()
            downloadButton.hidden = false
            downloadButton.setTitle("", forState: .Normal)
            downloadingIndicator.stopAnimating()
            break
        case .InProgress:
            statusView.backgroundColor = UIColor.yellowColor()
            downloadButton.hidden = true
            downloadingIndicator.startAnimating()
            break
        case .Finished:
            statusView.backgroundColor = UIColor.greenColor()
            downloadButton.hidden = false
            downloadButton.setTitle("", forState: .Normal)
            downloadingIndicator.stopAnimating()
            break
        }
    }
    
    /** assumed input format: Mon, 28 Sep 2015 00:30:00 CET
     * desired output format: 28 Sep 2015 */
    func extractDate(dateString: String) -> String {
        var date = dateString
        
        let dayIndex = date.characters.indexOf(",")!.advancedBy(2)
        date = date.substringFromIndex(dayIndex)
        
        let yearEndIndex = date.characters.indexOf(":")!.advancedBy(-3)
        date = date.substringToIndex(yearEndIndex)
        
        return date
    }
    
    
// MARK: - EpisodeDelegate
    
    func episode(episode: Episode, didChangeStatus status: DownloadStatus) {
        updateViewFromStatus()
    }
}
