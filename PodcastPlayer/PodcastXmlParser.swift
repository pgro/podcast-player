//
//  PodcastXmlParser.swift
//  PodcastPlayer
//
//  Created by Peter Großmann on 29.04.16.
//  Copyright © 2016 Peter Großmann. All rights reserved.
//

import Foundation

class PodcastXmlParser: NSObject, XMLParserDelegate {
    weak var podcast: Podcast?
    var episodes = Array<Episode>()
    var currentEpisode: Episode?
    var currentElementName: String?
    
    init(podcast: Podcast) {
        self.podcast = podcast
    }
    
    func parseEpisodes() -> Array<Episode> {
        let parser = XMLParser(contentsOf: URL(string: podcast!.feedUrl)!)
        parser?.delegate = self
        parser?.parse()
        return episodes
    }
    

// MARK: - NSXMLParserDelegate
    
    func parser(_ parser: XMLParser,
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
    
    func tryToParseStreamUrl(_ xmlCandidateUrl: String?) {
        if currentElementName != "enclosure" ||
            xmlCandidateUrl == nil {
            return
        }
        
        currentEpisode?.url = xmlCandidateUrl!
    }
    
    func tryToParsePodcastImageUrl(_ xmlCandidateUrl: String?) {
        if currentElementName != "itunes:image" ||
            currentEpisode != nil ||
            xmlCandidateUrl == nil {
            return
        }
        
        podcast?.imageUrl = xmlCandidateUrl!
    }
    
    func parser(_ parser: XMLParser,
                foundCharacters string: String) {
        if currentElementName == nil {
            return
        }
        
        if currentEpisode != nil {
            parseEpisode(string)
        }
    }
    
    func parseEpisode(_ string: String) {
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
    
    func parser(_ parser: XMLParser,
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
        
        var dayIndex = dateString.characters.index(of: ",")!
        dayIndex = dateString.index(dayIndex, offsetBy: 2)
        dateString = dateString.substring(from: dayIndex)
        
        var yearEndIndex = dateString.characters.index(of: ":")!
        yearEndIndex = dateString.index(yearEndIndex, offsetBy: -3)
        dateString = dateString.substring(to: yearEndIndex)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "dd LLL yyyy"
        let t = formatter.date(from: dateString)
        let date = t!
        
        formatter.dateFormat = "yyyy-MM-dd"
        currentEpisode?.date = formatter.string(from: date)
    }
}
