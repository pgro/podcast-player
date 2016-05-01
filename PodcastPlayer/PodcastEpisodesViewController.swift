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
            self.episodes = parser.parseEpisodes()
            
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
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = self.collectionView?.cellForItemAtIndexPath(indexPath) as! PodcastEpisodeCell
        if cell.status == PodcastEpisodeCell.Status.IsDownloading {
            // download is already in progress -> nothing to do
            return
        }
        
        /* download selected podcast episode (if necessary)
         * and update the cell status accordingly */
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let episode = self.episodes[indexPath.item]
            let result = self.prepareEpisodeFilePath(episode)
            if result.status == PathStatus.Exists {
                self.updateEpisodeCellStatus(PodcastEpisodeCell.Status.FinishedDownload,
                                             forCellAtIndexPath: indexPath)
                return
            }
            if result.status == PathStatus.Error {
                self.updateEpisodeCellStatus(PodcastEpisodeCell.Status.NeedsDownload,
                                             forCellAtIndexPath: indexPath)
                return
            }
            
            self.updateEpisodeCellStatus(PodcastEpisodeCell.Status.IsDownloading,
                                         forCellAtIndexPath: indexPath)
            // TODO: show waiting indicator
            let episodeFileData = NSData(contentsOfURL: NSURL(string: episode.url)!)
            // TODO: avoid iCloud backup
            let success = episodeFileData?.writeToFile(result.path!, atomically: true)
            let status = (success != nil) ? PodcastEpisodeCell.Status.FinishedDownload
                                          : PodcastEpisodeCell.Status.NeedsDownload
            self.updateEpisodeCellStatus(status,
                                         forCellAtIndexPath: indexPath)
        }
    }
    
    
    func updateEpisodeCellStatus(status: PodcastEpisodeCell.Status,
                                 forCellAtIndexPath indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_main_queue()) { 
            let cell = self.collectionView?.cellForItemAtIndexPath(indexPath) as! PodcastEpisodeCell
            cell.status = status
        }
    }
    
    
    func folderPathForEpisodes() -> String {
        var folderPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        folderPath = folderPath.stringByAppendingString("/episodes")
        return folderPath
    }
    
    
    enum PathStatus {
        case Error
        case Exists
        case IsFree
    }
    
    /** Returns the target path for download when it is available
        or nil if it was already downloaded (i.e. file exists)
        or if an error occured. */
    func prepareEpisodeFilePath(episode: Episode) -> (status: PathStatus, path: String?) {
        let folderPath = self.folderPathForEpisodes()
        let path = folderPath.stringByAppendingString("/" + episode.fileName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            return (PathStatus.Exists, nil)
        }
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            debugPrint(error)
            return (PathStatus.Exists, nil)
        }
        
        return (PathStatus.IsFree, path)
    }
}
