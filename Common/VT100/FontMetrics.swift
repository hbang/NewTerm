//
//  FontMetrics.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 20/6/19.
//

import Foundation
import CoreText

@objc public class FontMetrics: NSObject {

	@objc public let regularFont: Font
	@objc public let boldFont: Font

	@objc public let ascent: CGFloat
	@objc public let descent: CGFloat
	@objc public let leading: CGFloat

	@objc public let boundingBox: CGSize

	init(regularFont: Font, boldFont: Font) {
		self.regularFont = regularFont
		self.boldFont = boldFont

		let attributedString = NSAttributedString(string: "A", attributes: [
			.font: regularFont
		])
		let line = CTLineCreateWithAttributedString(attributedString)

		var ascent = CGFloat(0)
		var descent = CGFloat(0)
		var leading = CGFloat(0)
		let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
		self.ascent = ascent
		self.descent = descent
		self.leading = leading

		boundingBox = CGSize(width: width, height: ascent + descent + leading)
	}

	override public var description: String {
		return "FontMetrics: regularFont = \(regularFont); boldFont = \(boldFont); boundingBox = \(boundingBox)"
	}

}
