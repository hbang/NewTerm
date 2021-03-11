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
		if #available(iOS 13, *) {
		} else {
			indicatorStyle = .white
		}
		showsHorizontalScrollIndicator = false
		alwaysBounceVertical = true
		dataDetectorTypes = [] // none
		isEditable = false
		textContainerInset = UIEdgeInsets()
		self.textContainer.lineFragmentPadding = 0

		linkTextAttributes = [
			.underlineStyle: NSUnderlineStyle.single
		]
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIResponder

	override func becomeFirstResponder() -> Bool {
		// We aren’t meant to ever become first responder. That’s the job of TerminalKeyInput
		return false
	}

	// MARK: - UITextInput

	override func caretRect(for position: UITextPosition) -> CGRect {
		// TODO: Should we take advantage of this?
		return .zero
	}

}
