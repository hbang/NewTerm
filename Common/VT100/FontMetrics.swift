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
	@objc public let italicFont: Font
	@objc public let boldItalicFont: Font

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
			if #available(iOS 13, *) {
				for font in fonts {
					var cfErrorWrapper: Unmanaged<CFError>? = nil
					CTFontManagerRegisterFontsForURL(font as CFURL, .process, &cfErrorWrapper)
					if let cfError = cfErrorWrapper?.takeUnretainedValue() {
						os_log("error loading font %{public}@: %{public}@", type: .error, font.lastPathComponent, String(describing: cfError))
					}
				}
			} else {
				var cfErrorsWrapper: Unmanaged<CFArray>? = nil
				CTFontManagerRegisterFontsForURLs(fonts as CFArray, .process, &cfErrorsWrapper)
				if let cfErrors = cfErrorsWrapper?.takeUnretainedValue(),
					let errors = cfErrors as? [NSError] {
					os_log("%{public}li error(s) loading fonts: %{public}@", type: .error, errors.count, errors)
				}
			}
		}
	}

	init(regularFont: Font, boldFont: Font, italicFont: Font, boldItalicFont: Font) {
		self.regularFont = regularFont
		self.boldFont = boldFont
		self.italicFont = italicFont
		self.boldItalicFont = boldItalicFont

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
		return "FontMetrics: regularFont = \(regularFont); boldFont = \(boldFont); italicFont = \(italicFont); boldItalicFont = \(boldItalicFont); boundingBox = \(boundingBox)"
	}

}
