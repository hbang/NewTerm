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
	
	let ctrlKey = KeyboardButton(title: "Ctrl")
	let metaKey = KeyboardButton(title: "Esc")
	let tabKey = KeyboardButton(title: "Tab")
	let moreKey = KeyboardButton(title: "Fn")
	
	let upKey = KeyboardButton(title: "Up", glyph: "▲")
	let downKey = KeyboardButton(title: "Down", glyph: "▼")
	let leftKey = KeyboardButton(title: "Left", glyph: "◀")
	let rightKey = KeyboardButton(title: "Right", glyph: "▶")
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		addSubview(backdropView)

		let outerXSpacing = CGFloat(3)
		let xSpacing = CGFloat(6)
		let topSpacing = CGFloat(isSmallDevice ? 2 : 4)
		let bottomSpacing = CGFloat(isSmallDevice ? 0 : 2)

		let spacerView = UIView()

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

		let containerView: UIView
		
		if #available(iOS 9.0, *) {
			let sortedViews = [
				ctrlKey, metaKey, tabKey, moreKey, spacerView,
				upKey, downKey, leftKey, rightKey
			]

			let stackView = UIStackView(arrangedSubviews: sortedViews)
			containerView = stackView
			stackView.translatesAutoresizingMaskIntoConstraints = false
			stackView.axis = .horizontal
			stackView.spacing = xSpacing
			addSubview(stackView)

			addCompactConstraints([
				"stackView.top = toolbar.top + topSpacing",
				"stackView.bottom = toolbar.bottom - bottomSpacing",
				"stackView.left = toolbar.left + outerXSpacing",
				"stackView.right = toolbar.right - outerXSpacing"
			], metrics: [
				"outerXSpacing": outerXSpacing,
				"topSpacing": topSpacing,
				"bottomSpacing": bottomSpacing
			], views: [
				"toolbar": self,
				"stackView": stackView
			])
		} else {
			containerView = self

			// do it the hard way with constraints
			for view in views.values {
				view.translatesAutoresizingMaskIntoConstraints = false
				addSubview(view)
				
				addConstraints(withVisualFormat: "V:|-topSpacing-[key]-bottomSpacing-|", options: .init(), metrics: [
					"topSpacing": topSpacing,
					"bottomSpacing": bottomSpacing
				], views: [
					"key": view
				])
			}
			
			addConstraints(withVisualFormat: "H:|-outerMargin-[ctrlKey]-margin-[metaKey]-margin-[tabKey]-margin-[moreKey][spacerView(>=margin)][upKey]-margin-[downKey]-margin-[leftKey]-margin-[rightKey]-outerMargin-|", options: .init(), metrics: [
				"outerMargin": outerXSpacing,
				"margin": xSpacing
			], views: views)
		}

		containerView.addCompactConstraints([
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
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.height = isSmallDevice ? 32 : 40
		return size
	}
	
}

extension KeyboardToolbar: UIInputViewAudioFeedback {
	
	var enableInputClicksWhenVisible: Bool {
		// conforming to <UIInputViewAudioFeedback> allows the buttons to make the click sound when tapped
		return true
	}
	
}
