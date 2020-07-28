//
//  VideoView.swift
//  ExoticTeaser
//
//  Created by jia xiaodong on 7/25/20.
//  Copyright © 2020 homemade. All rights reserved.
//

import Cocoa
import Foundation
import AVFoundation

public class AVView: NSView {
	private var frameOrigin: CGPoint?
	
	// FIXME: in order to accept KeyDown events, the below method should be defined in theory. But in practice it doesn't have to.
	/*
	override public var acceptsFirstResponder: Bool {
			return true
	}
	*/

	override public func mouseDown(theEvent: NSEvent) {
		frameOrigin = self.window?.frame.origin
		//
		super.mouseDown(theEvent)
	}
	
	override public func mouseDragged(theEvent: NSEvent) {
		let newOrigin = NSPoint(x: frameOrigin!.x + theEvent.deltaX, y: frameOrigin!.y - theEvent.deltaY)
		self.window!.setFrameOrigin(newOrigin)
		frameOrigin = newOrigin
		//
		super.mouseDragged(theEvent)
	}
}