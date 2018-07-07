//
//  TerminalKeyInput.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

@objc protocol TerminalInputProtocol {
	
	@objc func receiveKeyboardInput(data: Data)
	
}

class TerminalKeyInput: TextInputBase {
	
	@objc weak var terminalInputDelegate: TerminalInputProtocol?
	@objc weak var textView: UITextView! {
		didSet {
			textView.frame = bounds
			textView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
			addSubview(textView)
		}
	}
	
	private var toolbar: KeyboardToolbar?
	private var ctrlKey: KeyboardButton!
	private var metaKey: KeyboardButton!
	
	private var ctrlDown = false
	private var metaDown = false
	
	private let backspaceData = Data(bytes: [0x7F]) // \x7F
	private let metaKeyData = Data(bytes: [0x1B]) // \e
	private let tabKeyData = Data(bytes: [0x09]) // \t
	private let upKeyData = Data(bytes: [0x1B, 0x5B, 0x41]) // \e[A
	private let downKeyData = Data(bytes: [0x1B, 0x5B, 0x42]) // \e[B
	private let leftKeyData = Data(bytes: [0x1B, 0x5B, 0x44]) // \e[D
	private let rightKeyData = Data(bytes: [0x1B, 0x5B, 0x43]) // \e[C
	
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
		var hasPadToolbar = false

		if UIDevice.current.userInterfaceIdiom == .pad {
			if #available(iOS 9.0, *) {
				hasPadToolbar = true

				ctrlKey = KeyboardButton(title: "Ctrl", target: self, action: #selector(self.ctrlKeyPressed))
				metaKey = KeyboardButton(title: "Esc", target: self, action: #selector(self.metaKeyPressed))
				
				inputAssistantItem.allowsHidingShortcuts = false
				
				var leadingBarButtonGroups = inputAssistantItem.leadingBarButtonGroups
				leadingBarButtonGroups.append(UIBarButtonItemGroup(barButtonItems: [
					UIBarButtonItem(customView: ctrlKey),
					UIBarButtonItem(customView: metaKey),
					UIBarButtonItem(customView: KeyboardButton(title: "Tab", target: self, action: #selector(self.tabKeyPressed)))
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
			}
		}
		
		if !hasPadToolbar {
			toolbar = KeyboardToolbar()
			toolbar!.translatesAutoresizingMaskIntoConstraints = false
			toolbar!.ctrlKey.addTarget(self, action: #selector(self.ctrlKeyPressed), for: .touchUpInside)
			toolbar!.metaKey.addTarget(self, action: #selector(self.metaKeyPressed), for: .touchUpInside)
			toolbar!.tabKey.addTarget(self, action: #selector(self.tabKeyPressed), for: .touchUpInside)
			toolbar!.upKey.addTarget(self, action: #selector(self.upKeyPressed), for: .touchUpInside)
			toolbar!.downKey.addTarget(self, action: #selector(self.downKeyPressed), for: .touchUpInside)
			toolbar!.leftKey.addTarget(self, action: #selector(self.leftKeyPressed), for: .touchUpInside)
			toolbar!.rightKey.addTarget(self, action: #selector(self.rightKeyPressed), for: .touchUpInside)
			
			ctrlKey = toolbar!.ctrlKey
			metaKey = toolbar!.metaKey
		}
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
	
	@objc func metaKeyPressed() {
		metaDown = !metaDown
		metaKey.isSelected = metaDown
	}
	
	@objc func tabKeyPressed() {
		terminalInputDelegate!.receiveKeyboardInput(data: tabKeyData)
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
				if character >= 0x41 && character <= 0x7A { // >= 'a' <= 'z'
					newCharacter -= 0x40 // 'a' - 1
				}
			} else if metaDown {
				// prepend the escape character
				data.append(contentsOf: metaKeyData)
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
		
		if metaDown {
			metaDown = false
			metaKey.isSelected = false
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
			return UIPasteboard.general.contains(pasteboardTypes: UIPasteboardTypeListString as! [String])
		
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
		if !pasteboard.contains(pasteboardTypes: UIPasteboardTypeListString as! [String]) {
			return
		}
		
		guard let string = pasteboard.string else {
			// welp?
			return
		}
		
		terminalInputDelegate!.receiveKeyboardInput(data: string.data(using: .utf8)!)
	}
	
}
