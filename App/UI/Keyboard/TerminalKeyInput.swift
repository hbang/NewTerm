//
//  TerminalKeyInput.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit
import NewTermCommon
import SwiftUIX

extension ToolbarKey {
	var keySequence: [UTF8Char] {
		switch self {
		case .escape:   return EscapeSequences.meta
		case .tab:      return EscapeSequences.tab
		case .up:       return EscapeSequences.up
		case .down:     return EscapeSequences.down
		case .left:     return EscapeSequences.left
		case .right:    return EscapeSequences.right
		case .home:     return EscapeSequences.home
		case .end:      return EscapeSequences.end
		case .pageUp:   return EscapeSequences.pageUp
		case .pageDown: return EscapeSequences.pageDown
		case .delete:   return EscapeSequences.delete
		case .fnKey(let index): return EscapeSequences.fn[index]
		case .fixedSpace, .variableSpace, .arrows,
				 .control, .more, .fnKeys:
			fatalError()
		}
	}

	var appKeySequence: [UTF8Char]? {
		switch self {
		case .up:       return EscapeSequences.upApp
		case .down:     return EscapeSequences.downApp
		case .left:     return EscapeSequences.leftApp
		case .right:    return EscapeSequences.rightApp
		default:        return nil
		}
	}

	func keySequence(applicationCursor: Bool = false) -> [UTF8Char] {
		(applicationCursor ? appKeySequence : nil) ?? keySequence
	}
}

class TerminalKeyInput: TextInputBase {

	weak var terminalInputDelegate: TerminalInputProtocol?
	weak var textView: UIView! {
		didSet {
			textView.frame = bounds
			textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			insertSubview(textView, at: 0)
		}
	}

	private var toolbar: KeyboardToolbarInputView!
	private var passwordInputView: TerminalPasswordInputView?

	private var ctrlDown = false
	private var previousFloatingCursorPoint: CGPoint? = nil
	private var longPressTimer: Timer?
	private var hardwareRepeatTimer: Timer?

	private var toggledKeys = Set<ToolbarKey>()
	private var pressedKeys = [UIKey]()

	override init(frame: CGRect) {
		super.init(frame: frame)

		autocapitalizationType = .none
		autocorrectionType = .no
		spellCheckingType = .no
		smartQuotesType = .no
		smartDashesType = .no
		smartInsertDeleteType = .no

		let toggledKeysBinding = Binding<Set<ToolbarKey>>(get: { self.toggledKeys },
																											set: { self.toggledKeys = $0 })

		var toolbars: [Toolbar] = [.fnKeys, .secondary]
		if UIDevice.current.userInterfaceIdiom == .pad {
			let leadingView = KeyboardToolbarPadItemView(delegate: self,
																									 toolbar: .padPrimaryLeading,
																									 toggledKeys: toggledKeysBinding)
			let trailingView = KeyboardToolbarPadItemView(delegate: self,
																										toolbar: .padPrimaryTrailing,
																										toggledKeys: toggledKeysBinding)

			inputAssistantItem.allowsHidingShortcuts = false

			if #available(iOS 16, *) {
				inputAssistantItem.leadingBarButtonGroups += [
					.fixedGroup(items: [UIBarButtonItem(customView: leadingView)])
				]
				inputAssistantItem.trailingBarButtonGroups += [
					.fixedGroup(items: [UIBarButtonItem(customView: trailingView)])
				]
			} else {
				inputAssistantItem.leadingBarButtonGroups += [
					UIBarButtonItemGroup(barButtonItems: [UIBarButtonItem(customView: leadingView)], representativeItem: nil)
				]
				inputAssistantItem.trailingBarButtonGroups += [
					UIBarButtonItemGroup(barButtonItems: [UIBarButtonItem(customView: trailingView)], representativeItem: nil)
				]
			}
		} else {
			toolbars += [.primary]
		}

		toolbar = KeyboardToolbarInputView(delegate: self,
																			 toolbars: toolbars,
																			 toggledKeys: toggledKeysBinding)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var inputAccessoryView: UIView? { toolbar }

