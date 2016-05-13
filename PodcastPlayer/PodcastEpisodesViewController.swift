//
//  ViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit

class PodcastEpisodesViewController: UICollectionViewController {
    var episodes = Array<Episode>()
    weak var waitingIndicator: UIActivityIndicatorView?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadEpisodes()
    }
    
    
    func loadEpisodes() {
        waitingIndicator?.startAnimating()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let parser = PodcastXmlParser()
            self.episodes = parser.parseEpisodes().reverse()
            
            dispatch_async(dispatch_get_main_queue()) {
                self.waitingIndicator?.stopAnimating()
                self.collectionView?.reloadData()
            }
        }
    }
    
    
    override func viewWillTransitionToSize(size: CGSize,
                                           withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        collectionViewLayout.invalidateLayout()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showEpisodeDetailSegue" {
            let controller = segue.destinationViewController as? PodcastEpisodeDetailViewController
            let episodeCell = sender as? PodcastEpisodeCell
            controller?.episode = episodeCell?.episode
            return
        }
    }
    
    
    //MARK: - UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func collectionView(collectionView: UICollectionView,
                                 cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("episodeCell", forIndexPath: indexPath) as! PodcastEpisodeCell
        cell.episode = episodes[indexPath.item]
        return cell
    }
    
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.bounds.size.width, CGFloat(85))
    }
}
