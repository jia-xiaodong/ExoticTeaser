//
//  ViewController.swift
//  ExoticTeaser
//
//  Created by jia xiaodong on 7/24/20.
//  Copyright © 2020 homemade. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation

enum SeekOption: Int {
	case NextClip = 0
	case NextGroup = 1
	case PreviousClip = 2
	case PreviousGroup = 3
	
	//! value type -> reference type
	static func toNumber(i:SeekOption) -> NSNumber {
		return NSNumber(integer: i.rawValue)
	}
}

class ViewController: NSViewController {

	// [jxd] important!
	// must define it to avoid app launching from XIB file
	override func loadView()
	{
		/*
		create a root view.
		We'll attach a layer to it thereafter.
		*/
		self.view = AVView(frame: NSMakeRect(0, 0, 50, 50))

		/*
		Because my NSWindow doesn't have Title Bar. So NSView can't receive KeyDown event.
		Therefore a local monitor must be added explicitly.
		*/
		NSEvent .addLocalMonitorForEventsMatchingMask(.KeyDownMask, handler: { event -> NSEvent? in
			self.keyDown(event)
			return event
		})
	}
	
	var playerLayer: AVPlayerLayer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// attach an AVPlayerLayer to root view
		let playerItem = chooseMovieClip(SeekOption.NextClip)
		let player = AVPlayer(playerItem: playerItem!)
		playerItem?.addObserver(self, forKeyPath: "status", options: .New, context: nil)
		NSNotificationCenter.defaultCenter()
			.addObserver(self,
			             selector: #selector(self.playNextClip(_:)),
			             name: AVPlayerItemDidPlayToEndTimeNotification,
			             object: nil) // "self" gets this notification
		let playerLayer = AVPlayerLayer(player: player)
		
		// the layer's initial anchor is bottom left corner.
		let viewCenter = CGPoint(x: view.bounds.width/2, y: view.bounds.height/2)
		let anchorCenter = CGPoint(x: 0.5, y: 0.5)
		playerLayer.bounds = view.bounds
		playerLayer.position = viewCenter
		playerLayer.anchorPoint = anchorCenter
		
