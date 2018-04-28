//
//  KeyboardToolbar.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class KeyboardToolbar: UIToolbar {
	
	@objc let ctrlKey = KeyboardButton(title: "Ctrl")
	@objc let metaKey = KeyboardButton(title: "Esc")
	@objc let tabKey = KeyboardButton(title: "Tab")
	
	@objc let upKey = KeyboardButton(title: "▲")
	@objc let downKey = KeyboardButton(title: "▼")
	@objc let leftKey = KeyboardButton(title: "◀")
	@objc let rightKey = KeyboardButton(title: "▶")
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		let spacerView = UIView()
		
		for view in [ ctrlKey, metaKey, tabKey, spacerView, upKey, downKey, leftKey, rightKey ] {
			view.translatesAutoresizingMaskIntoConstraints = false
			addSubview(view)
			
			addConstraints(withVisualFormat: "V:|-margin-[key]-margin-|", options: NSLayoutFormatOptions(), metrics: [
				"margin": isSmallDevice ? 2 : 4
			], views: [
				"key": view
			])
		}
		
		addConstraints(withVisualFormat: "H:|-outerMargin-[ctrlKey]-margin-[metaKey]-margin-[tabKey][spacerView(>=margin)][upKey]-margin-[downKey]-margin-[leftKey]-margin-[rightKey]-outerMargin-|", options: NSLayoutFormatOptions(), metrics: [
			"outerMargin": 3,
			"margin": 6
		], views: [
			"ctrlKey": ctrlKey,
			"metaKey": metaKey,
			"tabKey": tabKey,
			"spacerView": spacerView,
			"upKey": upKey,
			"downKey": downKey,
			"leftKey": leftKey,
			"rightKey": rightKey,
		])
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
