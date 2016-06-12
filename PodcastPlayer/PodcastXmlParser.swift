//
//  PodcastXmlParser.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation

class PodcastXmlParser: NSObject, NSXMLParserDelegate {
    weak var podcast: Podcast?
    var episodes = Array<Episode>()
    var currentEpisode: Episode?
    var currentElementName: String?
    
    init(podcast: Podcast) {
        self.podcast = podcast
    }
    
    func parseEpisodes() -> Array<Episode> {
        let parser = NSXMLParser(contentsOfURL: NSURL(string: podcast!.feedUrl)!)
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
        
        tryToParsePodcastImageUrl(attributeDict["href"])
        tryToParseStreamUrl(attributeDict["url"])
    }
    
    func tryToParseStreamUrl(xmlCandidateUrl: String?) {
        if currentElementName != "enclosure" ||
            xmlCandidateUrl == nil {
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
        case "itunes:author":
            currentEpisode?.author += string
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
            formatDateForCurrentEpisode()
            episodes.append(currentEpisode!)
            currentEpisode = nil
        }
        
        currentElementName = nil
    }
    
    
    /** assumed input format: Mon, 28 Sep 2015 00:30:00 CET
     * desired output format: 28 Sep 2015 */
    func formatDateForCurrentEpisode() {
        guard var dateString = currentEpisode?.date else {
            return
        }
        
        let dayIndex = dateString.characters.indexOf(",")!.advancedBy(2)
        dateString = dateString.substringFromIndex(dayIndex)
        
        let yearEndIndex = dateString.characters.indexOf(":")!.advancedBy(-3)
        dateString = dateString.substringToIndex(yearEndIndex)
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd LLL yyyy"
        let date = formatter.dateFromString(dateString)!
        
        formatter.dateFormat = "yyyy-MM-dd"
        currentEpisode?.date = formatter.stringFromDate(date)
    }
}
