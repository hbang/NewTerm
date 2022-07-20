//
//  StringSupplier.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 2/4/21.
//

import Foundation
import SwiftTerm
import SwiftUI

extension View {
	static func + (lhs: Self, rhs: some View) -> AnyView {
		AnyView(ViewBuilder.buildBlock(lhs, AnyView(rhs)))
	}
}

open class StringSupplier {

	open var terminal: Terminal?
	open var colorMap: ColorMap?
	open var fontMetrics: FontMetrics?

	public init() {}

	public func attributedString() -> [AnyView] {
		guard let terminal = terminal else {
			fatalError()
		}

		let cursorPosition = terminal.getCursorLocation()
		let scrollbackRows = terminal.getTopVisibleRow()

		var lastAttribute = Attribute.empty
		return Array(0..<terminal.rows + scrollbackRows).map { i in
			guard let line = terminal.getScrollInvariantLine(row: i) else {
				return AnyView(EmptyView())
			}

			var views = [any View]()
			var buffer = ""
			for j in 0..<terminal.cols {
				let data = line[j]
				let isCursor = i - scrollbackRows == cursorPosition.y && j == cursorPosition.x

				if isCursor || lastAttribute != data.attribute {
					// Finish up the last run by appending it to the attributed string, then reset for the
					// next run.
					views.append(text(buffer, attribute: lastAttribute))
					lastAttribute = data.attribute
					buffer.removeAll()
				}

				let character = data.getCharacter()
				buffer.append(character == "\0" ? " " : character)

				if isCursor {
					// We may need to insert a space for the cursor to show up.
					if buffer.isEmpty {
						buffer.append(" ") // Non-breaking space
					}

					views.append(text(buffer, attribute: lastAttribute, isCursor: true))
					buffer.removeAll()
				}
			}

			// Append the final run
			views.append(text(buffer, attribute: lastAttribute))

			return AnyView(HStack(alignment: .firstTextBaseline, spacing: 0) {
				views.reduce(AnyView(EmptyView()), { $0 + AnyView($1) })
			})
		}
	}

	private func text(_ run: String, attribute: Attribute, isCursor: Bool = false) -> any View {
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

		let foreground = colorMap?.color(for: fgColor,
																		 isForeground: true,
																		 isBold: attribute.style.contains(.bold),
																		 isCursor: isCursor)
		let background = colorMap?.color(for: bgColor,
																		 isForeground: false,
																		 isCursor: isCursor)

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

		return Text(run)
			.foregroundColor(Color(foreground ?? .white))
			.font(Font(font ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)))
			.underline(attribute.style.contains(.underline))
			.strikethrough(attribute.style.contains(.crossedOut))
			.kerning(0)
			.tracking(0)
			.background(Color(background ?? .black))
	}

}
