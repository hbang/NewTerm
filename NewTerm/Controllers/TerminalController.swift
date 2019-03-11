//
//  TerminalController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

protocol TerminalControllerDelegate {

	func refresh(attributedString: NSAttributedString, backgroundColor: UIColor)
	func activateBell()
	func close()
	func didReceiveError(error: Error)

	func openSettings()

}

class TerminalController: VT100 {

	var delegate: TerminalControllerDelegate?

	private var updateQueue: DispatchQueue!
	private var secondaryUpdateQueue: DispatchQueue!

	private var stringSupplier = VT100StringSupplier()

	var colorMap: VT100ColorMap {
		get { return stringSupplier.colorMap! }
		set { stringSupplier.colorMap = newValue }
	}

	var fontMetrics: FontMetrics {
		get { return stringSupplier.fontMetrics! }
		set { stringSupplier.fontMetrics = newValue }
	}

	private var subProcess: SubProcess?
	private var processEnded: Bool = false

	override var screenSize: ScreenSize {
		get { return super.screenSize }

		set {
			super.screenSize = newValue

			// Send the terminal the actual size of our vt100 view. This should be called any time we
			// change the size of the view. This should be a no-op if the size has not changed since the
			// last time we called it.
			subProcess?.screenSize = screenSize
		}
	}

	override init() {
		super.init()

		updateQueue = DispatchQueue(label: String(format: "au.com.hbang.NewTerm.update-queue-%p", self))
		secondaryUpdateQueue = DispatchQueue(label: String(format: "au.com.hbang.NewTerm.update-queue-secondary-%p", self))

		stringSupplier.screenBuffer = self

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: UserDefaults.didChangeNotification, object: nil)
		preferencesUpdated()
	}

	@objc func preferencesUpdated() {
		let preferences = Preferences.shared
		stringSupplier.colorMap = preferences.colorMap
		stringSupplier.fontMetrics = preferences.fontMetrics

		refresh()
	}

	// MARK: - Sub Process

	func startSubProcess() throws {
		processEnded = false

		subProcess = SubProcess()
		subProcess!.delegate = self
		try subProcess!.start()
	}

	func stopSubProcess() throws {
		processEnded = true
		try subProcess!.stop()
	}

}

extension TerminalController: TerminalInputProtocol {

	func receiveKeyboardInput(data: Data) {
		if processEnded {
			// we’ve told the user that pressing a key will close the tab, so close the tab
			delegate!.close()
		} else {
			// Forward the data from the keyboard directly to the subprocess
			subProcess!.write(data: data)
		}
	}

	func openSettings() {
		delegate!.openSettings()
	}

}

// ScreenBufferRefreshDelegate
extension TerminalController {

	override func refresh() {
		super.refresh()

		// TODO: this is called due to -[VT100 init], and we aren’t ready yet… we’ll be called when we
		// are anyway, so don’t worry about it
		if updateQueue == nil {
			return
		}

		// TODO: we should handle the scrollback separately so it only appears if the user scrolls
		updateQueue.async {
			let attributedString = self.stringSupplier.attributedString()!
			let backgroundColor = self.stringSupplier.colorMap!.background!

			DispatchQueue.main.async {
				self.delegate?.refresh(attributedString: attributedString, backgroundColor: backgroundColor)

				// self.secondaryUpdateQueue.async {
				// 	self.stringSupplier.detectLinks(for: attributedString)

				// 	DispatchQueue.main.async {
				// 		self.delegate?.refresh(attributedString: attributedString, backgroundColor: backgroundColor)
				// 	}
				// }
			}
		}
	}

	override func activateBell() {
		super.activateBell()
		delegate?.activateBell()
	}

}

extension TerminalController: SubProcessDelegate {

	func subProcessDidConnect() {
		// yay
	}

	func subProcess(didReceiveData data: Data) {
		// Simply forward the input stream down the VT100 processor. When it notices changes to the
		// screen, it should invoke our refresh delegate below.
		readInputStream(data)
	}

	func subProcess(didDisconnectWithError error: Error?) {
		// we have nothing useful to do if the process has already ended
		if processEnded {
			return
		}

		processEnded = true

		// show a message inside the terminal indicating that the session has ended, and that the user
		// can press any key to close the tab
		let message = "[\(NSLocalizedString("PROCESS_COMPLETED_TITLE", comment: ""))]\r\n\(NSLocalizedString("PROCESS_COMPLETED_MESSAGE", comment: ""))"
		readInputStream(message.data(using: .utf8))
	}

	func subProcess(didReceiveError error: Error) {
		NSLog("subprocess received error… %@", error as NSError)
		delegate?.didReceiveError(error: error)
	}

}
