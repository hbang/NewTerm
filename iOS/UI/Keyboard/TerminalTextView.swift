//
//  TerminalTextView.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class TerminalTextView: UITextView {

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)

		backgroundColor = .black
		showsHorizontalScrollIndicator = false
		alwaysBounceVertical = true
		dataDetectorTypes = [] // none
		isEditable = false
		textContainerInset = UIEdgeInsets()
		self.textContainer.lineFragmentPadding = 0
		self.textContainer.lineBreakMode = .byCharWrapping

		linkTextAttributes = [
			.underlineStyle: NSUnderlineStyle.single
		]
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
