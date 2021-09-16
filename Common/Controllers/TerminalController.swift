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
	func currentFileDidChange(_ url: URL?, inWorkingDirectory workingDirectoryURL: URL?)

	func saveFile(url: URL)
	func fileUploadRequested()

	func close()
	func didReceiveError(error: Error)

}

public class TerminalController {

	public weak var delegate: TerminalControllerDelegate?

	public var colorMap: ColorMap {
		get { return stringSupplier.colorMap! }
		set { stringSupplier.colorMap = newValue }
	}
	public var fontMetrics: FontMetrics {
		get { return stringSupplier.fontMetrics! }
		set { stringSupplier.fontMetrics = newValue }
	}

	internal var terminal: Terminal?
	private var subProcess: SubProcess?
	private let stringSupplier = StringSupplier()

	private var processLaunchDate: Date?
	private var updateTimer: Timer?
	private var refreshRate: TimeInterval = 60
	private var isVisible = true
	private var readBuffer = Data()

	internal var terminalQueue = DispatchQueue(label: "ws.hbang.Terminal.terminal-queue")

	public var screenSize: ScreenSize? {
		didSet { updateScreenSize() }
	}
	public var scrollbackLines: Int { terminal?.getTopVisibleRow() ?? 0 }

	private var lastCursorLocation: (x: Int, y: Int) = (-1, -1)
	private var lastBellDate: Date?

	internal var title: String?
	internal var userAndHostname: String?
	internal var user: String?
	internal var hostname: String?
	internal var isLocalhost: Bool { hostname == nil || hostname == ProcessInfo.processInfo.hostName }
	internal var currentWorkingDirectory: URL?
	internal var currentFile: URL?

	internal var iTermIntegrationVersion: String?
	internal var shell: String?

