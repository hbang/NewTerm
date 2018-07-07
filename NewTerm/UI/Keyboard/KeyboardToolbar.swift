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
	
	let upKey = KeyboardButton(title: "▲")
	let downKey = KeyboardButton(title: "▼")
	let leftKey = KeyboardButton(title: "◀")
	let rightKey = KeyboardButton(title: "▶")
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		addSubview(backdropView)

		let spacerView = UIView()

		let views = [
			"ctrlKey": ctrlKey,
			"metaKey": metaKey,
			"tabKey": tabKey,
			"spacerView": spacerView,
			"upKey": upKey,
			"downKey": downKey,
			"leftKey": leftKey,
			"rightKey": rightKey,
		]

		let outerXSpacing = CGFloat(3)
		let xSpacing = CGFloat(6)
		let topSpacing = CGFloat(isSmallDevice ? 2 : 4)
		let bottomSpacing = CGFloat(isSmallDevice ? 0 : 2)
		
		if #available(iOS 9.0, *) {
			let sortedViews = [ ctrlKey, metaKey, tabKey, spacerView, upKey, downKey, leftKey, rightKey ]

			let stackView = UIStackView(arrangedSubviews: sortedViews)
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
			
			addConstraints(withVisualFormat: "H:|-outerMargin-[ctrlKey]-margin-[metaKey]-margin-[tabKey][spacerView(>=margin)][upKey]-margin-[downKey]-margin-[leftKey]-margin-[rightKey]-outerMargin-|", options: .init(), metrics: [
				"outerMargin": outerXSpacing,
				"margin": xSpacing
			], views: views)
		}
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
