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
	private var readBuffer = Data()

	private var terminalQueue = DispatchQueue(label: "ws.hbang.Terminal.terminal-queue")

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

	public var scrollbackLines: Int { terminal?.getTopVisibleRow() ?? 0 }

	private var lastCursorLocation: (x: Int, y: Int) = (-1, -1)

	public init() {
		let options = TerminalOptions(termName: "xterm-256color",
																	scrollback: 10000)
		terminal = Terminal(delegate: self, options: options)

		stringSupplier.terminal = terminal

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
		preferencesUpdated()

		startUpdateTimer(fps: 60)

		if UIApplication.shared.supportsMultipleScenes {
			NotificationCenter.default.addObserver(self, selector: #selector(self.sceneDidEnterBackground), name: UIWindowScene.didEnterBackgroundNotification, object: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(self.sceneWillEnterForeground), name: UIWindowScene.willEnterForegroundNotification, object: nil)
		}
		NotificationCenter.default.addObserver(self, selector: #selector(self.appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
	}

	@objc private func preferencesUpdated() {
		let preferences = Preferences.shared
		stringSupplier.colorMap = preferences.colorMap
		stringSupplier.fontMetrics = preferences.fontMetrics

		terminal?.refresh(startRow: 0, endRow: terminal?.rows ?? 0)
	}

	@objc private func sceneDidEnterBackground() {
		// Throttle the update timer to save battery. On iPhone, we shouldn’t be visible at all in this
		// case, so stop updating entirely.
		if UIApplication.shared.supportsMultipleScenes {
			startUpdateTimer(fps: 10)
		} else {
			stopUpdatingTimer()
		}
	}

	@objc private func sceneWillEnterForeground() {
		// Go back to full speed.
		startUpdateTimer(fps: 60)
	}

	@objc private func appWillResignActive() {
		stopUpdatingTimer()
	}

	@objc private func appDidBecomeActive() {
		startUpdateTimer(fps: 60)
	}

	public func terminalWillAppear() {
		// Start updating again.
		startUpdateTimer(fps: 60)
	}

	public func terminalWillDisappear() {
		// Stop updating entirely. We don’t need to if we’re not visible.
		stopUpdatingTimer()
	}

	private func startUpdateTimer(fps: TimeInterval) {
		updateTimer?.invalidate()
		updateTimer = Timer.scheduledTimer(timeInterval: 1 / fps, target: self, selector: #selector(self.updateTimerFired), userInfo: nil, repeats: true)
	}

	private func stopUpdatingTimer() {
		updateTimer?.invalidate()
		updateTimer = nil
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
		readBuffer.append(data)
	}

	@objc private func updateTimerFired() {
		if !readBuffer.isEmpty {
			let bytes = Array<UInt8>(readBuffer)
			terminalQueue.async {
				self.terminal?.feed(byteArray: bytes)
			}
			readBuffer.removeAll()
		}

		guard let cursorLocation = terminal?.getCursorLocation() else {
			return
		}
		if terminal?.getUpdateRange() == nil && cursorLocation == lastCursorLocation {
			return
		}
		terminal?.clearUpdateRange()
		lastCursorLocation = cursorLocation

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
		let actualData = Data(data)
		DispatchQueue.main.async {
			self.subProcess?.write(data: actualData)
		}
	}

	public func bell(source: Terminal) {
		DispatchQueue.main.async {
			self.delegate?.activateBell()
		}
	}

	public func setTerminalTitle(source: Terminal, title: String) {
		DispatchQueue.main.async {
			self.delegate?.titleDidChange(title)
		}
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
