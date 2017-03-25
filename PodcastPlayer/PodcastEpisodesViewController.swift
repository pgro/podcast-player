//
//  ViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit
import AVFoundation

class PodcastEpisodesViewController: UICollectionViewController {
    let podcast = Podcast(feedUrl: "http://www.rocketbeans.tv/plauschangriff.xml")
    var episodes = Array<Episode>()
    let cellMargin = CGFloat(10)
    weak var waitingIndicator: UIActivityIndicatorView?
    var multiSelectButton: UIBarButtonItem?
    var deleteButton: UIBarButtonItem?
    let player = AVPlayer()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsetsMake(cellMargin, cellMargin, cellMargin, cellMargin)
        createBarButtons()
        loadEpisodes()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showBarButtons()
    }
    
    
    func createBarButtons() {
        multiSelectButton = UIBarButtonItem(title: "",
                                            style: UIBarButtonItemStyle.plain,
                                            target: self,
                                            action: #selector(toggleMultiSelection))
        let font = UIFont(name: "FontAwesome", size: 20)
        multiSelectButton!.setTitleTextAttributes([NSFontAttributeName:font!],
                                                 for: .normal)
        deleteButton = UIBarButtonItem(title: "",
                                       style: UIBarButtonItemStyle.plain,
                                       target: self,
                                       action: #selector(deleteSelectedEpisodes))
        deleteButton!.setTitleTextAttributes([NSFontAttributeName:font!],
                                             for: .normal)
    }
    
    func showBarButtons() {
        if collectionView!.allowsMultipleSelection {
            parent?.navigationItem.rightBarButtonItems = [multiSelectButton!, deleteButton!]
        } else {
            parent?.navigationItem.rightBarButtonItems = [multiSelectButton!]
        }
    }
    
    
    func loadEpisodes() {
        waitingIndicator?.startAnimating()
        DispatchQueue.global().async {
            self.podcast.retrieveEpisodes()
            self.episodes = self.podcast.episodes
            self.sortEpisodes()
            DispatchQueue.main.async {
                self.waitingIndicator?.stopAnimating()
                self.collectionView?.reloadData()
            }
        }
    }
    
    func sortEpisodes() {
        episodes.sort(by: { (x, y) -> Bool in
            if x.isRemoved && !y.isRemoved {
                return false
            }
            if y.isRemoved && !x.isRemoved {
                return true
            }
            
            return x.date > y.date
        })
    }
    
    
    override func viewWillTransition(to size: CGSize,
                                           with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionViewLayout.invalidateLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEpisodeDetailSegue" {
            let controller = segue.destination as? PodcastEpisodeDetailViewController
            let episodeCell = sender as? PodcastEpisodeCell
            controller?.episode = episodeCell?.episode
            controller?.podcast = podcast
            controller?.player = player
            return
        }
    }
    
    
    func toggleMultiSelection(_ sender: AnyObject) {
        collectionView?.allowsMultipleSelection = !collectionView!.allowsMultipleSelection
        showBarButtons()
        collectionView?.reloadData()
    }
    
    func deleteSelectedEpisodes(_ sender: AnyObject) {
        guard let selectedIndexPaths = collectionView?.indexPathsForSelectedItems else {
            return
        }
        for indexPath in selectedIndexPaths {
            episodes[indexPath.item].delete()
        }
        sortEpisodes()
        
        toggleMultiSelection(self)
    }
    
    
    //MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "episodeCell", for: indexPath) as! PodcastEpisodeCell
        cell.episode = episodes[indexPath.item]
        cell.showSelectionIndicator = collectionView.allowsMultipleSelection
        return cell
    }
    
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.size.width
        let maxCellWidth = CGFloat(300)
        let columns = floor(totalWidth / maxCellWidth)
        let totalMargin = (columns + CGFloat(1)) * cellMargin
        let cellWidth = (totalWidth - totalMargin) / columns
        let size = CGSize(width: cellWidth, height: CGFloat(85))
        return size
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        if !collectionView.allowsMultipleSelection {
            let cell = collectionView.cellForItem(at: indexPath) as! PodcastEpisodeCell
            performSegue(withIdentifier: "showEpisodeDetailSegue", sender: cell)
        }
    }
}
