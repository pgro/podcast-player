//
//  ViewController.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import UIKit

class PodcastViewController: UIViewController, NSXMLParserDelegate {
    var episodes = Array<Episode>()
    var currentEpisode: Episode?
    var currentElementName: String?
    var parseTitle = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let podcastUrl = "http://www.rocketbeans.tv/plauschangriff.xml"
        let parser = NSXMLParser(contentsOfURL: NSURL(string: podcastUrl)!)
        parser?.delegate = self
        parser?.parse()
    }
    
    
    func parser(parser: NSXMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String]) {
        currentElementName = elementName
        
        if elementName == "item" {
            currentEpisode = Episode()
            return
        }
        
        
    }

    func parser(parser: NSXMLParser,
                foundCharacters string: String) {
        if currentElementName == nil {
            return
        }
        
        if currentEpisode != nil {
            parseEpisode(string)
        }
    }
    
    func parseEpisode(string: String) {
        switch currentElementName! {
        case "title":
            currentEpisode?.title = string
            break
        case "guid":
            currentEpisode?.url = string
            break
        case "pubDate":
            currentEpisode?.date = string
            break
        case "itunes:summary":
            currentEpisode?.description = string
        default:
            break
        }
    }
    
    func parser(parser: NSXMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        if elementName == "item" {
            episodes.append(currentEpisode!)
            currentEpisode = nil
        }
        
        currentElementName = nil
    }
}

