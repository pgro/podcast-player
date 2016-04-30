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

    
    enum Status {
        case NeedsDownload
        case IsDownloading
        case FinishedDownload
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
}