	// MARK: - Callbacks

//	@objc func ctrlKeyPressed() {
//		ctrlDown.toggle()
//	}
//
//	@objc private func inputKeyPressed(_ sender: KeyboardButton) {
//		if let index = moreToolbar.fnKeys.firstIndex(of: sender) {
//			terminalInputDelegate!.receiveKeyboardInput(data: EscapeSequences.fn[index])
//			return
//		}
//
//		if let data = keyValues[sender] {
//			terminalInputDelegate!.receiveKeyboardInput(data: data)
//		}
//	}
//
//	@objc private func arrowKeyPressed(_ sender: KeyboardButton) {
//		let values = terminalInputDelegate!.applicationCursor ? keyAppValues : keyValues
//		if let data = values[sender] {
//			terminalInputDelegate!.receiveKeyboardInput(data: data)
//		}
//	}
//
//	@objc private func arrowRepeatTimerFired(_ timer: Timer) {
//		arrowKeyPressed(timer.userInfo as! KeyboardButton)
//	}
//
//	@objc func moreKeyPressed() {
//		setMoreRowVisible(moreToolbar.isHidden, animated: true)
//	}
//
//	@objc func arrowKeyLongPressed(_ sender: UILongPressGestureRecognizer) {
//		switch sender.state {
//		case .began:
//			longPressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.arrowRepeatTimerFired), userInfo: sender.view, repeats: true)
//			break
//
//		case .ended, .cancelled:
//			longPressTimer?.invalidate()
//			longPressTimer = nil
//			break
//
//		default:
//			break
//		}
//	}

	// MARK: - More row

//	func setMoreRowVisible(_ visible: Bool, animated: Bool = true) {
//		// if we’re already in the specified state, return
//		if visible == !moreToolbar.isHidden {
//			return
//		}
//
//		moreKey.isSelected = visible
//
//		// only hiding is animated
//		if !visible && animated {
//			UIView.animate(withDuration: 0.2, animations: {
//				self.moreToolbar.alpha = 0
//			}, completion: { _ in
//				self.moreToolbar.isHidden = true
//			})
//		} else {
//			moreToolbar.alpha = visible ? 1 : 0
//			moreToolbar.isHidden = !visible
//			moreToolbarBottomConstraint.constant = -(textView?.safeAreaInsets.bottom ?? 0)
//		}
//	}

	// MARK: - Password manager

	func activatePasswordManager() {
		// Trigger the iOS password manager button, or cancel the operation.
		if let passwordInputView = passwordInputView {
			// We’ll become first responder automatically after removing the view.
			passwordInputView.removeFromSuperview()
		} else {
			passwordInputView = TerminalPasswordInputView()
			passwordInputView!.passwordDelegate = self
			addSubview(passwordInputView!)
			passwordInputView!.becomeFirstResponder()
		}
	}

	// MARK: - UITextInput

	override var hasText: Bool { true }

	override func insertText(_ text: String) {
		// Used by the software keyboard only. See pressesBegan(_:with:) below for hardware keyboard.
		let data = text.utf8.map { character -> UTF8Char in
			// Convert newline to carriage return
			if character == 0x0A {
				return EscapeSequences.return.first!
			}
			if ctrlDown {
				return character.controlCharacter
			}
			return character
		}

		terminalInputDelegate!.receiveKeyboardInput(data: data)

		if ctrlDown {
			ctrlDown = false
//			ctrlKey.isSelected = false
		}

//		if !moreToolbar.isHidden {
//			setMoreRowVisible(false, animated: true)
//		}
	}

	override func deleteBackward() {
		terminalInputDelegate!.receiveKeyboardInput(data: EscapeSequences.backspace)
	}

	func beginFloatingCursor(at point: CGPoint) {
		previousFloatingCursorPoint = point
	}

	func updateFloatingCursor(at point: CGPoint) {
		guard let oldPoint = previousFloatingCursorPoint else {
			return
		}

		let threshold: CGFloat
		switch Preferences.shared.keyboardTrackpadSensitivity {
		case .off:    return
		case .low:    threshold = 8
		case .medium: threshold = 5
		case .high:   threshold = 2
		}

		let difference = point.x - oldPoint.x
		if abs(difference) < threshold {
			return
		}
		keyboardToolbarDidPressKey(difference < 0 ? .left : .right)
		previousFloatingCursorPoint = point
	}

