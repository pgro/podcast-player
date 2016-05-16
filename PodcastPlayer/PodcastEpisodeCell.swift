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
    @IBOutlet weak var fileActionButton: UIButton!
    @IBOutlet weak var downloadingIndicator: UIActivityIndicatorView!
    
    var episode: Episode? {
        didSet {
            episode?.delegate = self
            updateViewFromEpisode()
        }
    }

    
    @IBAction func doEpisodeFileAction(sender: AnyObject) {
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
        dateLabel.text = episode!.date
        updateViewFromStatus()
        updateRemovedState()
    }
    
    func updateViewFromStatus() {
        switch episode!.status {
        case .NotStarted:
            statusView.backgroundColor = UIColor.redColor()
            fileActionButton.hidden = false
            fileActionButton.setTitle("", forState: .Normal) // set download icon via Font Awesome
            downloadingIndicator.stopAnimating()
            break
        case .InProgress:
            statusView.backgroundColor = UIColor.yellowColor()
            fileActionButton.hidden = true
            downloadingIndicator.startAnimating()
            break
        case .Finished:
            statusView.backgroundColor = UIColor.greenColor()
            fileActionButton.hidden = false
            fileActionButton.setTitle("", forState: .Normal) // set trash icon via Font Awesome
            downloadingIndicator.stopAnimating()
            break
        }
    }

    func updateRemovedState() {
        titleLabel.textColor = episode!.isRemoved ? UIColor.darkGrayColor()
                                                  : UIColor.blackColor()
        descriptionLabel.textColor = titleLabel.textColor
        dateLabel.textColor = titleLabel.textColor
    }
    
    
// MARK: - EpisodeDelegate
    
    func episode(episode: Episode, didChangeStatus status: DownloadStatus) {
        updateViewFromStatus()
    }
    
    func episode(episode: Episode, didChangeIsRemoved isRemoved: Bool) {
        updateRemovedState()
    }
}
