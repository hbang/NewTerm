//
//  TextInputBase.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class TextInputBase: UIView, UIKeyInput, UITextInput, UITextInputTraits {
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		tokenizer = UITextInputStringTokenizer(textInput: self)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var hasText: Bool {
		return false
	}
	
	func insertText(_ text: String) {}
	func deleteBackward() {}
	
	func text(in range: UITextRange) -> String? {
		return nil
	}
	
	func replace(_ range: UITextRange, withText text: String) {}
	
	var selectedTextRange: UITextRange?
	var markedTextRange: UITextRange?
	var markedTextStyle: [AnyHashable : Any]?
	
	func setMarkedText(_ markedText: String?, selectedRange: NSRange) {}
	func unmarkText() {}
	
	var beginningOfDocument: UITextPosition = UITextPosition()
	var endOfDocument: UITextPosition = UITextPosition()
	
	func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
		return nil
	}
	
	func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
		return nil
	}
	
	func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
		return nil
	}
	
	func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
		guard let a = position as? TextPosition, let b = position as? TextPosition else {
			// orderedSame is 0, which is what the original implementation of this method would have
			// returned if both objects were nil and we attempted to call NSNumber.compare(_:)
			return .orderedSame
		}
		
		if a.position > b.position {
			return .orderedAscending
		} else if a.position < b.position {
			return .orderedDescending
		} else {
			return .orderedSame
		}
	}
	
	func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
		return 0
	}
	
	var inputDelegate: UITextInputDelegate?
	var tokenizer: UITextInputTokenizer!
	
	func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
		return nil
	}
	
	func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
		return nil
	}
	
	func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> UITextWritingDirection {
		return .natural
	}
	
	func setBaseWritingDirection(_ writingDirection: UITextWritingDirection, for range: UITextRange) {}
	
	func firstRect(for range: UITextRange) -> CGRect {
		return .zero
	}
	
	func caretRect(for position: UITextPosition) -> CGRect {
		return .zero
	}
	
	func selectionRects(for range: UITextRange) -> [Any] {
		return []
	}
	
	func closestPosition(to point: CGPoint) -> UITextPosition? {
		let position = TextPosition()
		position.position = point.x
		return position
	}
	
	func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
		let position = TextPosition()
		position.position = point.x
		return position
	}
	
	func characterRange(at point: CGPoint) -> UITextRange? {
		return nil
	}
	
	var autocapitalizationType = UITextAutocapitalizationType.sentences
	var autocorrectionType = UITextAutocorrectionType.default
	var spellCheckingType = UITextSpellCheckingType.default
//	var smartQuotesType = UITextSmartQuotesType.default
//	var smartDashesType = UITextSmartDashesType.default
//	var smartInsertDeleteType = UITextSmartInsertDeleteType.default
	var keyboardType = UIKeyboardType.default
	var keyboardAppearance = UIKeyboardAppearance.default
	var returnKeyType = UIReturnKeyType.default
	var enablesReturnKeyAutomatically = false
	var isSecureTextEntry = false
	var textContentType: UITextContentType? = nil
	
}
