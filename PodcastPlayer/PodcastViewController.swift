//
//  ViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit

class PodcastViewController: UICollectionViewController {
    var episodes = Array<Episode>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let parser = PodcastXmlParser()
        episodes = parser.parseEpisodes()
    }
    
    override func viewWillTransitionToSize(size: CGSize,
          withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        collectionViewLayout.invalidateLayout()
    }
    
    
    //MARK: - UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func collectionView(collectionView: UICollectionView,
                cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("episodeCell", forIndexPath: indexPath) as! PodcastEpisodeCell
        
        let episode = episodes[indexPath.item]
        cell.titleLabel.text = episode.title
        cell.descriptionLabel.text = episode.description
        cell.dateLabel.text = episode.date
        
        return cell
    }
    
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.bounds.size.width, CGFloat(85))
    }
}
