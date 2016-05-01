//
//  PodcastEpisodeCell.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 30.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit

class PodcastEpisodeCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var downloadButton: UIButton!
    
    var episode: Episode? {
        didSet {
            updateViewFromEpisode()
        }
    }

    
    enum Status {
        case NeedsDownload
        case IsDownloading
        case FinishedDownload
    @IBAction func downloadEpisode(sender: AnyObject) {
        episode?.download()
    }
    
    var status = Status.NeedsDownload {
        didSet {
            switch status {
            case .NeedsDownload:
                statusView.backgroundColor = UIColor.redColor()
                break
            case .IsDownloading:
                statusView.backgroundColor = UIColor.yellowColor()
                break
            case .FinishedDownload:
                statusView.backgroundColor = UIColor.greenColor()
                break
            }
        }
    }

    func updateViewFromEpisode() {
        titleLabel.text = episode!.title
        descriptionLabel.text = episode!.description
        dateLabel.text = extractDate(episode!.date)
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
}
