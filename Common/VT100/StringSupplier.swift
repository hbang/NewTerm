//
//  StringSupplier.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 2/4/21.
//

import Foundation
import SwiftTerm

open class StringSupplier {

	open var terminal: Terminal?
	open var colorMap: ColorMap?
	open var fontMetrics: FontMetrics?

	public init() {}

	public func attributedString() -> NSAttributedString {
		guard let terminal = terminal else {
			fatalError()
		}

		// TODO
		let cursorPosition = terminal.getCursorLocation()

		let attributedString = NSMutableAttributedString()

		var lines = [String]()
		var lastAttribute = Attribute.empty
		for i in 0..<terminal.rows {
			guard let line = terminal.getLine(row: i) else {
				lines.append("???")
				continue
			}

			var buffer = ""

			for i in 0..<terminal.cols {
				let data = line[i]
				if lastAttribute != data.attribute {
					// Finish up the last run by appending it to the attributed string, then reset for the
					// next run.
					let runAttributeString = NSAttributedString(string: buffer,
																											attributes: stringAttributes(for: lastAttribute))
					attributedString.append(runAttributeString)

					lastAttribute = data.attribute
					buffer = ""
				}

				let character = data.getCharacter()
				if i == terminal.cols - 1 {
					// UITextView won’t render a massive line of spaces (e.g. an empty nano screen), so add a
					// newline if the line ends with a space.
					if buffer.last == " " {
						// TODO: This is crazy. There has to be a better way to stop spaces from being collapsed
						buffer.removeLast()
						buffer.append("\u{A0}") // Non-breaking space
					} else {
						buffer.append(character)
					}
					buffer.append("\n")
				} else {
					buffer.append(character)
				}
			}

			// Append the final run
			let runAttributeString = NSAttributedString(string: buffer,
																									attributes: stringAttributes(for: lastAttribute))
			attributedString.append(runAttributeString)
		}

		return attributedString
	}

	private func stringAttributes(for attribute: Attribute) -> [NSAttributedString.Key: Any] {
		var stringAttributes = [NSAttributedString.Key: Any]()
		var fgColor = attribute.fg
		var bgColor = attribute.bg

		if attribute.style.contains(.inverse) {
			swap(&bgColor, &fgColor)
			if fgColor == .defaultColor {
				fgColor = .defaultInvertedColor
			}
			if bgColor == .defaultColor {
				bgColor = .defaultInvertedColor
			}
		}

		stringAttributes[.foregroundColor] = colorMap?.color(for: fgColor,
																												 isForeground: true,
																												 isBold: attribute.style.contains(.bold))
		stringAttributes[.backgroundColor] = colorMap?.color(for: bgColor,
																												 isForeground: false,
																												 isBold: false)

		if attribute.style.contains(.underline) {
			stringAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
		}
		if attribute.style.contains(.crossedOut) {
			stringAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
		}

		let font: UIFont?
		if attribute.style.contains(.bold) {
			if attribute.style.contains(.italic) {
				font = fontMetrics?.boldItalicFont
			} else {
				font = fontMetrics?.boldFont
			}
		} else {
			if attribute.style.contains(.italic) {
				font = fontMetrics?.italicFont
			} else {
				font = fontMetrics?.regularFont
			}
		}
		stringAttributes[.font] = font

		return stringAttributes
	}

	// TODO
	public func rowCount() -> Int32 { 0 }
	public func string(forLine rowIndex: Int32) -> String! { nil }

}
