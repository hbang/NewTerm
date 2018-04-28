//
//  TerminalSessionViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class TerminalSessionViewController: UIViewController {
	
	var barInsets = UIEdgeInsets.zero
	
	private var terminalController = TerminalController()
	private var keyInput = TerminalKeyInput()
	private var textView = TerminalTextView(frame: .zero, textContainer: nil)
	
	private lazy var bellHUDView: HUDView = {
		let bellHUDView = HUDView(image: #imageLiteral(resourceName: "bell-hud"))
		bellHUDView.translatesAutoresizingMaskIntoConstraints = false
		return bellHUDView
	}()
	
	private var hasAppeared = false
	private var hasStarted = false
	private var failureError: Error?
	
	private var keyboardHeight = CGFloat(0)
	private var lastAutomaticScrollOffset = CGPoint.zero
	
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
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		super.loadView()
		
		title = NSLocalizedString("TERMINAL", comment: "Generic title displayed before the terminal sets a proper title.")
		
		textView.frame = view.bounds
		textView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		textView.showsVerticalScrollIndicator = false
		// TODO: this breaks stuff sorta
		// textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTextViewTap(_:))))
		view.addSubview(textView)
		
		keyInput.frame = view.bounds
		keyInput.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		keyInput.textView = textView
		keyInput.terminalInputDelegate = terminalController
		view.addSubview(keyInput)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		registerForKeyboardNotifications()
		_ = becomeFirstResponder()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		unregisterForKeyboardNotifications()
		_ = resignFirstResponder()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		updateScreenSize()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if failureError != nil {
			let ok = NSLocalizedString("OK", tableName: "Localizable", bundle: Bundle(for: UIView.self), comment: "")
			let title = NSLocalizedString("TERMINAL_LAUNCH_FAILED", comment: "Alert title displayed when a terminal could not be launched.")

			let alertView = UIAlertView(title: title, message: failureError!.localizedDescription, delegate: nil, cancelButtonTitle: ok)
			alertView.show()
		}
	}
	
	override func removeFromParentViewController() {
		if hasStarted {
			do {
				try terminalController.stopSubProcess()
			} catch {
				NSLog("failed to stop subprocess… %@", error as NSError)
			}
		}
		
		super.removeFromParentViewController()
	}
	
	// MARK: - Screen
	
	func updateScreenSize() {
		// update the text view insets. if the keyboard height is non-zero, keyboard is visible and that’s
		// our bottom inset. else, it’s not and the bottom toolbar height is the bottom inset
		var newInsets = barInsets
		newInsets.bottom = keyboardHeight > 0 ? keyboardHeight : barInsets.bottom
		
		textView.contentInset = newInsets
		textView.scrollIndicatorInsets = textView.contentInset
		
		let glyphSize = terminalController.fontMetrics.boundingBox
		
		// make sure the glyph size has been set
		if glyphSize.width == 0 || glyphSize.height == 0 {
			fatalError("failed to get the glyph size")
		}
		
		// Determine the screen size based on the font size
		let width = textView.frame.size.width
		let height = textView.frame.size.height - newInsets.top - newInsets.bottom
		
		let size = ScreenSize(width: UInt16(width / glyphSize.width), height: UInt16(height / glyphSize.height))
		
		// The font size should not be too small that it overflows the glyph buffers. It is not worth the
		// effort to fail gracefully (increasing the buffer size would be better).
		if size.width >= kMaxRowBufferSize {
			fatalError("screen size is too wide")
		}
		
		terminalController.screenSize = size
	}
	
	// MARK: - Keyboard/Responder
	
	func scrollToBottom() {
		// if the user has scrolled up far enough on their own, don’t rudely scroll them back to the
		// bottom. when they scroll back, the automatic scrolling will continue
		// TODO: buggy
		// if textView.contentOffset.y < lastAutomaticScrollOffset.y - 20 {
		// 	return
		// }
		
		// if there is no scrollback, use the top of the scroll view. if there is, calculate the bottom
		let insets = textView.scrollIndicatorInsets
		var offset = textView.contentOffset
		let bottom = keyboardHeight > 0 ? keyboardHeight : insets.bottom
		offset.y = terminalController.scrollbackLines() == 0 ? -insets.top : bottom + textView.contentSize.height - textView.frame.size.height
		
		// if the offset has changed, update it and our lastAutomaticScrollOffset
		if textView.contentOffset.y != offset.y {
			textView.contentOffset = offset
			lastAutomaticScrollOffset = offset
		}
	}
	
	func registerForKeyboardNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: .UIKeyboardWillHide, object: nil)
	}
	
	func unregisterForKeyboardNotifications() {
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
	}
	
	@objc func keyboardVisibilityChanged(_ notification: Notification) {
		// we do this to avoid the scroll indicator from appearing as soon as the terminal appears.
		// we only want to see it after the keyboard has appeared
		if !hasAppeared {
			hasAppeared = false
			textView.showsVerticalScrollIndicator = true
		}
		
		// YES when showing, NO when hiding
		let direction = notification.name == .UIKeyboardWillShow
		
		let animationDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
	
		// determine the final keyboard height. we still get a height if hiding, so force it to 0 if this
		// isn’t a show notification
		let keyboardFrame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! CGRect
		keyboardHeight = direction ? keyboardFrame.size.height : 0
	
		// we call updateScreenSize in an animation block to force it to be animated with the exact
		// parameters given to us in the notification
		UIView.animate(withDuration: animationDuration) {
			self.updateScreenSize()
		}
	}
	
	override func becomeFirstResponder() -> Bool {
		return keyInput.becomeFirstResponder()
	}
	
	override func resignFirstResponder() -> Bool {
		return keyInput.resignFirstResponder()
	}
	
	override var isFirstResponder: Bool {
		return keyInput.isFirstResponder
	}
	
	func handleTextViewTap(_ gestureRecognizer: UITapGestureRecognizer) {
		if gestureRecognizer.state == .ended && !isFirstResponder {
			_ = becomeFirstResponder()
		}
	}
	
}

extension TerminalSessionViewController: TerminalControllerDelegate {
	
	func refresh(attributedString: NSAttributedString, backgroundColor: UIColor) {
		textView.attributedText = attributedString
		
		if backgroundColor != textView.backgroundColor {
			textView.backgroundColor = backgroundColor
		}
		
		// TODO: not sure why this is needed all of a sudden? what did i break?
		DispatchQueue.main.async {
			self.scrollToBottom()
		}
	}
	
	func activateBell() {
		// display the bell HUD, lazily initialising it if it hasn’t been yet
		if bellHUDView.superview == nil {
			view.addSubview(bellHUDView)
			view.addCompactConstraints([
				"hudView.centerX = self.centerX",
				"hudView.top = self.top + 100"
			], metrics: nil, views: [
				"self": view,
				"hudView": bellHUDView
			])
		}
		
		bellHUDView.animate()
	}
	
	func close() {
		// TODO: i guess this is kind of the wrong spot
		if let rootViewController = parent as? RootViewController {
			rootViewController.removeTerminal(terminal: self)
		}
	}

	func didReceiveError(error: Error) {
		if !hasAppeared {
			failureError = error
			return
		}

		let ok = NSLocalizedString("OK", tableName: "Localizable", bundle: Bundle(for: UIView.self), comment: "")
		// TODO: this string is wrong!
		let title = NSLocalizedString("TERMINAL_LAUNCH_FAILED", comment: "Alert title displayed when a terminal could not be launched.")

		let nsError = error as NSError
		let alertView = UIAlertView(title: title, message: nsError.localizedDescription, delegate: nil, cancelButtonTitle: ok)
		alertView.show()
	}
	
}
