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
import SwiftTerm

public protocol TerminalControllerDelegate: AnyObject {

	func refresh(attributedString: NSAttributedString, backgroundColor: UIColor)
	func activateBell()
	func titleDidChange(_ title: String?)

	func close()
	func didReceiveError(error: Error)

	func openSettings()

}

public class TerminalController {

	public weak var delegate: TerminalControllerDelegate?

	private var updateTimer: Timer?

	private var stringSupplier = StringSupplier()

	public var colorMap: ColorMap {
		get { return stringSupplier.colorMap! }
		set { stringSupplier.colorMap = newValue }
	}

	public var fontMetrics: FontMetrics {
		get { return stringSupplier.fontMetrics! }
		set { stringSupplier.fontMetrics = newValue }
	}

	private var terminal: Terminal?
	private var subProcess: SubProcess?
	private var processLaunchDate: Date?
	private var cursorDirty = false

	public var screenSize: ScreenSize? {
		didSet {
			// Send the terminal the actual size of our vt100 view. This should be called any time we
			// change the size of the view. This should be a no-op if the size has not changed since the
			// last time we called it.
			if let screenSize = screenSize {
				subProcess?.screenSize = screenSize
				terminal?.resize(cols: Int(screenSize.width),
												 rows: Int(screenSize.height))
			}
		}
	}

	public var scrollbackLines: Int { (terminal?.rows ?? 0) - (terminal?.getTopVisibleRow() ?? 0) }

	public init() {
		let options = TerminalOptions(termName: "xterm-256color",
																	scrollback: 1000)
		terminal = Terminal(delegate: self, options: options)

		stringSupplier.terminal = terminal

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
		preferencesUpdated()

		updateTimer = Timer.scheduledTimer(timeInterval: 1 / 60, target: self, selector: #selector(self.updateTimerFired), userInfo: nil, repeats: true)
	}

	@objc func preferencesUpdated() {
		let preferences = Preferences.shared
		stringSupplier.colorMap = preferences.colorMap
		stringSupplier.fontMetrics = preferences.fontMetrics

		terminal?.refresh(startRow: 0, endRow: terminal?.rows ?? 0)
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

	// MARK: - Terminal

	public func readInputStream(_ data: Data) {
		let bytes = Array<UInt8>(data)
		terminal?.feed(byteArray: bytes)
		cursorDirty = true
	}

	@objc private func updateTimerFired() {
		if terminal?.getUpdateRange() == nil || !cursorDirty {
			return
		}
		terminal?.clearUpdateRange()

		// TODO: We should handle the scrollback separately so it only appears if the user scrolls
		self.delegate?.refresh(attributedString: stringSupplier.attributedString(),
													 backgroundColor: stringSupplier.colorMap!.background)
	}

	// MARK: - Object lifecycle

	deinit {
		updateTimer?.invalidate()
	}

}

extension TerminalController: TerminalDelegate {

	public func send(source: Terminal, data: ArraySlice<UInt8>) {
		subProcess?.write(data: Data(data))
	}

	public func bell(source: Terminal) {
		delegate?.activateBell()
	}

	public func sizeChanged(source: Terminal) {
		// TODO
//		let screenSize = ScreenSize(width: UInt16(source.cols),
//																height: UInt16(source.rows))
//		if self.screenSize != screenSize {
//			self.screenSize = screenSize
//		}
	}

	public func setTerminalTitle(source: Terminal, title: String) {
		delegate?.titleDidChange(title)
	}

}

extension TerminalController: TerminalInputProtocol {

	public var applicationCursor: Bool { terminal?.applicationCursor ?? false }

	public func receiveKeyboardInput(data: Data) {
		// Forward the data from the keyboard directly to the subprocess
		subProcess!.write(data: data)
	}

	public func openSettings() {
		delegate!.openSettings()
	}

}

extension TerminalController: SubProcessDelegate {

	func subProcessDidConnect() {
		// Yay
	}

	func subProcess(didReceiveData data: Data) {
		// Simply forward the input stream down the VT100 processor. When it notices changes to the
		// screen, it should invoke our refresh delegate below.
		readInputStream(data)
	}

	func subProcess(didDisconnectWithError error: Error?) {
		if error == nil {
			// Graceful termination
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

		updateTimer?.invalidate()
		updateTimer = nil
		updateTimerFired()
	}

	func subProcess(didReceiveError error: Error) {
		delegate?.didReceiveError(error: error)
	}

}
