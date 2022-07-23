//
//  ColorMap.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 2/4/21.
//

import UIKit
import SwiftTerm
import os.log

public enum AnsiColorCode: Int, CaseIterable {
	case black, red, green, yellow, blue, purple, cyan, white
	case brightBlack, brightRed, brightGreen, brightYellow
	case brightBlue, brightPurple, brightCyan, brightWhite
}

public struct ColorMap: Hashable {

	public let background: UIColor
	public let foreground: UIColor
	public let foregroundBold: UIColor
	public let foregroundCursor: UIColor
	public let backgroundCursor: UIColor

	public let ansiColors: [AnsiColorCode: UIColor]

	public let isDark: Bool

	public var userInterfaceStyle: UIUserInterfaceStyle { isDark ? .dark : .light }

	private var colorCache = [Attribute.Color: UIColor]()

	public init(theme: AppTheme) {
		background = UIColor(propertyListValue: theme.background) ?? .systemGroupedBackground
		foreground = UIColor(propertyListValue: theme.text) ?? .systemGray6
		foregroundBold = UIColor(propertyListValue: theme.boldText) ?? .label
		foregroundCursor = UIColor(propertyListValue: theme.cursor) ?? .systemGreen
		backgroundCursor = foregroundCursor
		isDark = theme.isDark

		// TODO: For some reason .systemCyan doesn’t exist on macOS 12? Revisit this soon.
		var cyan: UIColor!
		if #available(iOS 15, *) {
			cyan = .systemCyan
		}
		if cyan == nil {
			cyan = UIColor(dynamicProvider: { _ in
				var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
				UIColor.systemBlue.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
				return UIColor(hue: h, saturation: s * 0.7, brightness: b * 1.3, alpha: a)
			})
		}

		var ansiColors: [AnsiColorCode: UIColor] = [
			.black:  .label,
			.red:    .systemRed,
			.green:  .systemGreen,
			.yellow: .systemYellow,
			.blue:   .systemBlue,
			.purple: .systemPurple,
			.cyan:   cyan,
			.white:  foreground,
			.brightBlack:  .label,
			.brightRed:    .systemRed,
			.brightGreen:  .systemGreen,
			.brightYellow: .systemYellow,
			.brightBlue:   .systemBlue,
			.brightPurple: .systemPurple,
			.brightCyan:   cyan,
			.brightWhite:  foregroundBold
		]

		if let colorTable = theme.colorTable,
			 colorTable.count == 16 {
			for (i, value) in colorTable.enumerated() {
				if let color = UIColor(propertyListValue: value) {
					ansiColors[.allCases[i]] = color
				}
			}
		}
		self.ansiColors = ansiColors
	}

	public mutating func color(for termColor: Attribute.Color, isForeground: Bool, isBold: Bool = false, isCursor: Bool = false) -> UIColor {
		if isCursor {
			if isForeground {
				switch termColor {
				case .defaultColor, .defaultInvertedColor: return background
				default: break
				}
			} else {
				return backgroundCursor
			}
		}

		switch termColor {
		case .defaultColor:
			return isForeground ? foreground : background

		case .defaultInvertedColor:
			return isForeground ? background : foreground

		case .ansi256(let ansi):
			let index = Int(ansi) + (isBold && ansi < 248 ? 8 : 0)
			if index < 16 {
				// ANSI color (0-15)
				return ansiColors[.allCases[index]]!
			}

			if let cachedColor = colorCache[termColor] {
				return cachedColor
			}

			let color: UIColor
			if index < 232 {
				// 256-color table (16-231)
				let tableIndex = index - 16
				let r = tableIndex / 36 == 0 ? 0 : ((tableIndex / 36) * 40 + 55)
				let g = tableIndex % 36 / 6 == 0 ? 0 : ((tableIndex % 36 / 6) * 40 + 55)
				let b = tableIndex % 6 == 0 ? 0 : (tableIndex % 6 * 40 + 55)
				color = UIColor(red: CGFloat(r) / 255,
												green: CGFloat(g) / 255,
												blue: CGFloat(b) / 255,
												alpha: 1)
			} else if index < 256 {
				// Greys (232-255)
				color = UIColor(white: ((CGFloat(index) - 232) * 10 + 8) / 255,
												alpha: 1)
			} else {
				Logger().warning("Unexpected color index: \(index)")
				color = foreground
			}
			colorCache[termColor] = color
			return color

		case .trueColor(let r, let g, let b):
			if let cachedColor = colorCache[termColor] {
				return cachedColor
			}

			let color = UIColor(red: CGFloat(r) / 255,
													green: CGFloat(g) / 255,
													blue: CGFloat(b) / 255,
													alpha: 1)
			colorCache[termColor] = color
			return color
		}
	}

}
