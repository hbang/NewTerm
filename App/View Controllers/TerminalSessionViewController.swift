//
//  TerminalSessionViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit
import AudioToolbox
import os.log
import CoreServices

fileprivate let kSystemSoundID_UserPreferredAlert: SystemSoundID = 0x00001000

class TerminalSessionViewController: UIViewController, TerminalSplitViewControllerChild {

	static let bellSoundID: SystemSoundID = {
		var soundID: SystemSoundID = 0
		if AudioServicesCreateSystemSoundID(Bundle.main.url(forResource: "bell", withExtension: "m4a")! as CFURL, &soundID) == kAudioServicesNoError {
			return soundID
		}
		fatalError("Couldn’t initialise bell sound")
	}()

	var initialCommand: String?

	var isSplitViewResizing = false {
		didSet { updateIsSplitViewResizing() }
	}
	var showsTitleView = false {
		didSet { updateShowsTitleView() }
	}

	private var terminalController = TerminalController()
	private var keyInput = TerminalKeyInput(frame: .zero)
	private var textView = TerminalTextView(frame: .zero, textContainer: nil)
	private var textViewTapGestureRecognizer: UITapGestureRecognizer!

	private var bellHUDView: HUDView?

	private var hasAppeared = false
	private var hasStarted = false
	private var failureError: Error?

	private var lastAutomaticScrollOffset = CGPoint.zero
	private var invertScrollToTop = false

	private var isPickingFileForUpload = false

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		terminalController.delegate = self

