//
//  SubProcess.swift
//  NewTerm
//
//  Created by Adam Demasi on 9/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import Foundation
import os.log

enum SubProcessIllegalStateError: Error {
	case alreadyStarted, notStarted
	case openPtyFailed, forkFailed, inSandbox
	case deallocatedWhileRunning
}

enum SubProcessIOError: Error {
	case readFailed, writeFailed
}

protocol SubProcessDelegate: AnyObject {

	func subProcessDidConnect()
	func subProcess(didReceiveData data: Data)
	func subProcess(didDisconnectWithError error: Error?)
	func subProcess(didReceiveError error: Error)

}

class SubProcess: NSObject {

	weak var delegate: SubProcessDelegate?

	private var childPID: pid_t?
	private var fileDescriptor: Int32?
	private var fileHandle: FileHandle?

	var screenSize: ScreenSize = ScreenSize(width: 80, height: 25) {
		didSet { updateWindowSize() }
	}

	func start() throws {
		if childPID != nil {
			throw SubProcessIllegalStateError.alreadyStarted
		}

		// Initialise the pty
		var windowSize = winsize()
		windowSize.ws_col = UInt16(screenSize.width)
		windowSize.ws_row = UInt16(screenSize.height)

		fileDescriptor = Int32()

		// This must be retrieved before we fork.
		let localeCode = self.localeCode

		
		let pid = forkpty(&fileDescriptor!, nil, nil, &windowSize)
		switch pid {
			case -1:
				if errno == EPERM {
					throw SubProcessIllegalStateError.inSandbox
				} else {
					os_log("Fork failed: %{public}d: %{public}s", type: .error, errno, strerror(errno))
					throw SubProcessIllegalStateError.forkFailed
				}

			case 0:
				// Handle the child subprocess. First try to use /bin/login since it’s a little nicer. Fall
				// back to /bin/bash if that is available.

				#if targetEnvironment(simulator)
				let path = "/bin/bash"
				let args = ([ "bash", "--login", "-i" ] as NSArray).cStringArray()!
				#else
				let path = "/usr/bin/login"
				let args = ([ "login", "-fp", NSUserName() ] as NSArray).cStringArray()!
				#endif

				let env = ([
					"TERM=xterm-256color",
					"LANG=\(localeCode)",
					"TERM_PROGRAM=NewTerm",
					"LC_TERMINAL=NewTerm"
				] as NSArray).cStringArray()!

				defer {
					free(args)
					free(env)
				}

				if execve(path, args, env) == -1 {
					os_log("%{public}@: exec failed: %{public}d: %{public}s", type: .error, path, errno, strerror(errno))
					throw SubProcessIllegalStateError.forkFailed
				}
				break

			default:
				os_log("Process forked: %d", type: .debug, pid)
				childPID = pid

				fileHandle = FileHandle(fileDescriptor: fileDescriptor!, closeOnDealloc: true)
				fileHandle!.readabilityHandler = { [weak self] fileHandle in
					self?.didReceiveData(fileHandle.availableData)
				}

				delegate!.subProcessDidConnect()
				break
		}
	}

	func stop(fromError: Bool = false) throws {
		guard let childPID = childPID else {
			throw SubProcessIllegalStateError.notStarted
		}

		kill(childPID, SIGKILL)

		var stat = Int32() // unused
		waitpid(childPID, &stat, WUNTRACED)

		self.childPID = nil
		fileDescriptor = nil
		fileHandle = nil

		if !fromError {
			// nil error means disconnected due to user request
			DispatchQueue.main.async {
				self.delegate?.subProcess(didDisconnectWithError: nil)
			}
		}
	}

	func write(data: Data) {
		fileHandle?.write(data)
	}

	private var localeCode: String {
		// Try and find a locale suitable for the user. Use en_US.UTF-8 as fallback.
		// TODO: There has to be a better way to get a gettext locale out of the Apple locale. For
		// instance, a phone set to Simplified Chinese but a region of Australia will only have the
		// language zh_AU… which isn’t a thing. But gettext only has languages in country pairs, no
		// safe generic fallbacks exist, like zh-Hans in this case.
		for language in Locale.preferredLanguages {
			let locale = Locale(identifier: language)
			if let languageCode = locale.languageCode, let regionCode = locale.regionCode {
				let identifier = "\(languageCode)_\(regionCode).UTF-8"
				let url = URL(fileURLWithPath: "/usr/share/locale").appendingPathComponent(identifier)
				if (try? url.checkResourceIsReachable()) == true {
					return identifier
				}
			}
		}
		return "en_US.UTF-8"
	}

	private func didReceiveData(_ data: Data) {
		if data.isEmpty {
			// Zero-length data is an indicator of EOF. This can happen if the user exits the terminal by
			// typing `exit` or ^D, or if there’s a catastrophic failure (e.g. /bin/login is broken).
			try? self.stop(fromError: true)
		}

		DispatchQueue.main.async {
			// Forward to the delegate.
			if data.isEmpty {
				self.delegate?.subProcess(didDisconnectWithError: SubProcessIOError.readFailed)
			} else {
				self.delegate?.subProcess(didReceiveData: data)
			}
		}
	}

	private func updateWindowSize() {
		if fileDescriptor == nil {
			return
		}

		var windowSize = winsize()
		windowSize.ws_col = UInt16(screenSize.width)
		windowSize.ws_row = UInt16(screenSize.height)

		if ioctl(fileDescriptor!, TIOCSWINSZ, &windowSize) == -1 {
			os_log("Setting screen size failed: %{public}d: %{public}s", type: .error, errno, strerror(errno))
			delegate!.subProcess(didReceiveError: SubProcessIOError.writeFailed)
		}
	}

	deinit {
		if childPID != nil {
			os_log("Illegal state - SubProcess deallocated while still running", type: .error)
		}

		childPID = nil
		fileHandle = nil
	}

}
