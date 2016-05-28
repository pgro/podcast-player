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
    var multiSelectButton: UIBarButtonItem?
    var deleteButton: UIBarButtonItem?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsetsMake(cellMargin, cellMargin, cellMargin, cellMargin)
        createBarButtons()
        loadEpisodes()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showBarButtons()
    }
    
    
    func createBarButtons() {
        multiSelectButton = UIBarButtonItem(title: "",
                                            style: UIBarButtonItemStyle.Plain,
                                            target: self,
                                            action: #selector(toggleMultiSelection))
        let font = UIFont(name: "FontAwesome", size: 20)
        multiSelectButton!.setTitleTextAttributes([NSFontAttributeName:font!],
                                                 forState: UIControlState.Normal)
        deleteButton = UIBarButtonItem(title: "",
                                       style: UIBarButtonItemStyle.Plain,
                                       target: self,
                                       action: #selector(deleteSelectedEpisodes))
        deleteButton!.setTitleTextAttributes([NSFontAttributeName:font!],
                                             forState: UIControlState.Normal)
    }
    
    func showBarButtons() {
        if collectionView!.allowsMultipleSelection {
            parentViewController?.navigationItem.rightBarButtonItems = [multiSelectButton!, deleteButton!]
        } else {
            parentViewController?.navigationItem.rightBarButtonItems = [multiSelectButton!]
        }
    }
    
    
    func loadEpisodes() {
        waitingIndicator?.startAnimating()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let parser = PodcastXmlParser()
            self.episodes = parser.parseEpisodes()
            self.episodes.sortInPlace({ (x, y) -> Bool in
                if x.isRemoved {
                    return false
                }
                
                return x.date > y.date
            })
            
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
    
    
    func toggleMultiSelection(sender: AnyObject) {
        collectionView?.allowsMultipleSelection = !collectionView!.allowsMultipleSelection
        showBarButtons()
        collectionView?.reloadData()
    }
    
    func deleteSelectedEpisodes(sender: AnyObject) {
        guard let selectedIndexPaths = collectionView?.indexPathsForSelectedItems() else {
            return
        }
        for indexPath in selectedIndexPaths {
            episodes[indexPath.item].delete()
        }
        
        toggleMultiSelection(self)
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
        cell.showSelectionIndicator = collectionView.allowsMultipleSelection
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
    
    override func collectionView(collectionView: UICollectionView,
                                 didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if !collectionView.allowsMultipleSelection {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PodcastEpisodeCell
            performSegueWithIdentifier("showEpisodeDetailSegue", sender: cell)
        }
    }
}
