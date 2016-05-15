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
    let cellMargin = CGFloat(10)
    weak var waitingIndicator: UIActivityIndicatorView?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsetsMake(cellMargin, cellMargin, cellMargin, cellMargin)
        
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
        let totalWidth = collectionView.bounds.size.width
        let maxCellWidth = CGFloat(300)
        let columns = floor(totalWidth / maxCellWidth)
        let totalMargin = (columns + CGFloat(1)) * cellMargin
        let cellWidth = (totalWidth - totalMargin) / columns
        let size = CGSizeMake(cellWidth, CGFloat(85))
        return size
    }
}
