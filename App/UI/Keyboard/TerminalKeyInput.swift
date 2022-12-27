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
		case .fnKey(let index): return EscapeSequences.fn[index - 1]
		case .fixedSpace, .variableSpace, .arrows,
				 .control, .more, .fnKeys:
			return []
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

	private var previousFloatingCursorPoint: CGPoint? = nil
	private var repeatTimer: Timer?

	private var state = KeyboardToolbarViewState()
	private var pressedHardwareKeys = Set<UIKey>()
	private var pressedToolbarKeys = Set<ToolbarKey>()

	override init(frame: CGRect) {
		super.init(frame: frame)

		autocapitalizationType = .none
		autocorrectionType = .no
		spellCheckingType = .no
		smartQuotesType = .no
		smartDashesType = .no
		smartInsertDeleteType = .no

		var toolbars: [Toolbar] = [.fnKeys, .secondary]
		if UIDevice.current.userInterfaceIdiom == .pad {
			let leadingView = KeyboardToolbarPadItemView(delegate: self,
																									 toolbar: .padPrimaryLeading,
																									 state: state)
			let trailingView = KeyboardToolbarPadItemView(delegate: self,
																										toolbar: .padPrimaryTrailing,
																										state: state)

			inputAssistantItem.allowsHidingShortcuts = false

			if #available(iOS 16, *) {
				#if swift(>=5.7)
				inputAssistantItem.leadingBarButtonGroups += [
					.fixedGroup(items: [UIBarButtonItem(customView: leadingView)])
				]
				inputAssistantItem.trailingBarButtonGroups += [
					.fixedGroup(items: [UIBarButtonItem(customView: trailingView)])
				]
				#endif
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
																			 state: state)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var inputAccessoryView: UIView? { toolbar }

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
		let isCtrlDown = state.toggledKeys.contains(.control)
		let data = text.utf8.map { character -> UTF8Char in
			// Convert newline to carriage return
			if character == 0x0A {
				return EscapeSequences.return.first!
			}
			if isCtrlDown {
				return character.controlCharacter
			}
			return character
		}

		terminalInputDelegate!.receiveKeyboardInput(data: data)

		if isCtrlDown {
			state.toggledKeys.remove(.control)
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
				pressedHardwareKeys.insert(key)
			}
		}

		if !pressedHardwareKeys.isEmpty {
			beginKeyRepeat()
		}

		if !isHandled {
			super.pressesBegan(presses, with: event)
		}
	}

	private func handlePressesEnded(_ presses: Set<UIPress>) {
		for press in presses {
			if let key = press.key {
				pressedHardwareKeys.remove(key)
			}
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

	private func beginKeyRepeat() {
		if repeatTimer != nil {
			return
		}

		if KeyboardPreferences.isKeyRepeatEnabled {
			repeatTimer = Timer.scheduledTimer(timeInterval: KeyboardPreferences.keyRepeatDelay,
																				 target: self,
																				 selector: #selector(self.handleKeyRepeat),
																				 userInfo: true,
																				 repeats: false)
		}
	}

	@objc private func handleKeyRepeat(_ timer: Timer) {
		for key in pressedHardwareKeys {
			handleKey(key)
		}

		for key in pressedToolbarKeys {
			keyboardToolbarDidPressKey(key)
		}

		if pressedHardwareKeys.isEmpty && pressedToolbarKeys.isEmpty {
			repeatTimer?.invalidate()
			repeatTimer = nil
			return
		}

		if timer.userInfo as? Bool ?? false {
			repeatTimer = Timer.scheduledTimer(timeInterval: KeyboardPreferences.keyRepeat,
																				 target: self,
																				 selector: #selector(self.handleKeyRepeat),
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

		switch key {
		case .more:
			// Also hide fn row if currently toggled
			if state.toggledKeys.contains(.fnKeys) {
				state.toggledKeys.remove(.fnKeys)
			}

		default: break
		}
	}

	func keyboardToolbarDidBeginPressingKey(_ key: ToolbarKey) {
		switch key {
		case .up, .down, .left, .right,
				 .home, .end, .pageUp, .pageDown,
				 .delete:
			pressedToolbarKeys.insert(key)
			beginKeyRepeat()

		default: break
		}
	}

	func keyboardToolbarDidEndPressingKey(_ key: ToolbarKey) {
		pressedToolbarKeys.remove(key)
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
