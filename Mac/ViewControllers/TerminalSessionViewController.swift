//
//  TerminalSessionViewController.swift
//  NewTerm (macOS)
//
//  Created by Adam Demasi on 20/6/19.
//

import AppKit

class TerminalSessionViewController: NSViewController {

	private var terminalController = TerminalController()

	@IBOutlet var scrollView: NSScrollView!
	@IBOutlet var textView: TerminalTextView!

	// MARK: - NSViewController

	override func viewDidLoad() {
		super.viewDidLoad()

		textView.terminalInputDelegate = terminalController
		terminalController.delegate = self

		do {
			try terminalController.startSubProcess()
		} catch {
			didReceiveError(error: error)
		}
	}

	override func viewWillAppear() {
		super.viewWillAppear()
		view.window!.makeFirstResponder(textView)
	}

	// MARK: - NSResponder

	@discardableResult override func becomeFirstResponder() -> Bool {
		view.window!.makeFirstResponder(textView)
		return false
	}

	@discardableResult override func resignFirstResponder() -> Bool {
		return false
	}

	// MARK: - Callbacks

	func scrollToBottom(animated: Bool = false) {
		if scrollView.verticalScroller!.doubleValue != 0 {
			scrollView.verticalScroller!.doubleValue = 0
		}
	}

	@IBAction override func newWindowForTab(_ sender: Any?) {
		let windowController = storyboard!.instantiateInitialController() as! NSWindowController
		let tabGroup = view.window!.tabGroup!
		tabGroup.addWindow(windowController.window!)
		tabGroup.selectedWindow = windowController.window!
	}

	@IBAction func closeWindow(_ sender: Any?) {
		let tabGroup = view.window!.tabGroup!
		for window in tabGroup.windows {
			window.performClose(sender)
		}
	}

	@IBAction func closeTab(_ sender: Any?) {
		view.window!.performClose(sender)
	}

}

extension TerminalSessionViewController: TerminalControllerDelegate {

	func refresh(attributedString: NSAttributedString, backgroundColor: NSColor) {
		let textViewAttributedString = textView.attributedString() as! NSMutableAttributedString
		textViewAttributedString.setAttributedString(attributedString)

		if backgroundColor != textView.backgroundColor {
			textView.backgroundColor = NSColor.clear
		}

		// TODO: not sure why this is needed all of a sudden? what did i break?
		DispatchQueue.main.async {
			self.scrollToBottom()
		}
	}

	func activateBell() {
		let preferences = Preferences.shared

		if preferences.bellHUD {
			// display the bell HUD, lazily initialising it if it hasn’t been yet
			#warning("TODO")
		}

		if preferences.bellSound {
			NSSound.beep()
		}
	}

	func close() {
		view.window!.performClose(self)
	}

	func didReceiveError(error: Error) {
		let alert = NSAlert(error: error)

		if view.window != nil {
			alert.beginSheetModal(for: view.window!, completionHandler: nil)
		} else {
			alert.runModal()
		}
	}

	func openSettings() {
		// stub
	}

}
