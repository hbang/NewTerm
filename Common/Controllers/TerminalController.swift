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

	func refresh(backgroundColor: UIColor)
	func activateBell()
	func close()
	func didReceiveError(error: Error)

	func openSettings()

}

public class TerminalController: VT100 {

	public var delegate: TerminalControllerDelegate?

	private var updateQueue: DispatchQueue!
	private var secondaryUpdateQueue: DispatchQueue!

	let stringSupplier = VT100StringSupplier()

	public var colorMap: VT100ColorMap {
		get { return stringSupplier.colorMap! }
		set { stringSupplier.colorMap = newValue }
	}

	public var fontMetrics: FontMetrics {
		get { return stringSupplier.fontMetrics! }
		set { stringSupplier.fontMetrics = newValue }
	}

	private var subProcess: SubProcess?

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

	func attributedString(forLine line: Int) -> NSAttributedString {
		return stringSupplier.attributedString(forLine: Int32(line))
	}

	// MARK: - Sub Process

	public func startSubProcess() throws {
		subProcess = SubProcess()
		subProcess!.delegate = self
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

		self.delegate?.refresh(backgroundColor: stringSupplier.colorMap!.background)
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
				// this can be the user just typing an EOF (^D) to end the terminal session. treat it as
				// not an error
				// TODO: this should determine if the terminal terminated too soon, and treat it as an error
				// just in case it really is
				delegate?.close()
				return

			case .writeFailed:
				break
			}
		}

		delegate?.didReceiveError(error: error!)
	}

	func subProcess(didReceiveError error: Error) {
		delegate?.didReceiveError(error: error)
	}

}
