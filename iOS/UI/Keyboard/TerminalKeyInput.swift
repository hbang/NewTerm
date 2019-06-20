//
//  TerminalKeyInput.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class TerminalKeyInput: TextInputBase {

	var terminalInputDelegate: TerminalInputProtocol?
	weak var textView: UITextView! {
		didSet {
			textView.frame = bounds
			textView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
			insertSubview(textView, at: 0)
		}
	}

	private var toolbar: KeyboardToolbar?
	private var ctrlKey: KeyboardButton!
	private var moreKey: KeyboardButton!
	private var moreToolbar = KeyboardPopupToolbar(frame: .zero)

	private var ctrlDown = false

	private let backspaceData = Data([0x7F]) // \x7F
	private let metaKeyData = Data([0x1B]) // \e
	private let tabKeyData = Data([0x09]) // \t
	private let upKeyData = Data([0x1B, 0x5B, 0x41]) // \e[A
	private let downKeyData = Data([0x1B, 0x5B, 0x42]) // \e[B
	private let leftKeyData = Data([0x1B, 0x5B, 0x44]) // \e[D
	private let rightKeyData = Data([0x1B, 0x5B, 0x43]) // \e[C
	private let homeKeyData = Data([0x1B, 0x5B, 0x48]) // \e[H
	private let endKeyData = Data([0x1B, 0x5B, 0x46]) // \e[F
	private let pageUpKeyData = Data([0x1B, 0x5B, 0x35, 0x7E]) // \e[5~
	private let pageDownKeyData = Data([0x1B, 0x5B, 0x36, 0x7E]) // \e[6~
	private let deleteKeyData = Data([0x1B, 0x5B, 0x33, 0x7E]) // \e[3~

	override init(frame: CGRect) {
		super.init(frame: frame)

		autocapitalizationType = .none
		autocorrectionType = .no
		spellCheckingType = .no

		if #available(iOS 11.0, *) {
			smartQuotesType = .no
			smartDashesType = .no
			smartInsertDeleteType = .no
		}

		// TODO: this should be themable
		keyboardAppearance = .dark

		// TODO: this is kinda ugly and causes duped code for these buttons
		if UIDevice.current.userInterfaceIdiom == .pad {
			ctrlKey = KeyboardButton(title: "Ctrl", target: self, action: #selector(self.ctrlKeyPressed))
			moreKey = KeyboardButton(title: "Fn", target: self, action: #selector(self.moreKeyPressed))

			inputAssistantItem.allowsHidingShortcuts = false

			var leadingBarButtonGroups = inputAssistantItem.leadingBarButtonGroups
			leadingBarButtonGroups.append(UIBarButtonItemGroup(barButtonItems: [
				UIBarButtonItem(customView: ctrlKey),
				UIBarButtonItem(customView: KeyboardButton(title: "Esc", target: self, action: #selector(self.metaKeyPressed))),
				UIBarButtonItem(customView: KeyboardButton(title: "Tab", target: self, action: #selector(self.tabKeyPressed))),
				UIBarButtonItem(customView: moreKey)
			], representativeItem: nil))
			inputAssistantItem.leadingBarButtonGroups = leadingBarButtonGroups

			var trailingBarButtonGroups = inputAssistantItem.trailingBarButtonGroups
			trailingBarButtonGroups.append(UIBarButtonItemGroup(barButtonItems: [
				UIBarButtonItem(customView: KeyboardButton(title: "▲", target: self, action: #selector(self.upKeyPressed))),
				UIBarButtonItem(customView: KeyboardButton(title: "▼", target: self, action: #selector(self.downKeyPressed))),
				UIBarButtonItem(customView: KeyboardButton(title: "◀", target: self, action: #selector(self.leftKeyPressed))),
				UIBarButtonItem(customView: KeyboardButton(title: "▶", target: self, action: #selector(self.rightKeyPressed))),
			], representativeItem: nil))
			inputAssistantItem.trailingBarButtonGroups = trailingBarButtonGroups
		} else {
			toolbar = KeyboardToolbar()
			toolbar!.translatesAutoresizingMaskIntoConstraints = false
			toolbar!.ctrlKey.addTarget(self, action: #selector(self.ctrlKeyPressed), for: .touchUpInside)
			toolbar!.metaKey.addTarget(self, action: #selector(self.metaKeyPressed), for: .touchUpInside)
			toolbar!.tabKey.addTarget(self, action: #selector(self.tabKeyPressed), for: .touchUpInside)
			toolbar!.moreKey.addTarget(self, action: #selector(self.moreKeyPressed), for: .touchUpInside)
			toolbar!.upKey.addTarget(self, action: #selector(self.upKeyPressed), for: .touchUpInside)
			toolbar!.downKey.addTarget(self, action: #selector(self.downKeyPressed), for: .touchUpInside)
			toolbar!.leftKey.addTarget(self, action: #selector(self.leftKeyPressed), for: .touchUpInside)
			toolbar!.rightKey.addTarget(self, action: #selector(self.rightKeyPressed), for: .touchUpInside)

			ctrlKey = toolbar!.ctrlKey
			moreKey = toolbar!.moreKey
		}

		setMoreRowVisible(false, animated: false)
		addSubview(moreToolbar)

		moreToolbar.homeKey.addTarget(self, action: #selector(self.homeKeyPressed), for: .touchUpInside)
		moreToolbar.endKey.addTarget(self, action: #selector(self.endKeyPressed), for: .touchUpInside)
		moreToolbar.pageUpKey.addTarget(self, action: #selector(self.pageUpKeyPressed), for: .touchUpInside)
		moreToolbar.pageDownKey.addTarget(self, action: #selector(self.pageDownKeyPressed), for: .touchUpInside)
		moreToolbar.deleteKey.addTarget(self, action: #selector(self.deleteKeyPressed), for: .touchUpInside)
		moreToolbar.settingsKey.addTarget(self, action: #selector(self.settingsKeyPressed), for: .touchUpInside)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var inputAccessoryView: UIView? {
		return toolbar
	}

	// MARK: - Callbacks

	@objc func ctrlKeyPressed() {
		ctrlDown = !ctrlDown
		ctrlKey.isSelected = ctrlDown
	}

	@objc func ctrlKeyCommandPressed(_ keyCommand: UIKeyCommand) {
		ctrlDown = keyCommand.modifierFlags.contains(.control)
		ctrlKey.isSelected = ctrlDown
	}

	@objc func metaKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: metaKeyData)
	}

	@objc func tabKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: tabKeyData)
	}

	@objc func moreKeyPressed() {
		setMoreRowVisible(moreToolbar.isHidden, animated: true)
	}

	@objc func upKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: upKeyData)
	}

	@objc func downKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: downKeyData)
	}

	@objc func leftKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: leftKeyData)
	}

	@objc func rightKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: rightKeyData)
	}

	@objc func homeKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: homeKeyData)
	}

	@objc func endKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: endKeyData)
	}

	@objc func pageUpKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: pageUpKeyData)
	}

	@objc func pageDownKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: pageDownKeyData)
	}

	@objc func deleteKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: deleteKeyData)
	}

	@objc func settingsKeyPressed() {
		terminalInputDelegate!.openSettings()
	}

	// MARK: - More row

	override func layoutSubviews() {
		super.layoutSubviews()

		let moreToolbarHeight = moreToolbar.intrinsicContentSize.height
		let insets: UIEdgeInsets
		if #available(iOS 13.0, *) {
			insets = textView.verticalScrollIndicatorInsets
		} else {
			insets = textView.scrollIndicatorInsets
		}
		moreToolbar.frame = CGRect(x: 0, y: textView.frame.size.height - insets.bottom - moreToolbarHeight, width: textView.frame.size.width, height: moreToolbarHeight)
	}

	func setMoreRowVisible(_ visible: Bool, animated: Bool = true) {
		// if we’re already in the specified state, return
		if visible == !moreToolbar.isHidden {
			return
		}

		moreKey.isSelected = visible

		// only hiding is animated
		if !visible && animated {
			UIView.animate(withDuration: 0.2, animations: {
				self.moreToolbar.alpha = 0
			}, completion: { _ in
				self.moreToolbar.isHidden = true
			})
		} else {
			moreToolbar.alpha = visible ? 1 : 0
			moreToolbar.isHidden = !visible
		}
	}

	// MARK: - UITextInput

	override var textInputView: UIView {
		// if we have the instance of the text view, return it here so stuff like selection hopefully
		// works. if not, just return self for the moment
		return textView ?? self
	}

	override func hasText() -> Bool {
		// we always “have text”, even if we don’t
		return true
	}

	override func insertText(_ text: String) {
		let input = text.data(using: .utf8)!
		var data = Data()

		for character in input {
			var newCharacter = character

			if ctrlDown {
				// translate capital to lowercase
				if character >= 0x41 && character <= 0x5A { // >= 'A' <= 'Z'
					newCharacter += 0x61 - 0x41 // 'a' - 'A'
				}

				// convert to the matching control character
				if character >= 0x61 && character <= 0x7A { // >= 'a' <= 'z'
					newCharacter -= 0x61 - 1 // 'a' - 1
				}
			}

			// convert newline to carriage return
			if character == 0x0A {
				newCharacter = 0x0D
			}

			data.append(contentsOf: [ newCharacter ])
		}

		terminalInputDelegate!.receiveKeyboardInput(data: data)

		if ctrlDown {
			ctrlDown = false
			ctrlKey.isSelected = false
		}

		if !moreToolbar.isHidden {
			setMoreRowVisible(false, animated: true)
		}
	}

	override func deleteBackward() {
		terminalInputDelegate!.receiveKeyboardInput(data: backspaceData)
	}

	// MARK: - UIResponder

	override func becomeFirstResponder() -> Bool {
		super.becomeFirstResponder()
		return true
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case #selector(self.paste(_:)):
			// only paste if the pasteboard contains a plaintext type
			return UIPasteboard.general.contains(pasteboardTypes: UIPasteboard.typeListString as! [String])

		case #selector(self.cut(_:)):
			// ensure cut is never allowed
			return false

		default:
			// the rest are handled by super (which probably just returns false for everything…)
			return super.canPerformAction(action, withSender: sender)
		}
	}

	override func copy(_ sender: Any?) {
		textView?.copy(sender)
	}

	override func paste(_ sender: Any?) {
		let pasteboard = UIPasteboard.general

		// we already checked this above in canPerformAction(_:withSender:), but double check again
		if !pasteboard.contains(pasteboardTypes: UIPasteboard.typeListString as! [String]) {
			return
		}

		guard let string = pasteboard.string else {
			// welp?
			return
		}

		terminalInputDelegate!.receiveKeyboardInput(data: string.data(using: .utf8)!)
	}

}
