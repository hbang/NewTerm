//
//  KeyboardPopupToolbar.swift
//  NewTerm
//
//  Created by Adam Demasi on 7/7/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class KeyboardPopupToolbar: UIView {

	let backdropView = UIToolbar()

	let homeKey = KeyboardButton(title: "Home", glyph: "Home")
	let endKey = KeyboardButton(title: "End", glyph: "End")
	let pageUpKey = KeyboardButton(title: "Page Up", glyph: "PgUp")
	let pageDownKey = KeyboardButton(title: "Page Down", glyph: "PgDn")
	let deleteKey = KeyboardButton(title: "Delete Forward", image: #imageLiteral(resourceName: "key-delete-forward"), highlightedImage: #imageLiteral(resourceName: "key-delete-forward-down"))
	let settingsKey = KeyboardButton(title: "Settings", image: #imageLiteral(resourceName: "key-settings"))

	var buttons: [KeyboardButton]!

	override init(frame: CGRect) {
		super.init(frame: frame)

		translatesAutoresizingMaskIntoConstraints = false

		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		backdropView.delegate = self
		addSubview(backdropView)

		let height = isSmallDevice ? 36 : 44
		let outerXSpacing = CGFloat(3)
		let xSpacing = CGFloat(6)
		let ySpacing = CGFloat(isSmallDevice ? 2 : 4)

		let homeEndSpacerView = UIView()
		let pageUpDownSpacerView = UIView()
		let deleteSpacerView = UIView()

		homeEndSpacerView.translatesAutoresizingMaskIntoConstraints = false
		pageUpDownSpacerView.translatesAutoresizingMaskIntoConstraints = false
		deleteSpacerView.translatesAutoresizingMaskIntoConstraints = false

		homeEndSpacerView.addCompactConstraint("self.width = 0", metrics: nil, views: nil)
		pageUpDownSpacerView.addCompactConstraint("self.width = 0", metrics: nil, views: nil)
		deleteSpacerView.addCompactConstraint("self.width <= max", metrics: [
			"max": CGFloat.greatestFiniteMagnitude
		], views: nil)

		deleteKey.titleLabel!.font = UIFont(name: "Helvetica Neue", size: deleteKey.titleLabel!.font.pointSize)

		buttons = [
			homeKey, endKey,
			pageUpKey, pageDownKey,
			deleteKey,
			settingsKey
		]

		let views = [
			"homeKey": homeKey,
			"endKey": endKey,
			"homeEndSpacerView": homeEndSpacerView,
			"pageUpKey": pageUpKey,
			"pageDownKey": pageDownKey,
			"pageUpDownSpacerView": pageUpDownSpacerView,
			"deleteKey": deleteKey,
			"deleteSpacerView": deleteSpacerView,
			"settingsKey": settingsKey
		]

		let sortedViews = [
			homeKey, endKey, pageUpDownSpacerView,
			pageUpKey, pageDownKey, homeEndSpacerView,
			deleteKey, deleteSpacerView,
			settingsKey
		]

		let stackView = UIStackView(arrangedSubviews: sortedViews)
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .horizontal
		stackView.spacing = xSpacing
		addSubview(stackView)

		addCompactConstraints([
			"self.height = height",
			"stackView.top = toolbar.top + ySpacing",
			"stackView.bottom = toolbar.bottom - ySpacing",
			"stackView.left = toolbar.left + outerXSpacing",
			"stackView.right = toolbar.right - outerXSpacing"
		], metrics: [
			"height": height,
			"outerXSpacing": outerXSpacing,
			"ySpacing": ySpacing
		], views: [
			"toolbar": self,
			"stackView": stackView
		])

		stackView.addCompactConstraints([
			"homeKey.width >= endKey.width",
			"endKey.width >= homeKey.width",
			"endKey.width >= pageUpKey.width",
			"pageUpKey.width >= endKey.width",
			"pageUpKey.width >= pageDownKey.width",
			"pageDownKey.width >= pageUpKey.width",
			"deleteKey.width >= deleteKey.height",
			"settingsKey.width >= settingsKey.height"
		], metrics: nil, views: views)

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
		preferencesUpdated()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc func preferencesUpdated() {
		let preferences = Preferences.shared
		let style = preferences.keyboardAccessoryStyle

		for button in buttons {
			button.style = style
		}
	}

	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.height = isSmallDevice ? 36 : 44
		return size
	}

}

extension KeyboardPopupToolbar: UIToolbarDelegate {

	func position(for bar: UIBarPositioning) -> UIBarPosition {
		// helps UIToolbar figure out where to place the shadow line
		return .bottom
	}

}

extension KeyboardPopupToolbar: UIInputViewAudioFeedback {

	var enableInputClicksWhenVisible: Bool {
		// conforming to <UIInputViewAudioFeedback> allows the buttons to make the click sound when tapped
		return true
	}

}
