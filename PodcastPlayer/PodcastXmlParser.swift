//
//  PodcastXmlParser.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation

class PodcastXmlParser: NSObject, NSXMLParserDelegate {
    var episodes = Array<Episode>()
    var currentEpisode: Episode?
    var currentElementName: String?
    
    func parseEpisodes() -> Array<Episode> {
        let podcastUrl = "http://www.rocketbeans.tv/plauschangriff.xml"
        let parser = NSXMLParser(contentsOfURL: NSURL(string: podcastUrl)!)
        parser?.delegate = self
        parser?.parse()
        return episodes
    }
    

// MARK: - NSXMLParserDelegate
    
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
        
        tryToParseUrl(attributeDict["url"])
    }
    
    func tryToParseUrl(xmlCandidateUrl: String?) {
        if currentElementName != "enclosure" {
            return
        }
        if xmlCandidateUrl == nil {
            return
        }
        
        currentEpisode?.url = xmlCandidateUrl!
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
            currentEpisode?.title += string
            break
        case "pubDate":
            currentEpisode?.date += string
            break
        case "itunes:summary":
            currentEpisode?.description += string
            break
        case "itunes:duration":
            currentEpisode?.duration += string
            break
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
