//
//  KeyboardToolbar.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class KeyboardToolbar: UIView {

	var ctrlKey: KeyboardButton!
	var metaKey: KeyboardButton!
	var tabKey: KeyboardButton!
	var moreKey: KeyboardButton!

	var upKey: KeyboardButton!
	var downKey: KeyboardButton!
	var leftKey: KeyboardButton!
	var rightKey: KeyboardButton!

	func setUp() {
		let backdropView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		addSubview(backdropView)

		let backdropColorView = UIView()
		backdropColorView.frame = backdropView.contentView.bounds
		backdropColorView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		backdropColorView.backgroundColor = .keyboardToolbarBackground
		backdropView.contentView.addSubview(backdropColorView)

		let height = isSmallDevice ? 35 : 43
		let outerXSpacing = CGFloat(3)
		let xSpacing = CGFloat(6)
		let topSpacing = CGFloat(isSmallDevice ? 2 : 4)
		let bottomSpacing = CGFloat(1)

		let spacerView = UIView()

		let sortedViews: [UIView] = [
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
			"stackView.left = safe.left + outerXSpacing",
			"stackView.right = safe.right - outerXSpacing"
		], metrics: [
			"height": height,
			"outerXSpacing": outerXSpacing,
			"topSpacing": topSpacing,
			"bottomSpacing": bottomSpacing
		], views: [
			"toolbar": self,
			"stackView": stackView
		])
	}

	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.height = isSmallDevice ? 36 : 44
		return size
	}

}

extension KeyboardToolbar: UIToolbarDelegate {

	func position(for bar: UIBarPositioning) -> UIBarPosition {
		// Helps UIToolbar figure out where to place the shadow line
		return .bottom
	}

}

extension KeyboardToolbar: UIInputViewAudioFeedback {

	var enableInputClicksWhenVisible: Bool {
		// Conforming to <UIInputViewAudioFeedback> allows the buttons to make the click sound
		// when tapped
		return true
	}

}
