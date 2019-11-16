//
//  KeyboardToolbar.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class KeyboardToolbar: UIView {

	let backdropView = UIToolbar()

	let ctrlKey = KeyboardButton(title: "Control", glyph: "Ctrl", systemImage: "control", image: #imageLiteral(resourceName: "key-control"))
	let metaKey = KeyboardButton(title: "Escape", glyph: "Esc", systemImage: "escape", image: #imageLiteral(resourceName: "key-escape"))
	let tabKey = KeyboardButton(title: "Tab", glyph: "Tab", systemImage: "arrow.right.to.line", image: #imageLiteral(resourceName: "key-tab"))
	let moreKey = KeyboardButton(title: "Functions", glyph: "Fn", systemImage: "ellipsis", image: #imageLiteral(resourceName: "key-more"))

	let upKey = KeyboardButton(title: "Up", systemImage: "arrowtriangle.up", systemHighlightedImage: "arrowtriangle.up.fill", image: #imageLiteral(resourceName: "key-up"), highlightedImage: #imageLiteral(resourceName: "key-up-down"))
	let downKey = KeyboardButton(title: "Down", systemImage: "arrowtriangle.down", systemHighlightedImage: "arrowtriangle.down.fill", image: #imageLiteral(resourceName: "key-down"), highlightedImage: #imageLiteral(resourceName: "key-down-down"))
	let leftKey = KeyboardButton(title: "Left", systemImage: "arrowtriangle.left", systemHighlightedImage: "arrowtriangle.left.fill", image: #imageLiteral(resourceName: "key-left"), highlightedImage: #imageLiteral(resourceName: "key-left-down"))
	let rightKey = KeyboardButton(title: "Right", systemImage: "arrowtriangle.right", systemHighlightedImage: "arrowtriangle.right.fill", image: #imageLiteral(resourceName: "key-right"), highlightedImage: #imageLiteral(resourceName: "key-right-down"))

	var buttons: [KeyboardButton]!
	var squareButtonConstraints: [NSLayoutConstraint]!

	override init(frame: CGRect) {
		super.init(frame: frame)

		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		backdropView.delegate = self
		addSubview(backdropView)

		let height = isSmallDevice ? 36 : 44
		let outerXSpacing = CGFloat(3)
		let xSpacing = CGFloat(6)
		let topSpacing = CGFloat(isSmallDevice ? 2 : 4)
		let bottomSpacing = CGFloat(2)

		let spacerView = UIView()

		buttons = [
			ctrlKey, metaKey, tabKey, moreKey,
			upKey, downKey, leftKey, rightKey
		]

		let views = [
			"ctrlKey": ctrlKey,
			"metaKey": metaKey,
			"tabKey": tabKey,
			"moreKey": moreKey,
			"spacerView": spacerView,
			"upKey": upKey,
			"downKey": downKey,
			"leftKey": leftKey,
			"rightKey": rightKey,
		]

		let sortedViews = [
			ctrlKey, metaKey, tabKey, moreKey, spacerView,
			upKey, downKey, leftKey, rightKey
		]

		let stackView = UIStackView(arrangedSubviews: sortedViews)
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .horizontal
		stackView.spacing = xSpacing
		addSubview(stackView)

		addCompactConstraints([
			"self.height = height",
			"stackView.top = toolbar.top + topSpacing",
			"stackView.bottom = toolbar.bottom - bottomSpacing",
			"stackView.left = toolbar.left + outerXSpacing",
			"stackView.right = toolbar.right - outerXSpacing"
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
			"ctrlKey.width >= metaKey.width",
			"metaKey.width >= ctrlKey.width",
			"metaKey.width >= tabKey.width",
			"tabKey.width >= metaKey.width",
			"tabKey.width >= moreKey.width",
			"moreKey.width >= tabKey.width",
			"upKey.width = upKey.height",
			"downKey.width = downKey.height",
			"leftKey.width = leftKey.height",
			"rightKey.width = rightKey.height"
		], metrics: nil, views: views)

		squareButtonConstraints = NSLayoutConstraint.compactConstraints([
			"ctrlKey.width = ctrlKey.height",
			"metaKey.width = metaKey.height",
			"tabKey.width = tabKey.height",
			"moreKey.width = moreKey.height"
		], metrics: nil, views: views, self: self)

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

		// enable 1:1 width:height aspect ratio if using icons style
		switch style {
			case .text:
				NSLayoutConstraint.deactivate(squareButtonConstraints)
				break

			case .icons:
				NSLayoutConstraint.activate(squareButtonConstraints)
				break
		}
	}

	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.height = isSmallDevice ? 36 : 44
		return size
	}

}

extension KeyboardToolbar: UIToolbarDelegate {

	func position(for bar: UIBarPositioning) -> UIBarPosition {
		// helps UIToolbar figure out where to place the shadow line
		return .bottom
	}

}

extension KeyboardToolbar: UIInputViewAudioFeedback {

	var enableInputClicksWhenVisible: Bool {
		// conforming to <UIInputViewAudioFeedback> allows the buttons to make the click sound when tapped
		return true
	}

}
