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
	let deleteKey = KeyboardButton(title: "Delete Forward", systemImage: "delete.right", systemHighlightedImage: "delete.right.fill", image: #imageLiteral(resourceName: "key-delete-forward"), highlightedImage: #imageLiteral(resourceName: "key-delete-forward-down"))

	var buttons: [KeyboardButton]!

	override init(frame: CGRect) {
		super.init(frame: frame)

		translatesAutoresizingMaskIntoConstraints = false

		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		backdropView.delegate = self
		addSubview(backdropView)

		let height = isSmallDevice ? 37 : 45
		let outerXSpacing = CGFloat(3)
		let xSpacing = CGFloat(6)
		let topSpacing = CGFloat(isSmallDevice ? 2 : 3)
		let bottomSpacing = CGFloat(isSmallDevice ? 3 : 4)

		let homeEndSpacerView = UIView()
		let pageUpDownSpacerView = UIView()
		let deleteSpacerView = UIView()

		homeEndSpacerView.translatesAutoresizingMaskIntoConstraints = false
		pageUpDownSpacerView.translatesAutoresizingMaskIntoConstraints = false
		deleteSpacerView.translatesAutoresizingMaskIntoConstraints = false

		homeEndSpacerView.addCompactConstraint("self.width = 0", metrics: nil, views: nil)
		pageUpDownSpacerView.addCompactConstraint("self.width = 0", metrics: nil, views: nil)

		buttons = [
			homeKey, endKey,
			pageUpKey, pageDownKey,
			deleteKey
		]

		let views = [
			"homeKey": homeKey,
			"endKey": endKey,
			"homeEndSpacerView": homeEndSpacerView,
			"pageUpKey": pageUpKey,
			"pageDownKey": pageDownKey,
			"pageUpDownSpacerView": pageUpDownSpacerView,
			"deleteKey": deleteKey,
			"deleteSpacerView": deleteSpacerView
		]

		let sortedViews = [
			homeKey, endKey, pageUpDownSpacerView,
			pageUpKey, pageDownKey, homeEndSpacerView,
			deleteKey, deleteSpacerView
		]

		let stackView = UIStackView(arrangedSubviews: sortedViews)
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .horizontal
		stackView.spacing = xSpacing
		addSubview(stackView)

		let safeArea: String
		if #available(iOS 11.0, *) {
			safeArea = "safe"
		} else {
			safeArea = "toolbar"
		}

		addCompactConstraints([
			"self.height = height",
			"stackView.top = toolbar.top + topSpacing",
			"stackView.bottom = toolbar.bottom - bottomSpacing",
			"stackView.left = \(safeArea).left + outerXSpacing",
			"stackView.right <= \(safeArea).right - outerXSpacing"
		], metrics: [
			"height": height,
			"outerXSpacing": outerXSpacing,
			"topSpacing": topSpacing,
			"bottomSpacing": bottomSpacing
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
			"deleteKey.width >= deleteKey.height"
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
		size.height = isSmallDevice ? 37 : 45
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
