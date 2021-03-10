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

	private let ctrlKey  = KeyboardButton(title: "Control",   glyph: "Ctrl", systemImage: "control", image: #imageLiteral(resourceName: "key-control"))
	private let metaKey  = KeyboardButton(title: "Escape",    glyph: "Esc",  systemImage: "escape", image: #imageLiteral(resourceName: "key-escape"))
	private let tabKey   = KeyboardButton(title: "Tab",       glyph: "Tab",  systemImage: "arrow.right.to.line", image: #imageLiteral(resourceName: "key-tab"))
	private let moreKey  = KeyboardButton(title: "Functions", systemImage: "ellipsis", image: #imageLiteral(resourceName: "key-more"))

	private let upKey    = KeyboardButton(title: "Up",    systemImage: "arrow.up",    image: #imageLiteral(resourceName: "key-up"))
	private let downKey  = KeyboardButton(title: "Down",  systemImage: "arrow.down",  image: #imageLiteral(resourceName: "key-down"))
	private let leftKey  = KeyboardButton(title: "Left",  systemImage: "arrow.left",  image: #imageLiteral(resourceName: "key-left"))
	private let rightKey = KeyboardButton(title: "Right", systemImage: "arrow.right", image: #imageLiteral(resourceName: "key-right"))

	private var longPressTimer: Timer?
	private var buttons: [KeyboardButton]!
	private var squareButtonConstraints: [NSLayoutConstraint]!
	private var moreToolbar = KeyboardPopupToolbar(frame: .zero)

	private var ctrlDown = false

	private let backspaceData   = Data([ 0x7F ]) // \x7F
	private let metaKeyData     = Data([ 0x1B ]) // \e
	private let tabKeyData      = Data([ 0x09 ]) // \t
	private let upKeyData       = Data([ 0x1B, 0x5B, 0x41 ]) // \e[A
	private let upKeyAppData    = Data([ 0x1B, 0x4F, 0x41 ]) // \eOA
	private let downKeyData     = Data([ 0x1B, 0x5B, 0x42 ]) // \e[B
	private let downKeyAppData  = Data([ 0x1B, 0x4F, 0x42 ]) // \eOB
	private let leftKeyData     = Data([ 0x1B, 0x5B, 0x44 ]) // \e[D
	private let leftKeyAppData  = Data([ 0x1B, 0x4F, 0x44 ]) // \eOD
	private let rightKeyData    = Data([ 0x1B, 0x5B, 0x43 ]) // \e[C
	private let rightKeyAppData = Data([ 0x1B, 0x4F, 0x43 ]) // \eOC
	private let homeKeyData     = Data([ 0x1B, 0x5B, 0x48 ]) // \e[H
	private let endKeyData      = Data([ 0x1B, 0x5B, 0x46 ]) // \e[F
	private let pageUpKeyData   = Data([ 0x1B, 0x5B, 0x35, 0x7E ]) // \e[5~
	private let pageDownKeyData = Data([ 0x1B, 0x5B, 0x36, 0x7E ]) // \e[6~
	private let deleteKeyData   = Data([ 0x1B, 0x5B, 0x33, 0x7E ]) // \e[3~

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

		if #available(iOS 13.0, *) {
		} else {
			// TODO: this should be themable
			keyboardAppearance = .dark
		}

		buttons = [
			ctrlKey, metaKey, tabKey, moreKey,
			upKey, downKey, leftKey, rightKey
		]

		if UIDevice.current.userInterfaceIdiom == .pad {
			inputAssistantItem.allowsHidingShortcuts = false

			let xSpacing = CGFloat(6)
			let height = CGFloat(isSmallDevice ? 36 : 44)

			let leftContainerView = UIView()
			leftContainerView.translatesAutoresizingMaskIntoConstraints = false

			let leftSpacerView = UIView()
			leftSpacerView.translatesAutoresizingMaskIntoConstraints = false

			let leftStackView = UIStackView(arrangedSubviews: [ ctrlKey, metaKey, tabKey, moreKey, leftSpacerView ])
			leftStackView.translatesAutoresizingMaskIntoConstraints = false
			leftStackView.axis = .horizontal
			leftStackView.spacing = xSpacing
			leftContainerView.addSubview(leftStackView)

			var leadingBarButtonGroups = inputAssistantItem.leadingBarButtonGroups
			leadingBarButtonGroups.append(UIBarButtonItemGroup(barButtonItems: [
				UIBarButtonItem(customView: leftContainerView)
			], representativeItem: nil))
			inputAssistantItem.leadingBarButtonGroups = leadingBarButtonGroups

			let rightContainerView = UIView()
			rightContainerView.translatesAutoresizingMaskIntoConstraints = false

			let rightSpacerView = UIView()
			rightSpacerView.translatesAutoresizingMaskIntoConstraints = false

			let rightStackView = UIStackView(arrangedSubviews: [ rightSpacerView, upKey, downKey, leftKey, rightKey ])
			rightStackView.translatesAutoresizingMaskIntoConstraints = false
			rightStackView.axis = .horizontal
			rightStackView.spacing = xSpacing
			rightContainerView.addSubview(rightStackView)

			var trailingBarButtonGroups = inputAssistantItem.trailingBarButtonGroups
			trailingBarButtonGroups.append(UIBarButtonItemGroup(barButtonItems: [
				UIBarButtonItem(customView: rightContainerView)
			], representativeItem: nil))
			inputAssistantItem.trailingBarButtonGroups = trailingBarButtonGroups

			NSLayoutConstraint.activate([
				leftStackView.leadingAnchor.constraint(equalTo: leftContainerView.leadingAnchor),
				rightStackView.leadingAnchor.constraint(equalTo: rightContainerView.leadingAnchor),
				leftStackView.trailingAnchor.constraint(equalTo: leftContainerView.trailingAnchor),
				rightStackView.trailingAnchor.constraint(equalTo: rightContainerView.trailingAnchor),
				leftStackView.heightAnchor.constraint(equalToConstant: height),
				rightStackView.heightAnchor.constraint(equalToConstant: height),
				leftStackView.centerYAnchor.constraint(equalTo: leftContainerView.centerYAnchor),
				rightStackView.centerYAnchor.constraint(equalTo: rightContainerView.centerYAnchor)
			])
		} else {
			toolbar = KeyboardToolbar()
			toolbar!.translatesAutoresizingMaskIntoConstraints = false
			toolbar!.ctrlKey = ctrlKey
			toolbar!.metaKey = metaKey
			toolbar!.tabKey = tabKey
			toolbar!.moreKey = moreKey
			toolbar!.upKey = upKey
			toolbar!.downKey = downKey
			toolbar!.leftKey = leftKey
			toolbar!.rightKey = rightKey
			toolbar!.setUp()
		}

		setMoreRowVisible(false, animated: false)
		addSubview(moreToolbar)

		ctrlKey.addTarget(self,  action: #selector(self.ctrlKeyPressed), for: .touchUpInside)
		metaKey.addTarget(self,  action: #selector(self.inputKeyPressed), for: .touchUpInside)
		tabKey.addTarget(self,   action: #selector(self.inputKeyPressed), for: .touchUpInside)
		moreKey.addTarget(self,  action: #selector(self.moreKeyPressed), for: .touchUpInside)
		upKey.addTarget(self,    action: #selector(self.arrowKeyPressed), for: .touchUpInside)
		downKey.addTarget(self,  action: #selector(self.arrowKeyPressed), for: .touchUpInside)
		leftKey.addTarget(self,  action: #selector(self.arrowKeyPressed), for: .touchUpInside)
		rightKey.addTarget(self, action: #selector(self.arrowKeyPressed), for: .touchUpInside)

		moreToolbar.homeKey.addTarget(self,     action: #selector(self.inputKeyPressed), for: .touchUpInside)
		moreToolbar.endKey.addTarget(self,      action: #selector(self.inputKeyPressed), for: .touchUpInside)
		moreToolbar.pageUpKey.addTarget(self,   action: #selector(self.inputKeyPressed), for: .touchUpInside)
		moreToolbar.pageDownKey.addTarget(self, action: #selector(self.inputKeyPressed), for: .touchUpInside)
		moreToolbar.deleteKey.addTarget(self,   action: #selector(self.inputKeyPressed), for: .touchUpInside)

		for key in [ upKey, downKey, leftKey, rightKey ] {
			let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.arrowKeyLongPressed(_:)))
			key.addGestureRecognizer(gestureRecognizer)
		}

		NSLayoutConstraint.activate([
			ctrlKey.widthAnchor.constraint(greaterThanOrEqualTo: metaKey.widthAnchor),
			metaKey.widthAnchor.constraint(greaterThanOrEqualTo: ctrlKey.widthAnchor),
			metaKey.widthAnchor.constraint(greaterThanOrEqualTo: tabKey.widthAnchor),
			tabKey.widthAnchor.constraint(greaterThanOrEqualTo: metaKey.widthAnchor),
			tabKey.widthAnchor.constraint(greaterThanOrEqualTo: moreKey.widthAnchor),
			moreKey.widthAnchor.constraint(greaterThanOrEqualTo: tabKey.widthAnchor)
		])

		NSLayoutConstraint.activate([ upKey, downKey, leftKey, rightKey ].map { view in view.widthAnchor.constraint(equalTo: view.heightAnchor) })
		squareButtonConstraints = [ ctrlKey, metaKey, tabKey, moreKey ].map { view in view.widthAnchor.constraint(equalTo: view.heightAnchor) }

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
		preferencesUpdated()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var inputAccessoryView: UIView? {
		return toolbar
	}

	@objc func preferencesUpdated() {
		let preferences = Preferences.shared
		let style = preferences.keyboardAccessoryStyle

		for button in buttons {
			button.style = style
		}

		// enable 1:1 width:height aspect ratio if using icons style
		switch style {
		case .text:  NSLayoutConstraint.deactivate(squareButtonConstraints)
		case .icons: NSLayoutConstraint.activate(squareButtonConstraints)
		}
	}

	// MARK: - Callbacks

	@objc func ctrlKeyPressed() {
		ctrlDown = !ctrlDown
		ctrlKey.isSelected = ctrlDown
	}

	@objc func ctrlKeyCommandPressed(_ keyCommand: UIKeyCommand) {
		if keyCommand.input != nil {
			ctrlDown = true
			insertText(keyCommand.input!)
		}
	}

	@objc private func inputKeyPressed(_ sender: KeyboardButton) {
		let keyValues: [KeyboardButton: Data] = [
			metaKey:  metaKeyData,
			tabKey:   tabKeyData,
			moreToolbar.homeKey:     homeKeyData,
			moreToolbar.endKey:      endKeyData,
			moreToolbar.pageUpKey:   pageUpKeyData,
			moreToolbar.pageDownKey: pageDownKeyData,
			moreToolbar.deleteKey:   deleteKeyData
		]
		if let data = keyValues[sender] {
			terminalInputDelegate!.receiveKeyboardInput(data: data)
		}
	}

	@objc private func arrowKeyPressed(_ sender: KeyboardButton) {
		let keyValues: [KeyboardButton: Data] = [
			upKey:    upKeyData,
			downKey:  downKeyData,
			leftKey:  leftKeyData,
			rightKey: rightKeyData
		]
		let keyAppValues: [KeyboardButton: Data] = [
			upKey:    upKeyAppData,
			downKey:  downKeyAppData,
			leftKey:  leftKeyAppData,
			rightKey: rightKeyAppData
		]
		let values = terminalInputDelegate!.applicationCursor ? keyValues : keyAppValues
		if let data = values[sender] {
			terminalInputDelegate!.receiveKeyboardInput(data: data)
		}
	}

	@objc private func arrowRepeatTimerFired(_ timer: Timer) {
		arrowKeyPressed(timer.userInfo as! KeyboardButton)
	}

	@objc func moreKeyPressed() {
		setMoreRowVisible(moreToolbar.isHidden, animated: true)
	}
	
	@objc func arrowKeyLongPressed(_ sender: UILongPressGestureRecognizer) {
		switch sender.state {
		case .began:
			longPressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.arrowRepeatTimerFired), userInfo: sender.view, repeats: true)
			break

		case .ended, .cancelled:
			longPressTimer?.invalidate()
			longPressTimer = nil
			break

		default:
			break
		}
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
		_ = super.becomeFirstResponder()
		return true
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case #selector(self.paste(_:)):
			// only paste if the pasteboard contains a plaintext type
			return UIPasteboard.general.hasStrings || UIPasteboard.general.hasURLs

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
		if let data = UIPasteboard.general.string?.data(using: .utf8) {
			terminalInputDelegate!.receiveKeyboardInput(data: data)
		}
	}

}
