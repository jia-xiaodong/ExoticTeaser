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

class ViewController: NSViewController {

	// [jxd] important!
	// must define it to avoid app to read XIB file
	override func loadView()
	{
		/*
		create a root view.
		We'll attach a layer to it thereafter.
		*/
		self.view = AVView(frame: NSMakeRect(0, 0, 50, 50))

		// a local monitor must be added explicitly to make a NSView to accept Key event. Because my NSWindow
		// doesn't have Title Bar.
		NSEvent .addLocalMonitorForEventsMatchingMask(.KeyDownMask, handler: { event -> NSEvent? in
			self.view.keyDown(event)
			return event
		})
	}
	
	var playerLayer: AVPlayerLayer?
	
	override func viewDidLoad() {
		super.viewDidLoad()

		srandom(UInt32(time(nil)))
		
		// attach an AVPlayerLayer to root view
		let playerItem = chooseRandomClip()
		let player = AVPlayer(playerItem: playerItem)
		playerItem.addObserver(self, forKeyPath: "status", options: .New, context: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
		                                                 selector: #selector(chooseRandomClip),
		                                                 name: AVPlayerItemDidPlayToEndTimeNotification,
		                                                 object: nil)
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

	//! choose a random movie clip
	var randomClip: NSURL? {
		do {
			return try teasers.next()
		} catch {
			return nil
		}
	}

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
	
	func chooseRandomClip() -> AVPlayerItem {
		let playItem = createTransparentItem(randomClip!)
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
}