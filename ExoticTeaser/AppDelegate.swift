//
//  AppDelegate.swift
//  ExoticTeaser
//
//  Created by jia xiaodong on 7/24/20.
//  Copyright © 2020 homemade. All rights reserved.
//

import Cocoa

//@NSApplicationMain	// [jxd] commented to force compiler to use customed "NSApplicationMain" (in main.swift)
class AppDelegate: NSObject, NSApplicationDelegate {
	var window: NSWindow?
	var viewController: ViewController?

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		window = NSWindow(contentRect: NSMakeRect(10, 10, 300, 300),
		                  styleMask: NSBorderlessWindowMask, // NSTitledWindowMask: a title bark can let you drag window
		                  backing: .Buffered,
		                  defer: false)
		viewController = ViewController()
		let content = window!.contentView! as NSView // window!.contentView: what is it now?
		content.addSubview(viewController!.view)
		
		// [debug] because I have only one window and only one View, so no need to explicitly make first responder.
		/*
		let ret = window?.makeFirstResponder(viewController!.view)
		let ret2 = viewController!.view.becomeFirstResponder()
		*/
		window!.makeKeyAndOrderFront(nil)

		// make it transparent
		window!.opaque = false
		window!.backgroundColor = NSColor.clearColor()
		
		// TODO: commandline parameter to specify a root directory, a movie filename.
		/*
		let args = NSProcessInfo.processInfo().arguments
		*/
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
}

