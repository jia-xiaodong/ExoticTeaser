//
//  TeaserGenerator.swift
//  ExoticTeaser
//
//  Created by jia xiaodong on 7/25/20.
//  Copyright © 2020 homemade. All rights reserved.
//

import Foundation

public class TreaserGenerator
{
	let teaserRoot = "/Users/xiaodong/UserData/erowall"
	var directoryList: [NSURL]
	var directoryCounter: Int
	var videoList: [NSURL]?
	var videoCounter: Int
	
	init() {
		directoryList = []
		directoryCounter = 0
		videoList = nil
		videoCounter = 0
		
		let fileManager = NSFileManager.defaultManager()
		let rootUrl = NSURL(fileURLWithPath: teaserRoot, isDirectory: true)
		let properties = [NSURLIsDirectoryKey]
		let enumerator = fileManager.enumeratorAtURL(rootUrl,
						 includingPropertiesForKeys: properties,
											options: [.SkipsHiddenFiles, .SkipsPackageDescendants],
									   errorHandler: { (_, _)->Bool in return true })
		guard enumerator != nil else {
			return
		}
		
		// FIXME: weird compile error
		/*
		If I wrote like this:
		    for url in enumerator! {...}
		
		I'll get compile error that's saying:
		    Command failed due to signal: Segmentation fault: 11
		What confuses me: if I use wrong syntax, why compiler tells me so late?
		*/
		for case let url as NSURL in enumerator! {
			if let resourceValues = try? url.resourceValuesForKeys(properties) {
				if resourceValues[NSURLIsDirectoryKey] as! Bool {
					directoryList.append(url)
				}
			}
		}
		if directoryList.count == 0 {
			debugPrint("[Error] teaser root directory is empty.")
			return
		}
		
		srandom(UInt32(time(nil)))
		
		// Fisher-Yates shuffle algorithm
		var last = directoryList.count - 1
		while (last > 0) {
			let swapped = random() % last // [0 ~ last-1]
			let tmp = directoryList[swapped]
			directoryList[swapped] = directoryList[last]
			directoryList[last] = tmp
			last -= 1
		}
	}
	
	//! Navigate to next clip in current group. If no more, jump to next group.
	public func next() -> NSURL? {
		if videoCounter < videoList?.count {
			let video = videoList![videoCounter]
			videoCounter += 1
			return video
		}
		// begin to iterate next directory
		while directoryCounter < directoryList.count {
			videoList = videosInDirectory(directoryList[directoryCounter])
			directoryCounter += 1
			
			if videoList != nil {
				videoCounter = 1
				return videoList![0]
			}
		}
		return nil // all directories are done iterating.
	}
	
	//! jump to next group
	public func nextGroup() -> NSURL? {
		while directoryCounter < directoryList.count {
			videoList = videosInDirectory(directoryList[directoryCounter])
			directoryCounter += 1
			
			if videoList != nil {
				videoCounter = 1
				return videoList![0]
			}
		}
		return nil // all directories are done iterating.
	}
	
	private func videosInDirectory(url: NSURL) -> [NSURL]? {
		let fileManager = NSFileManager.defaultManager()
		guard var files = try? fileManager.contentsOfDirectoryAtURL(url,
										includingPropertiesForKeys: nil,
														   options: .SkipsHiddenFiles)
		else {
			return nil
		}
		files = files.filter({ $0.absoluteString.hasSuffix(".mp4") })
		guard files.count > 0 else {
			return nil
		}
		// sort base on filename ascendingly
		files.sortInPlace() {
			guard let file0 = $0.lastPathComponent, let file1 = $1.lastPathComponent else {
				return $0.absoluteString < $1.absoluteString
			}
			guard let s0 = file0.rangeOfString("_"), let e0 = file0.rangeOfString(".") else {
				return $0.absoluteString < $1.absoluteString
			}
			guard let s1 = file1.rangeOfString("_"), let e1 = file1.rangeOfString(".") else {
				return $0.absoluteString < $1.absoluteString
			}
			let d0 = file0[s0.startIndex.advancedBy(1)..<e0.startIndex]
			let d1 = file1[s1.startIndex.advancedBy(1)..<e1.startIndex]
			return Int(d0) < Int(d1)
		}
		return files
	}
}