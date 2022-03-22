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
	case openPtyFailed, forkFailed(errno: Int32)
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

	var screenSize: ScreenSize = ScreenSize(cols: 80, rows: 25) {
		didSet { updateWindowSize() }
	}

	func start() throws {
		if childPID != nil {
			throw SubProcessIllegalStateError.alreadyStarted
		}

		// Initialise the pty
		var windowSize = winsize()
		windowSize.ws_col = UInt16(screenSize.cols)
		windowSize.ws_row = UInt16(screenSize.rows)

		fileDescriptor = Int32()

		// This must be retrieved before we fork.
		let localeCode = self.localeCode

		// Interestingly, despite what login(1) seems to imply, it still seems we need to manually
		// handle passing the -q (force hush login) flag. iTerm2 does this, so I guess it’s fine?
		let hushLoginURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".hushlogin")
		let hushLogin = (try? hushLoginURL.checkResourceIsReachable()) == true

		let pid = forkpty(&fileDescriptor!, nil, nil, &windowSize)
		switch pid {
		case -1:
			// Fork failed.
			let error = errno
			os_log("Fork failed: %{public errno}d", type: .error, error)
			throw SubProcessIllegalStateError.forkFailed(errno: error)

		case 0:
			// We’re in the fork. Execute the login shell.
			// TODO: At some point, come up with some way to keep track of working directory changes.
			// When opening a new tab, we can switch straight to the previous tab’s working directory.
			chdir(NSHomeDirectory())

#if targetEnvironment(simulator)
			let path = "/bin/bash"
			let args = ([ "bash", "--login", "-i" ] as NSArray).cStringArray()!
#else
			let path = "/usr/bin/login"
			let args = ([ "login", "-fpl\(hushLogin ? "q" : "")", NSUserName() ] as NSArray).cStringArray()!
#endif

			let env = ([
				"TERM=xterm-256color",
				"COLORTERM=truecolor",
				"LANG=\(localeCode)",
				"TERM_PROGRAM=NewTerm",
				"LC_TERMINAL=NewTerm"
			] as NSArray).cStringArray()!

			defer {
				free(args)
				free(env)
			}

			if execve(path, args, env) == -1 {
				let error = errno
				os_log("%{public}@: exec failed: %{public errno}d", type: .error, path, error)
				throw SubProcessIllegalStateError.forkFailed(errno: error)
			}
			break

		default:
			// We’re in the parent process. We can go ahead and plug a file handle into the child tty.
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
		var languages = Locale.preferredLanguages
		let preferredLocale = Preferences.shared.preferredLocale
		if preferredLocale != "",
			 Locale(identifier: preferredLocale).languageCode != nil {
			languages.insert(preferredLocale, at: 0)
		}

		for language in languages {
			let locale = Locale(identifier: language)
			if let languageCode = locale.languageCode,
				 let regionCode = locale.regionCode {
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
		windowSize.ws_col = UInt16(screenSize.cols)
		windowSize.ws_row = UInt16(screenSize.rows)

		if ioctl(fileDescriptor!, TIOCSWINSZ, &windowSize) == -1 {
			os_log("Setting screen size failed: %{public errno}d", type: .error, errno)
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