		do {
			try terminalController.startSubProcess()
			hasStarted = true
		} catch {
			failureError = error
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		super.loadView()

		title = .localize("TERMINAL", comment: "Generic title displayed before the terminal sets a proper title.")

		textView.delegate = self

		#if !targetEnvironment(macCatalyst)
		textViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTextViewTap(_:)))
		textViewTapGestureRecognizer.delegate = self
		textView.addGestureRecognizer(textViewTapGestureRecognizer)
		#endif

		keyInput.frame = view.bounds
		keyInput.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		keyInput.textView = textView
		keyInput.terminalInputDelegate = terminalController
		view.addSubview(keyInput)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		let passwordImage: UIImage?
		if #available(iOS 14, *) {
			passwordImage = UIImage(systemName: "key.fill")
		} else {
			passwordImage = UIImage(named: "key.fill", in: nil, with: nil)
		}

		addKeyCommand(UIKeyCommand(title: .localize("CLEAR_TERMINAL", comment: "VoiceOver label for a button that clears the terminal."),
															 image: UIImage(systemName: "text.badge.xmark"),
															 action: #selector(self.clearTerminal),
															 input: "k",
															 modifierFlags: .command))

		#if !targetEnvironment(macCatalyst)
		addKeyCommand(UIKeyCommand(title: .localize("PASSWORD_MANAGER", comment: "VoiceOver label for the password manager button."),
															 image: passwordImage,
															 action: #selector(self.activatePasswordManager),
															 input: "f",
															 modifierFlags: [ .command, .alternate ]))
		#endif

		if UIApplication.shared.supportsMultipleScenes {
			NotificationCenter.default.addObserver(self, selector: #selector(self.sceneDidEnterBackground), name: UIWindowScene.didEnterBackgroundNotification, object: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(self.sceneWillEnterForeground), name: UIWindowScene.willEnterForegroundNotification, object: nil)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		becomeFirstResponder()
		terminalController.terminalWillAppear()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		hasAppeared = true

		if let error = failureError {
			didReceiveError(error: error)
		} else {
			if let initialCommand = initialCommand?.data(using: .utf8) {
				terminalController.write(initialCommand + EscapeSequences.return)
			}
		}

		initialCommand = nil
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		resignFirstResponder()
		terminalController.terminalWillDisappear()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		hasAppeared = false
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		updateScreenSize()
	}

	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		updateScreenSize()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateScreenSize()
	}

	override func removeFromParent() {
		if hasStarted {
			do {
				try terminalController.stopSubProcess()
			} catch {
				os_log("Failed to stop subprocess: %@", type: .error, error as NSError)
			}
		}

		super.removeFromParent()
	}

	// MARK: - Screen

	func updateScreenSize() {
		if view.frame.size == .zero || isSplitViewResizing {
			// Not laid out yet. Wait till we are.
			return
		}

		let glyphSize = terminalController.fontMetrics.boundingBox
		if glyphSize.width == 0 || glyphSize.height == 0 {
			fatalError("Failed to get glyph size")
		}

		// Determine the screen size based on the font size
		let width = textView.frame.size.width - textView.safeAreaInsets.left - textView.safeAreaInsets.right
		#if targetEnvironment(macCatalyst)
		let extraHeight: CGFloat = 26
		#else
		let extraHeight: CGFloat = 0
		#endif
		let height = textView.frame.size.height - textView.safeAreaInsets.top - textView.safeAreaInsets.bottom - extraHeight

		if width < 0 || height < 0 {
			// Huh? Let’s just ignore it.
			return
		}

		let size = ScreenSize(cols: UInt(width / glyphSize.width),
													rows: UInt(height / glyphSize.height))
		if terminalController.screenSize != size {
			terminalController.screenSize = size
		}

		let widthRemainder = abs(width.remainder(dividingBy: glyphSize.width))
		let heightRemainder = abs(height.remainder(dividingBy: glyphSize.height))
		textView.contentInset = UIEdgeInsets(top: 0,
																				 left: view.safeAreaInsets.left,
																				 bottom: heightRemainder,
																				 right: view.safeAreaInsets.right + widthRemainder)
		textView.scrollIndicatorInsets = .zero
	}

	@objc func clearTerminal() {
		terminalController.clearTerminal()
	}

	private func updateIsSplitViewResizing() {
		if !isSplitViewResizing {
			updateScreenSize()
		}
	}

	private func updateShowsTitleView() {
		updateScreenSize()
	}

	// MARK: - UIResponder

	@discardableResult override func becomeFirstResponder() -> Bool {
		return keyInput.becomeFirstResponder()
	}

	@discardableResult override func resignFirstResponder() -> Bool {
		return keyInput.resignFirstResponder()
	}

	override var isFirstResponder: Bool {
		return keyInput.isFirstResponder
	}

	// MARK: - Keyboard

	func scrollToBottom(animated: Bool = false) {
		// If the user has scrolled up far enough on their own, don’t rudely scroll them back to the
		// bottom. When they scroll back, the automatic scrolling will continue
		// TODO: Buggy
		// if textView.contentOffset.y < lastAutomaticScrollOffset.y - 20 {
		// 	return
		// }

		// If there is no scrollback, use the top of the scroll view. If there is, calculate the bottom
		var offset = textView.contentOffset
		let bottom = textView.safeAreaInsets.bottom

		offset.y = terminalController.scrollbackLines == 0 ? -textView.safeAreaInsets.top : bottom + textView.contentSize.height - textView.frame.size.height

		// If the offset has changed, update it and our lastAutomaticScrollOffset
		if textView.contentOffset.y != offset.y {
			textView.setContentOffset(offset, animated: animated)
			lastAutomaticScrollOffset = offset
		}
	}

	// MARK: - Gestures

	@objc func handleTextViewTap(_ gestureRecognizer: UITapGestureRecognizer) {
		if gestureRecognizer.state == .ended && !isFirstResponder {
			becomeFirstResponder()
		}
	}

	// MARK: - Lifecycle

	@objc private func sceneDidEnterBackground(_ notification: Notification) {
		if notification.object as? UIWindowScene == view.window?.windowScene {
			terminalController.windowDidEnterBackground()
		}
	}

	@objc private func sceneWillEnterForeground(_ notification: Notification) {
		if notification.object as? UIWindowScene == view.window?.windowScene {
			terminalController.windowWillEnterForeground()
		}
	}

}

extension TerminalSessionViewController: TerminalControllerDelegate {

