//
//  SubProcess.swift
//  NewTerm
//
//  Created by Adam Demasi on 9/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import Foundation

enum SubProcessIllegalStateError: Error {
	case alreadyStarted, notStarted
	case forkFailed, inSandbox
	case deallocatedWhileRunning
}

enum SubProcessIOError: Error {
	case readFailed, writeFailed
}

protocol SubProcessDelegate: NSObjectProtocol {

	func subProcessDidConnect()
	func subProcess(didReceiveData data: Data)
	func subProcess(didDisconnectWithError error: Error?)
	func subProcess(didReceiveError error: Error)

}

class SubProcess: NSObject {

	private static let newlineData = Data(bytes: "\r\n", count: 2)

	// Simply used to initialize the terminal and thrown away after startup.
	private static let defaultWidth: UInt16 = 80
	private static let defaultHeight: UInt16 = 25

	var delegate: SubProcessDelegate?

	private var childPID: pid_t?
	private var fileDescriptor: Int32?
	public var fileHandle: FileHandle?

	var screenSize: ScreenSize = ScreenSize() {
		didSet {
			if fileDescriptor == nil {
				// we can’t throw from didSet… shrug?
				NSLog("screen size set before subprocess was started")
				return
			}

			var windowSize = winsize()
			windowSize.ws_col = screenSize.width
			windowSize.ws_row = screenSize.height

			if ioctl(fileDescriptor!, TIOCSWINSZ, &windowSize) == -1 {
				NSLog("setting screen size failed: %d: %s", errno, strerror(errno))
				delegate!.subProcess(didReceiveError: SubProcessIOError.writeFailed)
			}
		}
	}

	func start() throws {
		if childPID != nil {
			throw SubProcessIllegalStateError.alreadyStarted
		}

		var windowSize = winsize()
		windowSize.ws_col = SubProcess.defaultWidth
		windowSize.ws_row = SubProcess.defaultHeight

		fileDescriptor = Int32()
		let pid = forkpty(&fileDescriptor!, nil, nil, &windowSize)

		switch pid {
			case -1:
				if errno == EPERM {
					throw SubProcessIllegalStateError.inSandbox
				} else {
					NSLog("fork failed: %d: %s", errno, strerror(errno))
					throw SubProcessIllegalStateError.forkFailed
				}

			case 0:
				// Handle the child subprocess. First try to use /bin/login since it’s a little nicer. Fall
				// back to /bin/bash if that is available.
				let loginArgs = ([ "login", "-fp", NSUserName() ] as NSArray).cStringArray()!
				let bashArgs = ([ "bash", "--login", "-i" ] as NSArray).cStringArray()!

				let env = ([
					"TERM=xterm-color",
					"LANG=en_US.UTF-8",
					"TERM_PROGRAM=NewTerm",
					"LC_TERMINAL=NewTerm"
				] as NSArray).cStringArray()!

				#if !targetEnvironment(simulator)
				_ = attemptStartProcess(path: "/usr/bin/login", arguments: loginArgs, environment: env)
				#endif
				_ = attemptStartProcess(path: "/bin/bash", arguments: bashArgs, environment: env)
				break

			default:
				NSLog("process forked: %d", pid)
				childPID = pid

				fileHandle = FileHandle(fileDescriptor: fileDescriptor!, closeOnDealloc: true)
				NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveData(_:)), name: FileHandle.readCompletionNotification, object: fileHandle)
				fileHandle!.readInBackgroundAndNotify()

				delegate!.subProcessDidConnect()
				break
		}
	}

	func stop() throws {
		if childPID == nil {
			throw SubProcessIllegalStateError.notStarted
		}

		kill(childPID!, SIGKILL)

		var stat = Int32() // unused
		waitpid(childPID!, &stat, WUNTRACED)

		NotificationCenter.default.removeObserver(self, name: FileHandle.readCompletionNotification, object: fileHandle)

		childPID = nil
		fileDescriptor = nil
		fileHandle = nil

		// nil error means disconnected due to user request
		delegate!.subProcess(didDisconnectWithError: nil)
	}

	@objc private func didReceiveData(_ notification: Notification) {
		guard let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data else {
			NSLog("file handle read callback returned nil data")
			return
		}

		if data.isEmpty {
			// zero-length data is an indicator of EOF. this can happen if the user exits the terminal by
			// typing `exit`, or if there’s a catastrophic failure (e.g. /bin/login is broken)
			delegate!.subProcess(didDisconnectWithError: SubProcessIOError.readFailed)
		} else {
			// forward to the delegate and queue another read
			delegate!.subProcess(didReceiveData: data)
			fileHandle!.readInBackgroundAndNotify()
		}
	}

	private func attemptStartProcess(path: String, arguments: UnsafePointer<UnsafeMutablePointer<Int8>?>, environment: UnsafePointer<UnsafeMutablePointer<Int8>?>) -> Int {
		let fileManager = FileManager.default

		if !fileManager.fileExists(atPath: path) {
			return -1
		}

		// Notably, we don't test group or other bits so this still might not always
		// notice if the binary is not executable by us.
		if !fileManager.isExecutableFile(atPath: path) {
			return -1
		}

		if execve(path, arguments, environment) == -1 {
			NSLog("%@: exec failed: %s", path, strerror(errno))
			return -1
		}

		// execve never returns if successful
		return 0
	}

	func write(data: Data) {
		fileHandle!.write(data)
	}

	deinit {
		if childPID != nil {
			NSLog("warning: illegal state — SubProcess deallocated while still running")
		}
	}

}
