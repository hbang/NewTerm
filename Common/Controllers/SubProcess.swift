//
//  SubProcess.swift
//  NewTerm
//
//  Created by Adam Demasi on 9/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import Foundation
import os.log

enum SubProcessIllegalStateError: Error, LocalizedError {
	case alreadyStarted, notStarted
	case openPtyFailed(errno: errno_t)
	case loginTtyFailed(errno: errno_t)
	case forkFailed(errno: errno_t)
	case deallocatedWhileRunning

	private func errorString(errno: errno_t) -> String {
		if let string = strerror(errno) {
			return String(cString: string)
		}
		return String(format: .localize("Unknown (%i)"), errno)
	}

	var errorDescription: String? {
		switch self {
		case .alreadyStarted, .notStarted, .deallocatedWhileRunning:
			return .localize("Internal state error")

		case .openPtyFailed(let errno):
			return String(format: .localize("Couldn’t initialize a terminal. %@"), errorString(errno: errno))

		case .loginTtyFailed(let errno):
			return String(format: .localize("Couldn’t prepare terminal for logging in. %@"), errorString(errno: errno))

		case .forkFailed(let errno):
			return String(format: .localize("Couldn’t start a terminal process. %@"), errorString(errno: errno))
		}
	}
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

	private static let loginHelper: String = Bundle.main.path(forAuxiliaryExecutable: "NewTermLoginHelper")!

	private static let loginIsShell: Bool = {
		#if targetEnvironment(simulator)
		true
		#else
		// TODO: Temporary workaround for XinaA15
		(try? URL(fileURLWithPath: "/var/Liy/xina").checkResourceIsReachable()) == true
		#endif
	}()

	private static let login: String = {
		#if targetEnvironment(simulator)
		return "/bin/zsh"
		#elseif targetEnvironment(macCatalyst)
		return "/usr/bin/login"
		#else
		// TODO: Temporary workaround for XinaA15
		if loginIsShell {
			return "/var/jb/bin/zsh"
		}
		return ["/var/jb/usr/bin/login", "/usr/bin/login"]
			.first { (try? URL(fileURLWithPath: $0).checkResourceIsReachable()) == true } ?? "/usr/bin/login"
		#endif
	}()

	private static var loginArgv: [String] {
		#if targetEnvironment(simulator)
		return ["zsh", "--login", "-i"]
		#else
		// TODO: Temporary workaround for XinaA15
		if loginIsShell {
			return ["zsh", "--login", "-i"]
		}

		// Interestingly, despite what login(1) seems to imply, it still seems we need to manually
		// handle passing the -q (force hush login) flag. iTerm2 does this, so I guess it’s fine?
		let hushLoginURL = URL(fileURLWithPath: homeDirectory)/".hushlogin"
		let hushLogin = (try? hushLoginURL.checkResourceIsReachable()) == true
		return ["login", "-fp\(hushLogin ? "q" : "")", NSUserName(), loginHelper]
		#endif
	}

	private static let baseEnvp: [String] = [
		"TERM=xterm-256color",
		"COLORTERM=truecolor",
		"TERM_PROGRAM=NewTerm",
		"LC_TERMINAL=NewTerm"
	]

	private static var userPasswd: passwd? {
		let length = sysconf(_SC_GETPW_R_SIZE_MAX)
		let buffer = malloc(length)
		defer { buffer?.deallocate() }

		var pwd = passwd()
		var result: UnsafeMutablePointer<passwd>? = UnsafeMutablePointer<passwd>.allocate(capacity: 1)
		guard ie_getpwuid_r(getuid(), &pwd, buffer, length, &result) == 0 else {
			return nil
		}
		return pwd
	}

	private static var shell: String {
		if let result = userPasswd?.pw_shell {
			return String(cString: result)
		}
		return "/bin/bash"
	}

	private static var homeDirectory: String {
		if let result = userPasswd?.pw_dir {
			return String(cString: result)
		}
		return NSHomeDirectory()
	}

	weak var delegate: SubProcessDelegate?

	private var childPID: pid_t?
	private var fileDescriptor: Int32?

	private let queue = DispatchQueue(label: "ws.hbang.Terminal.io-queue")
	private var readSource: DispatchSourceRead?
	private var signalSource: DispatchSourceProcess?

	private let logger = Logger(subsystem: "ws.hbang.Terminal", category: "SubProcess")

