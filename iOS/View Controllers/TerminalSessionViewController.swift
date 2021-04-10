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

fileprivate let kSystemSoundID_UserPreferredAlert: SystemSoundID = 0x00001000

class TerminalSessionViewController: UIViewController {

	static let bellSoundID: SystemSoundID = {
		var soundID: SystemSoundID = 0
		if AudioServicesCreateSystemSoundID(Bundle.main.url(forResource: "bell", withExtension: "m4a")! as CFURL, &soundID) == kAudioServicesNoError {
			return soundID
		}
		fatalError("Couldn’t initialise bell sound")
	}()

	private var terminalController = TerminalController()
	private var keyInput = TerminalKeyInput(frame: .zero)
	private var textView = TerminalTextView(frame: .zero, textContainer: nil)
	private var textViewTapGestureRecognizer: UITapGestureRecognizer!

	private lazy var bellHUDView: HUDView = {
		let configuration = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium, scale: .large)
		let image = UIImage(systemName: "bell", withConfiguration: configuration)!
		let bellHUDView = HUDView(image: image)
		bellHUDView.translatesAutoresizingMaskIntoConstraints = false
		return bellHUDView
	}()

	private var hasAppeared = false
	private var hasStarted = false
	private var keyboardVisible = false
	private var failureError: Error?

	private var keyboardHeight: CGFloat = 0
	private var lastAutomaticScrollOffset = CGPoint.zero
	private var invertScrollToTop = false

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		setUp()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUp()
	}

	func setUp() {
		terminalController.delegate = self

		do {
			try terminalController.startSubProcess()
			hasStarted = true
		} catch {
			failureError = error
		}
	}

	override func loadView() {
		super.loadView()

		title = NSLocalizedString("TERMINAL", comment: "Generic title displayed before the terminal sets a proper title.")

		textView.showsVerticalScrollIndicator = false
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

		addKeyCommand(UIKeyCommand(title: NSLocalizedString("CLEAR_TERMINAL", comment: "VoiceOver label for a button that clears the terminal."),
															 image: UIImage(systemName: "text.badge.xmark"),
															 action: #selector(self.clearTerminal),
															 input: "k",
															 modifierFlags: .command))

		#if !targetEnvironment(macCatalyst)
		addKeyCommand(UIKeyCommand(title: NSLocalizedString("PASSWORD_MANAGER", comment: "VoiceOver label for the password manager button."),
															 image: passwordImage,
															 action: #selector(self.activatePasswordManager),
															 input: "f",
															 modifierFlags: [ .command, .alternate ]))
		#endif

		if #available(iOS 13.4, *) {
			// Handled by TerminalKeyInput
		} else {
			addKeyCommand(UIKeyCommand(input: UIKeyCommand.inputUpArrow,    modifierFlags: [], action: #selector(TerminalKeyInput.upKeyPressed)))
			addKeyCommand(UIKeyCommand(input: UIKeyCommand.inputDownArrow,  modifierFlags: [], action: #selector(TerminalKeyInput.downKeyPressed)))
			addKeyCommand(UIKeyCommand(input: UIKeyCommand.inputLeftArrow,  modifierFlags: [], action: #selector(TerminalKeyInput.leftKeyPressed)))
			addKeyCommand(UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(TerminalKeyInput.rightKeyPressed)))
			addKeyCommand(UIKeyCommand(input: UIKeyCommand.inputEscape,     modifierFlags: [], action: #selector(TerminalKeyInput.metaKeyPressed)))

			let letters = [
				"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r",
				"s", "t", "u", "v", "w", "x", "y", "z"
			]
			for key in letters {
				addKeyCommand(UIKeyCommand(input: key, modifierFlags: [ .control ], action: #selector(TerminalKeyInput.ctrlKeyCommandPressed(_:))))
			}
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

		becomeFirstResponder()
		terminalController.terminalWillAppear()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		// Removing keyboard notification observers should come first so we don’t trigger a bunch of
		// probably unnecessary screen size changes.
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

		resignFirstResponder()
		terminalController.terminalWillDisappear()
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

	func inputText(_ text: String) {
		terminalController.receiveKeyboardInput(data: text.data(using: .utf8)!)
	}

	// MARK: - Screen

	func updateScreenSize() {
		textView.contentInset = UIEdgeInsets(top: 0,
																				 left: view.safeAreaInsets.left,
																				 bottom: 0,
																				 right: view.safeAreaInsets.right)
		textView.scrollIndicatorInsets = UIEdgeInsets(top: textView.contentInset.top,
																									left: 0,
																									bottom: textView.contentInset.bottom,
																									right: 0)

		let glyphSize = terminalController.fontMetrics.boundingBox

		// Make sure the glyph size has been set
		if glyphSize.width == 0 || glyphSize.height == 0 {
			fatalError("Failed to get glyph size")
		}

		// Determine the screen size based on the font size
		let width = textView.frame.size.width - view.safeAreaInsets.left - view.safeAreaInsets.right
		#if targetEnvironment(macCatalyst)
		let extraHeight: CGFloat = 26
		#else
		let extraHeight: CGFloat = 0
		#endif
		let height = textView.frame.size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - extraHeight

		if width < 0 || height < 0 {
			// Huh? Let’s just ignore it.
			return
		}

		let size = ScreenSize(width: UInt(width / glyphSize.width),
													height: UInt(height / glyphSize.height))

		terminalController.screenSize = size
	}

	@objc func clearTerminal() {
		terminalController.clearTerminal()
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
		var insets = textView.verticalScrollIndicatorInsets
		var offset = textView.contentOffset
		let bottom = keyboardHeight > 0 ? keyboardHeight : insets.bottom

		insets.top += view.safeAreaInsets.top
		offset.y = terminalController.scrollbackLines == 0 ? -insets.top : bottom + textView.contentSize.height - textView.frame.size.height

		// If the offset has changed, update it and our lastAutomaticScrollOffset
		if textView.contentOffset.y != offset.y {
			textView.setContentOffset(offset, animated: animated)
			lastAutomaticScrollOffset = offset
		}
	}

	@objc func keyboardVisibilityChanged(_ notification: Notification) {
		// We do this to avoid the scroll indicator from appearing as soon as the terminal appears.
		// We only want to see it after the keyboard has appeared.
		if !hasAppeared {
			hasAppeared = true
			textView.showsVerticalScrollIndicator = true

			if let error = failureError {
				// Try to handle the error again now that the UI is ready.
				didReceiveError(error: error)
				failureError = nil
			}
		}

		if notification.name == UIResponder.keyboardWillShowNotification {
			keyboardVisible = true
		} else if notification.name == UIResponder.keyboardDidHideNotification {
			keyboardVisible = false
		}

		// Hide toolbar popups if visible
		keyInput.setMoreRowVisible(false, animated: true)

		// Determine the final keyboard height. We still get a height if hiding, so force it to 0 if
		// this isn’t a show notification.
		let keyboardFrame = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
		if keyboardVisible && notification.name != UIResponder.keyboardWillHideNotification && notification.name != UIResponder.keyboardDidHideNotification {
			keyboardHeight = keyboardFrame.size.height
		} else {
			keyboardHeight = 0
		}

		// We update the safe areas in an animation block to force it to be animated with the exact
		// parameters given to us in the notification.
		let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
		UIView.animate(withDuration: animationDuration) {
			let bottomInset = self.parent?.view.safeAreaInsets.bottom ?? 0
			self.additionalSafeAreaInsets.bottom = max(bottomInset, self.keyboardHeight - bottomInset)
		}
	}

	// MARK: - Gestures

	@objc func handleTextViewTap(_ gestureRecognizer: UITapGestureRecognizer) {
		if gestureRecognizer.state == .ended && !isFirstResponder {
			becomeFirstResponder()
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
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.scrollToBottom()
		}
	}

	func activateBell() {
		let preferences = Preferences.shared

		if preferences.bellHUD {
			// Display the bell HUD, lazily initialising it if it hasn’t been yet
			if bellHUDView.superview == nil {
				view.addSubview(bellHUDView)
				view.addCompactConstraints([
					"hudView.centerX = safe.centerX",
					"hudView.centerY = safe.centerY / 3"
				], metrics: nil, views: [
					"self": view!,
					"hudView": bellHUDView
				])
			}

			bellHUDView.animate()
		}

		if preferences.bellVibrate {
			// According to the docs, we should let the feedback generator get deallocated so the
			// Taptic Engine goes back to sleep afterwards. Also according to the docs, we should use the
			// most semantic impact generator, which would be UINotificationFeedbackGenerator, but I think
			// a single tap feels better than two or three. Shrug
			let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
			feedbackGenerator.impactOccurred()
		}

		if preferences.bellSound {
			#if targetEnvironment(macCatalyst)
			AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert)
			#else
			AudioServicesPlaySystemSound(TerminalSessionViewController.bellSoundID)
			#endif
		}
	}

	func titleDidChange(_ title: String?) {
		self.title = title
	}

	@objc func activatePasswordManager() {
		keyInput.activatePasswordManager()
	}

	@objc func close() {
		if let rootViewController = parent as? RootViewController {
			rootViewController.removeTerminal(terminal: self)
		}
	}

	func didReceiveError(error: Error) {
		if !hasAppeared {
			failureError = error
			return
		}

		let alertController = UIAlertController(title: NSLocalizedString("TERMINAL_LAUNCH_FAILED_TITLE", comment: "Alert title displayed when a terminal could not be launched."),
																						message: NSLocalizedString("TERMINAL_LAUNCH_FAILED_BODY", comment: "Alert body displayed when a terminal could not be launched."),
																						preferredStyle: .alert)
		let ok = NSLocalizedString("OK", tableName: "Localizable", bundle: .uikit, comment: "")
		alertController.addAction(UIAlertAction(title: ok, style: .cancel, handler: nil))
		present(alertController, animated: true, completion: nil)
	}

	@objc func openSettings() {
		if let rootViewController = parent as? RootViewController {
			rootViewController.openSettings()
		}
	}

}

extension TerminalSessionViewController: UITextViewDelegate {

	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		// Hide toolbar popups if visible
		keyInput.setMoreRowVisible(false, animated: true)
	}

	func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
		// If we’re at the top of the scroll view, guess that the user wants to go back to the bottom
		if scrollView.contentOffset.y <= (scrollView.frame.size.height - textView.safeAreaInsets.top - textView.safeAreaInsets.bottom) / 2 {
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
		// scroll. Trick it by scrolling 1 physical pixel up
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
