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
    @IBOutlet weak var selectionButton: UIButton!
    @IBOutlet weak var selectionViewWidth: NSLayoutConstraint!
    
    var episode: Episode? {
        didSet {
            episode?.delegate = self
            updateViewFromEpisode()
        }
    }

    
    @IBAction func doEpisodeFileAction(_ sender: AnyObject) {
        guard let episode = episode else { return }
        switch episode.status {
        case .notStarted:
            episode.download()
            break
        case .finished:
            episode.delete()
            break
        default:
            break
        }
    }
    

    func updateViewFromEpisode() {
        titleLabel.text = episode?.title
        descriptionLabel.text = episode?.description
        dateLabel.text = episode?.date
        updateViewFromStatus()
        updateRemovedState()
    }
    
    func updateViewFromStatus() {
        guard let episode = episode else { return }
        
        switch episode.status {
        case .notStarted:
            statusView.backgroundColor = UIColor.red
            fileActionButton.isHidden = false
            fileActionButton.setTitle("", for: .normal) // set download icon via Font Awesome
            downloadingIndicator.stopAnimating()
            break
        case .inProgress:
            statusView.backgroundColor = UIColor.yellow
            fileActionButton.isHidden = true
            downloadingIndicator.startAnimating()
            break
        case .finished:
            statusView.backgroundColor = UIColor.green
            fileActionButton.isHidden = false
            fileActionButton.setTitle("", for: .normal) // set trash icon via Font Awesome
            downloadingIndicator.stopAnimating()
            break
        }
    }

    func updateRemovedState() {
        guard let episode = episode else { return }
        
        titleLabel.textColor = episode.isRemoved ? UIColor.darkGray
                                                 : UIColor.black
        descriptionLabel.textColor = titleLabel.textColor
        dateLabel.textColor = titleLabel.textColor
    }
    
    
    var showSelectionIndicator = false {
        didSet {
            if showSelectionIndicator == oldValue {
                return
            }
            
            selectionButton.isHidden = true
            selectionViewWidth.constant = showSelectionIndicator ? 40 : 0
            UIView.animate(withDuration: 0.3,
                           animations: {
                            self.layoutIfNeeded()
            },
                           completion: { _ in
                            self.selectionButton.isHidden = false
            })
        }
    }
    
    override var isSelected: Bool {
        didSet {
            let icon = isSelected ? "" // fa-check-circle-o
                                  : "" // fa-circle-o
            selectionButton.setTitle(icon, for: .normal)
        }
    }
    
    
// MARK: - EpisodeDelegate
    
    func episode(_ episode: Episode, didChangeStatus status: DownloadStatus) {
        updateViewFromStatus()
    }
    
    func episode(_ episode: Episode, didChangeIsRemoved isRemoved: Bool) {
        updateRemovedState()
    }
}
