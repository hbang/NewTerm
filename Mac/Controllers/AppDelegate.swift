//
//  AppDelegate.swift
//  NewTerm (macOS)
//
//  Created by Adam Demasi on 20/6/19.
//

import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet var dockMenu: NSMenu!

	func applicationDidFinishLaunching(_ notification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ notification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
		return dockMenu
	}

	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
		if !hasVisibleWindows {
			newWindow(sender)
		}
		return true
	}

	// MARK: - Menu bar

	@IBAction func newWindow(_ sender: Any?) {
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		let windowController = storyboard.instantiateInitialController() as! NSWindowController
		windowController.showWindow(sender)
		windowController.window!.moveTabToNewWindow(sender)
	}

	@IBAction func newWindowForTab(_ sender: Any?) {
		// This can only be called while there are no windows in the responder chain, so we create a
		// new window
		newWindow(sender)
	}

}

