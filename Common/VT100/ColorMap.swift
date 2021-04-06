//
//  ColorMap.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 2/4/21.
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

import SwiftTerm
import os.log

public struct ColorMap {

	public let background: UIColor
	public let foreground: UIColor
	public let foregroundBold: UIColor
	public let foregroundCursor: UIColor
	public let backgroundCursor: UIColor

	public let ansiColors: [UIColor]

	public let isDark: Bool

	#if os(iOS)
	public var userInterfaceStyle: UIUserInterfaceStyle { isDark ? .dark : .light }
	#else
	public var appearanceStyle: NSAppearanceName { isDark ? .darkAqua : .aqua }
	#endif

	public init(theme: AppTheme) {
		background = UIColor(propertyListValue: theme.background)
		foreground = UIColor(propertyListValue: theme.text)
		foregroundBold = UIColor(propertyListValue: theme.boldText)
		foregroundCursor = UIColor(propertyListValue: theme.cursor)
		backgroundCursor = foregroundCursor
		isDark = theme.isDark

		if let colorTable = theme.colorTable,
			 colorTable.count == 16 {
			ansiColors = colorTable.map { item in UIColor(propertyListValue: item) }
		} else {
			// System 7.5 colors, why not?
			ansiColors = [
				UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1),
				UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1),
				UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1),
				UIColor(red: 0.6, green: 0.4, blue: 0.0, alpha: 1),
				UIColor(red: 0.0, green: 0.0, blue: 0.6, alpha: 1),
				UIColor(red: 0.6, green: 0.0, blue: 0.6, alpha: 1),
				UIColor(red: 0.0, green: 0.6, blue: 0.6, alpha: 1),
				UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1),
				UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1),
				UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1),
				UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1),
				UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1),
				UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1),
				UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1),
				UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1),
				UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
			]
		}
	}

	public func color(for termColor: Attribute.Color, isForeground: Bool, isBold: Bool = false, isCursor: Bool = false) -> UIColor {
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
				return ansiColors[index]
			} else if index < 232 {
				// 256-color table (16-231)
				let tableIndex = index - 16
				let r = tableIndex / 36 == 0 ? 0 : ((tableIndex / 36) * 40 + 55)
				let g = tableIndex % 36 / 6 == 0 ? 0 : ((tableIndex % 36 / 6) * 40 + 55)
				let b = tableIndex % 6 == 0 ? 0 : (tableIndex % 6 * 40 + 55)
				return UIColor(red: CGFloat(r) / 255,
											 green: CGFloat(g) / 255,
											 blue: CGFloat(b) / 255,
											 alpha: 1)
			} else if index < 256 {
				// Greys (232-255)
				return UIColor(white: ((CGFloat(index) - 232) * 10 + 8) / 255,
											 alpha: 1)
			} else {
				os_log("Unexpected color index: %{public}i", index)
				return foreground
			}

		case .trueColor(let r, let g, let b):
			return UIColor(red: CGFloat(r) / 255,
										 green: CGFloat(g) / 255,
										 blue: CGFloat(b) / 255,
										 alpha: 1)
		}
	}

}