	func refresh(attributedString: NSAttributedString, backgroundColor: UIColor) {
		textView.attributedText = attributedString

		if backgroundColor != textView.backgroundColor {
			textView.backgroundColor = backgroundColor
		}

		// TODO: Not sure why this is needed all of a sudden? What did I break?
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
			self.scrollToBottom()
		}
	}

	func activateBell() {
		let preferences = Preferences.shared
		if preferences.bellHUD {
			// Display the bell HUD, lazily initialising if it hasn’t been yet.
			if bellHUDView == nil {
				let configuration = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium, scale: .large)
				let image = UIImage(systemName: "bell", withConfiguration: configuration)!
				bellHUDView = HUDView(image: image)
				bellHUDView!.translatesAutoresizingMaskIntoConstraints = false
				view.addSubview(bellHUDView!)

				NSLayoutConstraint.activate([
					bellHUDView!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
					NSLayoutConstraint(item: bellHUDView!,
														 attribute: .centerYWithinMargins,
														 relatedBy: .equal,
														 toItem: view,
														 attribute: .centerYWithinMargins,
														 multiplier: 1 / 3,
														 constant: 0)
				])
			}

			bellHUDView!.animate()
		}

		if preferences.bellVibrate {
			// According to the docs, we should let the feedback generator get deallocated so the
			// Taptic Engine goes back to sleep afterwards. Also according to the docs, we should use the
			// most semantic impact generator, which would be UINotificationFeedbackGenerator, but I think
			// a single tap feels better than two or three. Shrug
			// TODO: Use CoreHaptics for this + the bell sound
			let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
			feedbackGenerator.impactOccurred()
		}

		if preferences.bellSound {
			#if targetEnvironment(macCatalyst)
			AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert)
			#else
			AudioServicesPlaySystemSound(Self.bellSoundID)
			#endif
		}
	}

	func titleDidChange(_ title: String?) {
		self.title = title
	}

	func currentFileDidChange(_ url: URL?, inWorkingDirectory workingDirectoryURL: URL?) {
		#if targetEnvironment(macCatalyst)
		if let windowScene = view.window?.windowScene {
			windowScene.titlebar?.representedURL = url
		}
		#endif
	}

	func saveFile(url: URL) {
		let viewController: UIDocumentPickerViewController
		if #available(iOS 14, *) {
			viewController = UIDocumentPickerViewController(forExporting: [ url ], asCopy: false)
		} else {
			viewController = UIDocumentPickerViewController(url: url, in: .moveToService)
		}
		viewController.delegate = self
		present(viewController, animated: true, completion: nil)
	}

	func fileUploadRequested() {
		isPickingFileForUpload = true

		let viewController: UIDocumentPickerViewController
		if #available(iOS 14, *) {
			viewController = UIDocumentPickerViewController(forOpeningContentTypes: [ .data, .directory ])
		} else {
			viewController = UIDocumentPickerViewController(documentTypes: [ kUTTypeData as String, kUTTypeDirectory as String ], in: .import)
		}
		viewController.delegate = self
		present(viewController, animated: true, completion: nil)
	}

	@objc func activatePasswordManager() {
		keyInput.activatePasswordManager()
	}

	@objc func close() {
		if let splitViewController = parent as? TerminalSplitViewController {
			splitViewController.remove(viewController: self)
		}
	}

	func didReceiveError(error: Error) {
		if !hasAppeared {
			failureError = error
			return
		}
		failureError = nil

		let alertController = UIAlertController(title: .localize("TERMINAL_LAUNCH_FAILED_TITLE", comment: "Alert title displayed when a terminal could not be launched."),
																						message: .localize("TERMINAL_LAUNCH_FAILED_BODY", comment: "Alert body displayed when a terminal could not be launched."),
																						preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: .ok, style: .cancel, handler: nil))
		present(alertController, animated: true, completion: nil)
	}

}

extension TerminalSessionViewController: UITextViewDelegate {

	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		// Hide toolbar popups if visible
		keyInput.setMoreRowVisible(false, animated: true)
	}

	func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
		// If we’re at the top of the scroll view, guess that the user wants to go back to the bottom
		if scrollView.contentOffset.y <= (scrollView.frame.size.height - scrollView.safeAreaInsets.top - scrollView.safeAreaInsets.bottom) / 2 {
			// Wrapping in an animate block as a hack to avoid strange content inset issues, unfortunately
			UIView.animate(withDuration: 0.5) {
				self.scrollToBottom(animated: true)
			}
			return false
		}
		return true
	}

	func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
		// Since the scroll view is at {0, 0}, it won’t respond to scroll to top events till the next
		// scroll. Trick it by scrolling 1 physical pixel up.
		scrollView.contentOffset.y -= CGFloat(1) / UIScreen.main.scale
	}

}

extension TerminalSessionViewController: UIGestureRecognizerDelegate {

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		// This allows the tap-to-activate-keyboard gesture to work without conflicting with UIKit’s
		// internal text view/scroll view gestures… as much as we can avoid conflicting, at least.
		return gestureRecognizer == textViewTapGestureRecognizer
			&& (!(otherGestureRecognizer is UITapGestureRecognizer) || isFirstResponder)
	}

}

extension TerminalSessionViewController: UIDocumentPickerDelegate {

	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard isPickingFileForUpload,
					let url = urls.first else {
			return
		}
		terminalController.uploadFile(url: url)
		isPickingFileForUpload = false
	}

	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		if isPickingFileForUpload {
			isPickingFileForUpload = false
			terminalController.cancelUploadRequest()
		} else {
			// The system will clean up the temp directory for us eventually anyway, but still delete the
			// downloads temp directory now so the file doesn’t linger around till then.
			terminalController.deleteDownloadCache()
		}
	}

}
