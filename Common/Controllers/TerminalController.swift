//
//  TerminalController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public protocol TerminalControllerDelegate {

	func refresh(attributedString: NSAttributedString, backgroundColor: Color)
	func activateBell()
	func close()
	func didReceiveError(error: Error)

	func openSettings()

}

public class TerminalController: VT100 {

	public var delegate: TerminalControllerDelegate?

	private var updateQueue: DispatchQueue!
	private var secondaryUpdateQueue: DispatchQueue!

	private var stringSupplier = VT100StringSupplier()

	public var colorMap: VT100ColorMap {
		get { return stringSupplier.colorMap! }
		set { stringSupplier.colorMap = newValue }
	}

	public var fontMetrics: FontMetrics {
		get { return stringSupplier.fontMetrics! }
		set { stringSupplier.fontMetrics = newValue }
	}

	private var subProcess: SubProcess?
	private var processLaunchDate: Date?

	override public var screenSize: ScreenSize {
		get { return super.screenSize }

		set {
			super.screenSize = newValue

			// Send the terminal the actual size of our vt100 view. This should be called any time we
			// change the size of the view. This should be a no-op if the size has not changed since the
			// last time we called it.
			subProcess?.screenSize = screenSize
		}
	}

	public override init() {
		super.init()

		updateQueue = DispatchQueue(label: String(format: "au.com.hbang.NewTerm.update-queue-%p", self))
		secondaryUpdateQueue = DispatchQueue(label: String(format: "au.com.hbang.NewTerm.update-queue-secondary-%p", self))

		stringSupplier.screenBuffer = self

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
		preferencesUpdated()
	}

	@objc func preferencesUpdated() {
		let preferences = Preferences.shared
		stringSupplier.colorMap = preferences.colorMap
		stringSupplier.fontMetrics = preferences.fontMetrics!

		refresh()
	}

	// MARK: - Sub Process

	public func startSubProcess() throws {
		subProcess = SubProcess()
		subProcess!.delegate = self
		processLaunchDate = Date()
		try subProcess!.start()
	}

	public func stopSubProcess() throws {
		try subProcess!.stop()
	}

}

extension TerminalController: TerminalInputProtocol {

	public func receiveKeyboardInput(data: Data) {
		// Forward the data from the keyboard directly to the subprocess
		subProcess!.write(data: data)
	}

	public func openSettings() {
		delegate!.openSettings()
	}

}

// ScreenBufferRefreshDelegate
extension TerminalController {

	override public func refresh() {
		super.refresh()

		// TODO: this is called due to -[VT100 init], and we aren’t ready yet… we’ll be called when we
		// are anyway, so don’t worry about it
		if updateQueue == nil {
			return
		}

		// TODO: we should handle the scrollback separately so it only appears if the user scrolls
		DispatchQueue.main.async {
			let attributedString = self.stringSupplier.attributedString()!
			let backgroundColor = self.stringSupplier.colorMap!.background!

			// DispatchQueue.main.async {
				self.delegate?.refresh(attributedString: attributedString, backgroundColor: backgroundColor)

				// self.secondaryUpdateQueue.async {
				// 	self.stringSupplier.detectLinks(for: attributedString)

				// 	DispatchQueue.main.async {
				// 		self.delegate?.refresh(attributedString: attributedString, backgroundColor: backgroundColor)
				// 	}
				// }
			// }
		}
	}

	override public func activateBell() {
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
		if error == nil {
			// graceful termination
			return
		}

		if let ioError = error as? SubProcessIOError {
			switch ioError {
			case .readFailed:
				// This can be the user just typing an EOF (^D) to end the terminal session. However, it
				// can also happen because the process crashed for some reason. If it seems like the shell
				// exited gracefully, just close the tab.
				if (processLaunchDate ?? Date()) < Date(timeIntervalSinceNow: -3) {
					delegate?.close()
				}
				break

			case .writeFailed:
				break
			}
		}

		delegate?.didReceiveError(error: error!)

		// Write the termination message to the terminal.
		let processCompleted = NSLocalizedString("PROCESS_COMPLETED_TITLE", comment: "Title displayed when the terminal’s process has ended.")
		let cols = Int(subProcess?.screenSize.width ?? 0)
		let messageLength = processCompleted.count + 2
		let divider = String(repeating: "═", count: max((cols - messageLength) / 2, 0))
		let message = "\r\n\u{1b}[0;31m\(divider) \u{1b}[1;31m\(processCompleted)\u{1b}[0;31m \(divider)\u{1b}[m\r\n"
		readInputStream(message.data(using: .utf8)!)
	}

	func subProcess(didReceiveError error: Error) {
		delegate?.didReceiveError(error: error)
	}

}