	public init() {
		let options = TerminalOptions(termName: "xterm-256color",
																	scrollback: 10000)
		terminal = Terminal(delegate: self, options: options)

		stringSupplier.terminal = terminal

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
		preferencesUpdated()

		startUpdateTimer(fps: refreshRate)

		#if os(iOS)
		NotificationCenter.default.addObserver(self, selector: #selector(self.appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		#endif

		if #available(macOS 12, *) {
			NotificationCenter.default.addObserver(self, selector: #selector(self.powerStateChanged), name: .NSProcessInfoPowerStateDidChange, object: nil)
		}
	}

	@objc private func preferencesUpdated() {
		let preferences = Preferences.shared
		stringSupplier.colorMap = preferences.colorMap
		stringSupplier.fontMetrics = preferences.fontMetrics

		powerStateChanged()
		terminal?.refresh(startRow: 0, endRow: terminal?.rows ?? 0)
	}

	@objc private func powerStateChanged() {
		let preferences = Preferences.shared
		if #available(macOS 12, *),
			 ProcessInfo.processInfo.isLowPowerModeEnabled && preferences.reduceRefreshRateInLPM {
			refreshRate = 15
		} else {
			refreshRate = TimeInterval(min(preferences.refreshRate, UIScreen.main.maximumFramesPerSecond))
		}
		if isVisible {
			startUpdateTimer(fps: refreshRate)
		}
	}

	public func windowDidEnterBackground() {
		// Throttle the update timer to save battery. On iPhone, we shouldn’t be visible at all in this
		// case, so stop updating entirely.
		if UIApplication.shared.supportsMultipleScenes {
			startUpdateTimer(fps: 10)
		} else {
			stopUpdatingTimer()
		}
		isVisible = false
	}

	public func windowWillEnterForeground() {
		// Go back to full speed.
		startUpdateTimer(fps: refreshRate)
		isVisible = true
	}

	@objc private func appWillResignActive() {
		stopUpdatingTimer()
		isVisible = false
	}

	@objc private func appDidBecomeActive() {
		startUpdateTimer(fps: refreshRate)
		isVisible = true
	}

	public func terminalWillAppear() {
		// Start updating again.
		startUpdateTimer(fps: refreshRate)
		isVisible = true
	}

	public func terminalWillDisappear() {
		// Stop updating entirely. We don’t need to if we’re not visible.
		stopUpdatingTimer()
		isVisible = false
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

	internal func write(_ data: Data) {
		subProcess?.write(data: data)
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
		delegate?.refresh(attributedString: stringSupplier.attributedString(),
											backgroundColor: stringSupplier.colorMap!.background)
	}

	public func clearTerminal() {
		terminal?.resetToInitialState()
	}

	private func updateScreenSize() {
		if let screenSize = screenSize,
			 let terminal = terminal,
			 screenSize.cols != terminal.cols || screenSize.rows != terminal.rows {
			subProcess?.screenSize = screenSize
			terminal.resize(cols: Int(screenSize.cols),
											rows: Int(screenSize.rows))
		}
	}

	private func updateTitle() {
		var newTitle: String? = nil
		if let title = title,
			 !title.isEmpty {
			newTitle = title
		}
		if let hostname = hostname {
			let user = self.user == NSUserName() ? nil : self.user
			let cleanedHostname = hostname.replacingOccurrences(of: "\\.local$", with: "", options: .regularExpression, range: hostname.startIndex..<hostname.endIndex)
			let hostString: String
			if isLocalhost {
				hostString = user ?? ""
			} else {
				hostString = "\(user ?? "")\(user == nil ? "" : "@")\(cleanedHostname)"
			}
			if !hostString.isEmpty {
				newTitle = "[\(hostString)] \(newTitle ?? "")"
			}
		}
		self.delegate?.titleDidChange(newTitle)
	}

	// MARK: - Object lifecycle

	deinit {
		updateTimer?.invalidate()
	}

}

extension TerminalController: TerminalDelegate {

	public func isProcessTrusted(source: Terminal) -> Bool { isLocalhost }

	public func send(source: Terminal, data: ArraySlice<UInt8>) {
		let actualData = Data(data)
		DispatchQueue.main.async {
			self.write(actualData)
		}
	}

	public func bell(source: Terminal) {
		DispatchQueue.main.async {
			// Throttle bell so it only rings a maximum of once a second.
			if self.lastBellDate == nil || self.lastBellDate! < Date(timeIntervalSinceNow: -1) {
				self.lastBellDate = Date()
				self.delegate?.activateBell()
			}
		}
	}

	public func setTerminalTitle(source: Terminal, title: String) {
		self.title = title
		DispatchQueue.main.async {
			self.updateTitle()
		}
	}

	public func hostCurrentDirectoryUpdated(source: Terminal) {
		hostCurrentDocumentUpdated(source: source)
	}

	public func hostCurrentDocumentUpdated(source: Terminal) {
		let workingDirectory = source.hostCurrentDirectory
		let filePath = source.hostCurrentDocument ?? workingDirectory
		currentWorkingDirectory = nil
		currentFile = nil

		if let workingDirectory = workingDirectory,
			 let url = URL(string: workingDirectory),
			 url.isFileURL {
			hostname = url.host
			if isLocalhost {
				currentWorkingDirectory = url
			}
		}

		if let filePath = filePath,
			 let url = URL(string: filePath),
			 url.isFileURL {
			hostname = url.host
			if isLocalhost {
				currentFile = url
			}
		}

		DispatchQueue.main.async {
			self.delegate?.currentFileDidChange(self.currentFile ?? self.currentWorkingDirectory,
																					inWorkingDirectory: self.currentWorkingDirectory)
		}
	}

}

extension TerminalController: TerminalInputProtocol {

	public var applicationCursor: Bool { terminal?.applicationCursor ?? false }

	public func receiveKeyboardInput(data: Data) {
		// Forward the data from the keyboard directly to the subprocess
		subProcess!.write(data: data)
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
		let cols = Int(subProcess?.screenSize.cols ?? 0)
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