	var screenSize = ScreenSize.default {
		didSet { updateWindowSize() }
	}

	func start(initialDirectory: String? = nil) throws {
		if childPID != nil {
			throw SubProcessIllegalStateError.alreadyStarted
		}

		// Initialise the pty
		var windowSize = screenSize.windowSize
		var fds = (primary: Int32(), replica: Int32())
		if openpty(&fds.primary, &fds.replica, nil, nil, &windowSize) != 0 {
			// Opening pty failed.
			let error = errno
			logger.error("openpty() failed: \(error, format: .darwinErrno)")
			throw SubProcessIllegalStateError.openPtyFailed(errno: error)
		}

		fileDescriptor = fds.primary

		var actions: posix_spawn_file_actions_t!
		posix_spawn_file_actions_init(&actions)
		posix_spawn_file_actions_adddup2(&actions, fds.replica, STDIN_FILENO)
		posix_spawn_file_actions_adddup2(&actions, fds.replica, STDOUT_FILENO)
		posix_spawn_file_actions_adddup2(&actions, fds.replica, STDERR_FILENO)
		defer { posix_spawn_file_actions_destroy(&actions) }

		var attr: posix_spawnattr_t!
		posix_spawnattr_init(&attr)
		defer { posix_spawnattr_destroy(&attr) }
		#if !(targetEnvironment(simulator) || targetEnvironment(macCatalyst))
		if !Self.loginIsShell {
			// Spawn `login` as the super user even in a jailed state, where the rootfs has the
			// nosuid option set.
			posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE)
			posix_spawnattr_set_persona_uid_np(&attr, 0)
			posix_spawnattr_set_persona_gid_np(&attr, 0)
		}
		#endif

		// TODO: At some point, come up with some way to keep track of working directory changes.
		// When opening a new tab, we can switch straight to the previous tab’s working directory.
		let argv: [UnsafeMutablePointer<CChar>?]
		if Self.loginIsShell {
			argv = Self.loginArgv.cStringArray
			chdir(initialDirectory ?? Self.homeDirectory)
		} else {
			argv = (Self.loginArgv + [initialDirectory ?? Self.homeDirectory, Self.shell]).cStringArray
		}
		let envp = (ProcessInfo.processInfo.environment.map { "\($0)=\($1)" } + Self.baseEnvp + [
			"LANG=\(localeCode)"
		]).cStringArray

		defer {
			argv.deallocate()
			envp.deallocate()
		}

		var pid = pid_t()
		let result = ie_posix_spawn(&pid, Self.login, &actions, &attr, argv, envp)
		close(fds.replica)
		if result != 0 {
			// Fork failed.
			close(fds.primary)
			logger.error("posix_spawn() failed: \(result, format: .darwinErrno)")
			throw SubProcessIllegalStateError.forkFailed(errno: result)
		}

		logger.debug("Process forked: \(pid)")
		childPID = pid

		// Go ahead and plug a file handle into the child tty.
		readSource = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor!, queue: queue)
		readSource?.setEventHandler { [weak self] in
			self?.handleRead()
		}
		signalSource = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: queue)
		signalSource?.setEventHandler { [weak self] in
			try? self?.stop()
		}

		readSource?.activate()
		signalSource?.activate()
		delegate!.subProcessDidConnect()
	}

	func stop(fromError: Bool = false) throws {
		guard let childPID = childPID else {
			throw SubProcessIllegalStateError.notStarted
		}

		// If process is still running, send it SIGKILL and wait for termination
		if kill(childPID, 0) == 0 {
			kill(childPID, SIGKILL)

			var status = Int32()
			waitpid(childPID, &status, WUNTRACED)

			logger.debug("Process stopped with exit code: \(WEXITSTATUS(status))")
		}

		if let fileDescriptor = fileDescriptor {
			close(fileDescriptor)
		}

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
				let url = URL(fileURLWithPath: "/usr/share/locale")/identifier
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

		var windowSize = screenSize.windowSize
		if ioctl(fileDescriptor, TIOCSWINSZ, &windowSize) == -1 {
			let error = errno
			logger.error("Setting screen size failed: \(error, format: .darwinErrno)")
		}
	}

	deinit {
		if childPID != nil {
			logger.error("Illegal state - SubProcess deallocated while still running")
		}

		try? stop(fromError: true)
	}

}