		// make pixel-buffer to accept alpha value.
		playerLayer.pixelBufferAttributes = [
			(kCVPixelBufferPixelFormatTypeKey as String): NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)
		]

		view.wantsLayer = true
		view.layer?.addSublayer(playerLayer)
		self.playerLayer = playerLayer
		
		// FIXME: why it doesn't work?
		/*
		let playerView = AVPlayerView()
		playerView.controlsStyle = .Inline
		playerView.player = player
		playerView.translatesAutoresizingMaskIntoConstraints = false
		playerView.wantsLayer = true
		playerView.layer?.addSublayer(playerLayer)
		view.addSubview(playerView)
		*/
	}

	override var representedObject: AnyObject? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	let teasers = TreaserGenerator()

	// MARK: - Player Item Configuration
	
	func createTransparentItem(url: NSURL) -> AVPlayerItem {
		let asset = AVAsset(URL: url)
		let playerItem = AVPlayerItem(asset: asset)
		// Set the video so that seeking also renders with transparency
		playerItem.seekingWaitsForVideoCompositionRendering = true
		// Apply a video composition (which applies our custom filter)
		playerItem.videoComposition = createVideoComposition(for: asset)
		return playerItem
	}
	
	func createVideoComposition(for asset: AVAsset) -> AVVideoComposition {
		let filter = AlphaFrameFilter(renderingMode: .builtInFilter)
		let composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
			do {
				let (inputImage, maskImage) = request.sourceImage.verticalSplit()
				let outputImage = try filter.process(inputImage, mask: maskImage)
				return request.finishWithImage(outputImage, context: nil)
			} catch {
				debugPrint("Video composition error")
				return request.finishWithError(NSError(domain: "placeholder", code: 0, userInfo: nil))
			}
		})
		
		composition.renderSize = CGSizeApplyAffineTransform(asset.videoSize, CGAffineTransformMakeScale(1.0, 0.5))
		return composition
	}
	
	// MARK: - Key-value-observing on AVPlayerItem
	// Only called once after AVPlayerItem is loaded
	override func observeValueForKeyPath(keyPath: String?,
	                                     ofObject object: AnyObject?,
	                                              change: [String : AnyObject]?,
	                                              context: UnsafeMutablePointer<Void>)
	{
		if keyPath?.compare("status") == NSComparisonResult.OrderedSame {
			let status: AVPlayerItemStatus
			if let statusNumber = change?[NSKeyValueChangeNewKey] as? NSNumber {
				status = AVPlayerItemStatus(rawValue: statusNumber.integerValue)!
			} else {
				status = .Unknown
			}
			// automatically play after play-item is loaded.
			if let playerItem = (object as? AVPlayerItem) {
				switch status {
				case .Failed:
					debugPrint(playerItem.error?.localizedDescription)
				case .ReadyToPlay:
					resizeWindow(playerItem.presentationSize)
					playerLayer?.player?.play()
				case .Unknown:
					break
				}
				playerItem.removeObserver(self, forKeyPath: "status")
			}
		}
	}
	
	func chooseMovieClip(operation: SeekOption) -> AVPlayerItem? {
		let video: NSURL?
		switch operation {
		case .NextClip: // normal play: exit when all videos are done playing.
			video = teasers.next()
			if video == nil {
				NSApp.terminate(nil)
			}
		case .NextGroup: // if it's the last group, ignore it.
			video = teasers.nextGroup()
			if video == nil {
				return nil
			}
		case .PreviousClip: // if it's the 1st clip, ignore it.
			video = teasers.previous()
			if video == nil {
				return nil
			}
		case .PreviousGroup: // if it's the 1st group, ignore it.
			video = teasers.previousGroup()
			if video == nil {
				return nil
			}
		}
		let playItem = createTransparentItem(video!)
		playItem.addObserver(self, forKeyPath: "status", options: .New, context: nil)
		playerLayer?.player?.replaceCurrentItemWithPlayerItem(playItem)
		return playItem
	}
	
	//! resize window to fit movie's size
	func resizeWindow(size: CGSize) {
		let oldOrigin = view.window!.frame.origin // bottom-left corner is Window origin
		view.window?.setFrame(NSRect(origin: oldOrigin, size: size), display: false)
		view.frame = NSRect(origin: .zero, size: size)
		//
		let viewCenter = CGPoint(x: size.width/2, y: size.height/2)
		let anchorCenter = CGPoint(x: 0.5, y: 0.5)
		playerLayer?.bounds = view.bounds
		playerLayer?.position = viewCenter
		playerLayer?.anchorPoint = anchorCenter
	}
	
	override func keyDown(theEvent: NSEvent) {
		switch theEvent.keyCode {
		case 49:  // space-bar
			guard let player = playerLayer?.player else {
				return
			}
			if (player.rate == 1.0) {
				player.pause()
			} else {
				player.play()
			}
		case 53:  // esc
			NSApp.terminate(nil)
		case 123: // left arrow
			let userInfo = ["to": SeekOption.toNumber(.PreviousClip)]
			NSNotificationCenter.defaultCenter()
				.postNotificationName(AVPlayerItemDidPlayToEndTimeNotification,
				                      object: self,
				                      userInfo:userInfo)
		case 124: // right arrow: jump to next clip.
			NSNotificationCenter.defaultCenter()
				.postNotificationName(AVPlayerItemDidPlayToEndTimeNotification, object: self)
		case 125: // bottom arrow
			let userInfo = ["to": SeekOption.toNumber(.NextGroup)]
			NSNotificationCenter.defaultCenter()
				.postNotificationName(AVPlayerItemDidPlayToEndTimeNotification,
				                      object: self,
				                      userInfo:userInfo)
		case 126: // up arrow
			let userInfo = ["to": SeekOption.toNumber(.PreviousGroup)]
			NSNotificationCenter.defaultCenter()
				.postNotificationName(AVPlayerItemDidPlayToEndTimeNotification,
				                      object: self,
				                      userInfo:userInfo)
		default:
			debugPrint("[user key] code:", theEvent.keyCode)
		}
	}
	
	func playNextClip(notification: NSNotification) {
		let info = notification.userInfo
		var operation = SeekOption.NextClip
		if let param = info?["to"] as? NSNumber {
			operation = SeekOption(rawValue: param.integerValue)!
		}
		chooseMovieClip(operation)
	}
}