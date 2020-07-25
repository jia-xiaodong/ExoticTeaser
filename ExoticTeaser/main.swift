//
//  main.swift
//  ExoticTeaser
//
//  Created by jia xiaodong on 7/24/20.
//  Copyright © 2020 homemade. All rights reserved.
//

import Cocoa

let delegate = AppDelegate() //alloc main app's delegate class
NSApplication.sharedApplication().delegate = delegate //set as app's delegate

//! start of run loop
// NSApplicationMain(C_ARGC, C_ARGV) // Old version
NSApplicationMain(Process.argc, Process.unsafeArgv)
