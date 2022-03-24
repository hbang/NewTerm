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
	case readFailed(errno: errno_t?)
	case writeFailed(errno: errno_t?)
}

protocol SubProcessDelegate: AnyObject {
	func subProcessDidConnect()
	func subProcess(didReceiveData data: [UTF8Char])
	func subProcess(didDisconnectWithError error: Error?)
	func subProcess(didReceiveError error: Error)
}

class SubProcess {

	weak var delegate: SubProcessDelegate?

	private var childPID: pid_t?
	private var fileDescriptor: Int32?

	private let queue = DispatchQueue(label: "ws.hbang.Terminal.io-queue")
	private var readSource: DispatchSourceRead?
	private var signalSource: DispatchSourceProcess?

	var screenSize = ScreenSize.default {
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
			let args = ["bash", "--login", "-i"].cStringArray
			#else
			let path = "/usr/bin/login"
			let args = ["login", "-fpl\(hushLogin ? "q" : "")", NSUserName()].cStringArray
			#endif

			let env = [
				"TERM=xterm-256color",
				"COLORTERM=truecolor",
				"LANG=\(localeCode)",
				"TERM_PROGRAM=NewTerm",
				"LC_TERMINAL=NewTerm"
			].cStringArray

			defer {
				args.deallocate()
				env.deallocate()
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

			readSource = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor!, queue: queue)
			readSource?.setEventHandler { [weak self] in
				self?.handleRead()
			}
			signalSource = DispatchSource.makeProcessSource(identifier: pid, eventMask: .signal, queue: queue)
			signalSource?.setEventHandler {
				os_log("received signal")
			}

			readSource?.activate()
			signalSource?.activate()
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
		readSource?.cancel()
		readSource = nil
		signalSource?.cancel()
		signalSource = nil

		if !fromError {
			// nil error means disconnected due to user request
			DispatchQueue.main.async {
				self.delegate?.subProcess(didDisconnectWithError: nil)
			}
		}
	}

	private func handleRead() {
		guard let fileDescriptor = fileDescriptor else {
			return
		}

		let buffer = UnsafeMutableRawPointer.allocate(byteCount: Int(BUFSIZ), alignment: MemoryLayout<CChar>.alignment)
		let bytesRead = read(fileDescriptor, buffer, Int(BUFSIZ))
		switch bytesRead {
		case -1:
			let code = errno
			switch code {
			case EAGAIN, EINTR:
				// Ignore, we’ll be called again when the source is ready.
				break

			default:
				// Something is wrong.
				DispatchQueue.main.async {
					self.delegate?.subProcess(didDisconnectWithError: SubProcessIOError.readFailed(errno: code))
				}
			}

		case 0:
			// Zero-length data is an indicator of EOF. This can happen if the user exits the terminal by
			// typing `exit` or ^D, or if there’s a catastrophic failure (e.g. /bin/login is broken).
			try? stop(fromError: false)

		default:
			// Read from output and notify delegate.
			let bytes = buffer.bindMemory(to: UTF8Char.self, capacity: bytesRead)
			let data = Array(UnsafeBufferPointer(start: bytes, count: bytesRead))
			delegate?.subProcess(didReceiveData: data)
		}
		buffer.deallocate()
	}

	func write(data: [UTF8Char]) {
		queue.async {
			guard let fileDescriptor = self.fileDescriptor else {
				return
			}
			_ = data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
				Darwin.write(fileDescriptor, buffer.baseAddress!, buffer.count)
			}
		}
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

	private func updateWindowSize() {
		guard let fileDescriptor = fileDescriptor else {
			return
		}

		var windowSize = winsize()
		windowSize.ws_col = UInt16(screenSize.cols)
		windowSize.ws_row = UInt16(screenSize.rows)

		if ioctl(fileDescriptor, TIOCSWINSZ, &windowSize) == -1 {
			os_log("Setting screen size failed: %{public errno}d", type: .error, errno)
		}
	}

	deinit {
		if childPID != nil {
			os_log("Illegal state - SubProcess deallocated while still running", type: .error)
		}

		try? stop(fromError: true)
	}

}
