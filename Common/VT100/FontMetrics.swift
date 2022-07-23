//
//  FontMetrics.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 20/6/19.
//

import UIKit
import CoreGraphics
import CoreText
import os.log

public struct FontMetrics: Hashable {

	public let regularFont: UIFont
	public let boldFont: UIFont
	public let italicFont: UIFont
	public let boldItalicFont: UIFont
	public let lightFont: UIFont
	public let lightItalicFont: UIFont

	public let width: CGFloat
	public let height: CGFloat

	public var boundingBox: CGSize { CGSize(width: width, height: height) }

	public static func loadFonts() {
		// Runtime load all fonts we’re interested in.
		// TODO: This should only load the fonts the user wants.
		guard let listing = try? FileManager.default.contentsOfDirectory(at: Bundle.main.resourceURL!,
																																		 includingPropertiesForKeys: nil,
																																		 options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) else {
			return
		}
		let fonts = listing.filter { item in item.pathExtension == "ttf" || item.pathExtension == "otf" }
		for font in fonts {
			var cfErrorWrapper: Unmanaged<CFError>? = nil
			CTFontManagerRegisterFontsForURL(font as CFURL, .process, &cfErrorWrapper)
			if let cfError = cfErrorWrapper?.takeUnretainedValue() {
				Logger().error("Error loading font \(font.lastPathComponent): \(String(describing: cfError))")
			}
		}
	}

	public init(font: AppFont, fontSize: CGFloat) {
		var regularFont: UIFont?
		var boldFont: UIFont?
		var italicFont: UIFont?
		var boldItalicFont: UIFont?
		var lightFont: UIFont?
		var lightItalicFont: UIFont?

		if font.systemMonospaceFont ?? false {
			if let name = font.regular {
				regularFont = UIFont(name: name, size: fontSize)
			}
			if let name = font.bold {
				boldFont = UIFont(name: name, size: fontSize)
			}
			if let name = font.italic {
				italicFont = UIFont(name: name, size: fontSize)
			}
			if let name = font.boldItalic {
				boldItalicFont = UIFont(name: name, size: fontSize)
			}
			if let name = font.light {
				lightFont = UIFont(name: name, size: fontSize)
			}
			if let name = font.lightItalic {
				lightItalicFont = UIFont(name: name, size: fontSize)
			}
		}

		if regularFont == nil || boldFont == nil {
			if font.systemMonospaceFont != true {
				Logger().error("Font \(font.regular ?? "?") size \(fontSize, format: .fixed(precision: 1)) could not be initialised")
			}

			regularFont = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
			boldFont = .monospacedSystemFont(ofSize: fontSize, weight: .bold)
			lightFont = .monospacedSystemFont(ofSize: fontSize, weight: .light)

			if let fontDescriptor = regularFont?.fontDescriptor.withSymbolicTraits(.traitItalic) {
				italicFont = UIFont(descriptor: fontDescriptor, size: fontSize)
			}
			if let fontDescriptor = boldFont?.fontDescriptor.withSymbolicTraits(.traitItalic) {
				boldItalicFont = UIFont(descriptor: fontDescriptor, size: fontSize)
			}
			if let fontDescriptor = lightFont?.fontDescriptor.withSymbolicTraits(.traitItalic) {
				lightItalicFont = UIFont(descriptor: fontDescriptor, size: fontSize)
			}
		}

		self.init(regularFont: regularFont!,
							boldFont: boldFont,
							italicFont: italicFont,
							boldItalicFont: boldItalicFont,
							lightFont: lightFont,
							lightItalicFont: lightItalicFont)
	}

	public init(regularFont: UIFont, boldFont: UIFont?, italicFont: UIFont?, boldItalicFont: UIFont?, lightFont: UIFont?, lightItalicFont: UIFont?) {
		self.regularFont = regularFont
		self.boldFont = boldFont ?? regularFont
		self.italicFont = italicFont ?? regularFont
		self.boldItalicFont = boldItalicFont ?? boldFont ?? regularFont
		self.lightFont = lightFont ?? regularFont
		self.lightItalicFont = lightFont ?? italicFont ?? regularFont

		// Determine the bounding box of a single letter in this font. This, of course, assumes all
		// characters in this font (and its variants) are the same width, but that’s an assumption most
		// terminals/text editors make anyway.
		let attributedString = NSAttributedString(string: "A",
																							attributes: [.font: regularFont])
		let line = CTLineCreateWithAttributedString(attributedString)

		var ascent: CGFloat = 0
		var descent: CGFloat = 0
		var leading: CGFloat = 0
		self.width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
		self.height = ascent + descent + leading
	}

}
