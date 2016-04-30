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
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // download selected podcast episode if necessary
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let episode = self.episodes[indexPath.item]
            let path = self.prepareEpisodeFilePath(episode)
            if (path.isEmpty) {
                return;
            }
            
            let episodeFileData = NSData(contentsOfURL: NSURL(string: episode.url)!)
            // TODO: avoid iCloud backup
            let success = episodeFileData?.writeToFile(path, atomically: true)
            debugPrint(success)
        }
    }
    
    func folderPathForEpisodes() -> String {
        var folderPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        folderPath = folderPath.stringByAppendingString("/episodes")
        return folderPath
    }
    
    func prepareEpisodeFilePath(episode: Episode) -> String {
        let folderPath = self.folderPathForEpisodes()
        let path = folderPath.stringByAppendingString("/" + episode.fileName)
        debugPrint(path)
        
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            return ""
        }
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            debugPrint(error)
            return ""
        }
        
        return path
    }
}
