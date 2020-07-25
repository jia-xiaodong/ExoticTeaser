//
//  TeaserGenerator.swift
//  ExoticTeaser
//
//  Created by jia xiaodong on 7/25/20.
//  Copyright © 2020 homemade. All rights reserved.
//

import Foundation

class TreaserGenerator
{
	let teaserRoot = "/Users/xiaodong/UserData/erowall"
	var currentList: [NSURL]?
	var nextFile = 0
	
	func next() throws -> NSURL? {
		let fileManager = NSFileManager.defaultManager()
		if currentList?.count <= nextFile {
			let rootUrl = NSURL(fileURLWithPath: teaserRoot, isDirectory: true)
			let paths = try fileManager.contentsOfDirectoryAtURL(rootUrl,
			                                                     includingPropertiesForKeys: nil,
			                                                     options: .SkipsHiddenFiles)
			guard paths.count > 0 else {
				debugPrint("[Error] teaser root directory is empty.")
				currentList = nil
				return nil
			}
			let selected = random() % paths.count
			currentList = try fileManager.contentsOfDirectoryAtURL(paths[selected],
			                                                       includingPropertiesForKeys: nil,
			                                                       options: .SkipsHiddenFiles)
			// sort base on filename ascendingly
			currentList?.sortInPlace() {
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
			nextFile = 0
		}
		nextFile += 1
		return currentList?[nextFile-1]
	}
}