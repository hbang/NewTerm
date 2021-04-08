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

		let cursorPosition = terminal.getCursorLocation()

		let attributedString = NSMutableAttributedString()
		var lastAttribute = Attribute.empty

		let scrollbackRows = terminal.getTopVisibleRow()
		let totalRows = terminal.rows + scrollbackRows
		for i in 0..<totalRows {
			guard let line = terminal.getScrollInvariantLine(row: i) else {
				continue
			}

			var buffer = ""
			for j in 0..<terminal.cols {
				let data = line[j]
				let isCursor = i - scrollbackRows == cursorPosition.y && j == cursorPosition.x

				if isCursor || lastAttribute != data.attribute {
					// Finish up the last run by appending it to the attributed string, then reset for the
					// next run.
					let runAttributeString = NSAttributedString(string: buffer,
																											attributes: stringAttributes(for: lastAttribute))
					attributedString.append(runAttributeString)

					lastAttribute = data.attribute
					buffer.removeAll()
				}

				let character = data.getCharacter()
				if j == terminal.cols - 1 {
					// UITextView won’t render a massive line of spaces (e.g. an empty nano screen), so add a
					// newline if the line ends with a space.
					if buffer.last == " " {
						// TODO: This is crazy. There has to be a better way to stop spaces from being collapsed
						buffer.removeLast()
						buffer.append("\u{A0}") // Non-breaking space
					} else if character != "\0" {
						buffer.append(character)
					}
					if i != totalRows - 1 {
						buffer.append("\n")
					}
				} else if character == "\0" {
					buffer.append(" ")
				} else {
					buffer.append(character)
				}

				if isCursor {
					// We may need to insert a space for the cursor to show up.
					if buffer.isEmpty {
						buffer.append("\u{A0}") // Non-breaking space
					}

					let runAttributeString = NSAttributedString(string: buffer,
																											attributes: stringAttributes(for: lastAttribute, isCursor: true))
					attributedString.append(runAttributeString)

					buffer.removeAll()
				}
			}

			// Append the final run
			let runAttributeString = NSAttributedString(string: buffer,
																									attributes: stringAttributes(for: lastAttribute))
			attributedString.append(runAttributeString)
		}

		return attributedString
	}

	private func stringAttributes(for attribute: Attribute, isCursor: Bool = false) -> [NSAttributedString.Key: Any] {
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
																												 isBold: attribute.style.contains(.bold),
																												 isCursor: isCursor)
		stringAttributes[.backgroundColor] = colorMap?.color(for: bgColor,
																												 isForeground: false,
																												 isCursor: isCursor)

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

}
