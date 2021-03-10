//
//  FontMetrics.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 20/6/19.
//

import Foundation
import CoreGraphics
import CoreText
import os.log

@objc public class FontMetrics: NSObject {

	@objc public let regularFont: Font
	@objc public let boldFont: Font

	@objc public let ascent: CGFloat
	@objc public let descent: CGFloat
	@objc public let leading: CGFloat

	@objc public let boundingBox: CGSize

	class func loadFonts() {
		// Runtime load all fonts we’re interested in.
		// TODO: This should only load the fonts the user wants.
		guard let listing = try? FileManager.default.contentsOfDirectory(at: Bundle.main.resourceURL!, includingPropertiesForKeys: nil, options: [ .skipsSubdirectoryDescendants, .skipsHiddenFiles ]) else {
			return
		}
		let fonts = listing.filter { item in item.pathExtension == "ttf" || item.pathExtension == "otf" }
		if fonts.count > 0 {
			var cfErrorsWrapper: Unmanaged<CFArray>? = nil
			CTFontManagerRegisterFontsForURLs(fonts as CFArray, .process, &cfErrorsWrapper)
			if let cfErrors = cfErrorsWrapper?.takeUnretainedValue(),
				let errors = cfErrors as? [NSError] {
				os_log("%{public}li error(s) loading fonts: %{public}@", type: .error, errors.count, errors)
			}
		}
	}

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
