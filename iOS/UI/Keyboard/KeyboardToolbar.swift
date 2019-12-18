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

	var ctrlKey: KeyboardButton!
	var metaKey: KeyboardButton!
	var tabKey: KeyboardButton!
	var moreKey: KeyboardButton!

	var upKey: KeyboardButton!
	var downKey: KeyboardButton!
	var leftKey: KeyboardButton!
	var rightKey: KeyboardButton!

	func setUp() {
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

		let sortedViews: [UIView] = [
			ctrlKey, metaKey, tabKey, moreKey, spacerView,
			upKey, downKey, leftKey, rightKey
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
			"stackView.right = \(safeArea).right - outerXSpacing"
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
