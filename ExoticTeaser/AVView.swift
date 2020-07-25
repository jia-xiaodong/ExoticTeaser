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
	
	// FIXME: in order to accept Key events, the below method should be defined in theory. But in practice it doesn't have to.
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
	
	override public func keyDown(theEvent: NSEvent) {
		switch theEvent.keyCode {
		case 49:  // space-bar
			let avLayers = self.layer!.sublayers!.filter({ $0 is AVPlayerLayer })
			guard avLayers.count > 0 else {
				return
			}
			guard let player = (avLayers[0] as? AVPlayerLayer)?.player else {
				return
			}
			if (player.rate == 1.0) {
				player.pause()
			} else {
				player.play()
			}
		case 53:  // esc
			NSApp.terminate(nil)
		default:
			break
		}
	}
}