	func endFloatingCursor() {
		previousFloatingCursorPoint = nil
	}

	// MARK: - UIResponder

	@discardableResult
	override func becomeFirstResponder() -> Bool {
		if let passwordInputView = passwordInputView {
			return passwordInputView.becomeFirstResponder()
		} else {
			_ = super.becomeFirstResponder()
			return true
		}
	}

	@discardableResult
	override func resignFirstResponder() -> Bool {
		super.resignFirstResponder()
	}

	override var canBecomeFirstResponder: Bool { true }

	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case #selector(self.paste(_:)):
			// Only paste if the pasteboard contains a plaintext type
			return UIPasteboard.general.hasStrings || UIPasteboard.general.hasURLs

		case #selector(self.cut(_:)):
			// Ensure cut is never allowed
			return false

		default:
			return super.canPerformAction(action, withSender: sender)
		}
	}

	override func copy(_ sender: Any?) {
//		textView?.copy(sender)
	}

	override func paste(_ sender: Any?) {
		if let string = UIPasteboard.general.string {
			terminalInputDelegate!.receiveKeyboardInput(data: string.utf8Array)
		}
	}

	// MARK: - Hardware keyboard

	@discardableResult
	private func handleKey(_ key: UIKey) -> Bool {
		// We don‘t want to handle cmd, let UIKit handle that.
		if key.modifierFlags.contains(.command) {
			return false
		}

		var keyData: [UTF8Char]
		switch key.keyCode {
		case .keyboardReturnOrEnter: keyData = EscapeSequences.return
		case .keyboardEscape:        keyData = EscapeSequences.meta
		case .keyboardDeleteOrBackspace: keyData = EscapeSequences.backspace
		case .keyboardDeleteForward: keyData = EscapeSequences.delete

		case .keyboardHome:
			keyData = terminalInputDelegate!.applicationCursor ? EscapeSequences.homeApp : EscapeSequences.home

		case .keyboardEnd:
			keyData = terminalInputDelegate!.applicationCursor ? EscapeSequences.endApp : EscapeSequences.end

		case .keyboardUpArrow:
			keyData = terminalInputDelegate!.applicationCursor ? EscapeSequences.upApp : EscapeSequences.up

		case .keyboardDownArrow:
			keyData = terminalInputDelegate!.applicationCursor ? EscapeSequences.downApp : EscapeSequences.down

		case .keyboardLeftArrow:
			if key.modifierFlags.contains(.alternate) {
				keyData = EscapeSequences.leftMeta
			} else if terminalInputDelegate!.applicationCursor {
				keyData = EscapeSequences.leftApp
			} else {
				keyData = EscapeSequences.left
			}

		case .keyboardRightArrow:
			if key.modifierFlags.contains(.alternate) {
				keyData = EscapeSequences.rightMeta
			} else if terminalInputDelegate!.applicationCursor {
				keyData = EscapeSequences.rightApp
			} else {
				keyData = EscapeSequences.right
			}

		case .keyboardPageUp:     keyData = EscapeSequences.pageUp
		case .keyboardPageDown:   keyData = EscapeSequences.pageDown

		case .keyboardF1, .keyboardF2, .keyboardF3, .keyboardF4, .keyboardF5, .keyboardF6, .keyboardF7,
				.keyboardF8, .keyboardF9, .keyboardF10, .keyboardF11, .keyboardF12:
			keyData = EscapeSequences.fn[key.keyCode.rawValue - UIKeyboardHIDUsage.keyboardF1.rawValue]

		default: keyData = key.characters.utf8Array
		}

		// If we didn’t get anything to type, nothing else to do here.
		if keyData.isEmpty {
			return false
		}

		// Translate ctrl key sequences to the approriate escape.
		if key.modifierFlags.contains(.control) {
			keyData = keyData.map(\.controlCharacter)
		}

		// Prepend esc before each byte if meta key is down.
		if key.modifierFlags.contains(.alternate) {
			keyData = keyData.reduce([], { result, character in result + EscapeSequences.meta + [character] })
		}

		terminalInputDelegate?.receiveKeyboardInput(data: keyData)
		return true
	}

	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		var isHandled = false
		for press in presses {
			if let key = press.key,
				 handleKey(key) {
				isHandled = true
				pressedKeys.append(key)
			}
		}

		if !pressedKeys.isEmpty && hardwareRepeatTimer == nil {
			#if targetEnvironment(macCatalyst)
			// If key repeat is disabled by the user, the initial repeat value will be set to a crazy
			// high sentinel number.
			let defaults = UserDefaults.standard
			let keyRepeatEnabled = defaults.object(forKey: "InitialKeyRepeat") as? TimeInterval != 300000
			#else
			let defaults = UserDefaults(suiteName: "com.apple.Accessibility")
			let keyRepeatEnabled = defaults?.object(forKey: "KeyRepeatEnabled") as? Bool ?? true
			#endif

			if keyRepeatEnabled {
				#if targetEnvironment(macCatalyst)
				// No idea what these key repeat preference values are meant to calculate out to, but
				// this seems about right. Tested by counting frames in a screen recording.
				let initialKeyRepeat = (UserDefaults.standard.object(forKey: "InitialKeyRepeat") as? TimeInterval ?? 84) * 0.012
				#else
				let initialKeyRepeat = defaults?.object(forKey: "KeyRepeatDelay") as? TimeInterval ?? 0.4
				#endif

				hardwareRepeatTimer = Timer.scheduledTimer(timeInterval: initialKeyRepeat,
																									 target: self,
																									 selector: #selector(self.handleHardwareKeyRepeat),
																									 userInfo: true,
																									 repeats: false)
			}
		}

		if !isHandled {
			super.pressesBegan(presses, with: event)
		}
	}

	private func handlePressesEnded(_ presses: Set<UIPress>) {
		let keys = presses.compactMap(\.key)
		pressedKeys.removeAll(where: { keys.contains($0) })
		if pressedKeys.isEmpty {
			hardwareRepeatTimer?.invalidate()
			hardwareRepeatTimer = nil
		}
	}

	override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		handlePressesEnded(presses)
		super.pressesEnded(presses, with: event)
	}

	override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		handlePressesEnded(presses)
		super.pressesCancelled(presses, with: event)
	}

	@objc private func handleHardwareKeyRepeat(_ timer: Timer) {
		for key in pressedKeys {
			handleKey(key)
		}

		if timer.userInfo as? Bool ?? false {
			#if targetEnvironment(macCatalyst)
			let keyRepeat = (UserDefaults.standard.object(forKey: "KeyRepeat") as? TimeInterval ?? 8) * 0.012
			#else
			let keyRepeat = UserDefaults(suiteName: "com.apple.Accessibility")?
				.object(forKey: "KeyRepeatInterval") as? TimeInterval ?? 0.1
			#endif
			hardwareRepeatTimer = Timer.scheduledTimer(timeInterval: keyRepeat,
																								 target: self,
																								 selector: #selector(self.handleHardwareKeyRepeat),
																								 userInfo: nil,
																								 repeats: true)
		}
	}

}

extension TerminalKeyInput: KeyboardToolbarViewDelegate {
	func keyboardToolbarDidPressKey(_ key: ToolbarKey) {
		guard let terminalInputDelegate = terminalInputDelegate else {
			return
		}
		terminalInputDelegate.receiveKeyboardInput(data: key.keySequence(applicationCursor: terminalInputDelegate.applicationCursor))
	}
}

extension TerminalKeyInput: TerminalPasswordInputViewDelegate {

	func passwordInputViewDidComplete(password: String?) {
		if let password = password {
			// User could have typed on the keyboard while it was in password mode, rather than using the
			// password autofill. Send a return if it seems like a password was actually received,
			// otherwise just pretend it was typed like normal.
			if password.count > 2 {
				terminalInputDelegate!.receiveKeyboardInput(data: password.utf8Array + EscapeSequences.return)
			} else {
				insertText(password)
			}
		}
		passwordInputView?.removeFromSuperview()
		passwordInputView = nil
		_ = becomeFirstResponder()
	}

}
