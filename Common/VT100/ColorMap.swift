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

open class ColorMap {

	public let background: UIColor
	public let foreground: UIColor
	public let foregroundBold: UIColor
	public let foregroundCursor: UIColor
	public let backgroundCursor: UIColor

	public let ansiColors: [UIColor]

	public let isDark: Bool

	#if os(iOS)
	open var userInterfaceStyle: UIUserInterfaceStyle { isDark ? .dark : .light }
	#else
	open var appearanceStyle: NSAppearanceName { isDark ? .darkAqua : .aqua }
	#endif

	public init(dictionary: [String: Any]) {
		if let color = dictionary["Background"] as? String {
			self.background = UIColor(propertyListValue: color)
		} else {
			self.background = .black
		}
		if let color = dictionary["Text"] as? String {
			self.foreground = UIColor(propertyListValue: color)
		} else {
			self.foreground = UIColor(white: 0.95, alpha: 1)
		}
		if let color = dictionary["BoldText"] as? String {
			self.foregroundBold = UIColor(propertyListValue: color)
		} else {
			self.foregroundBold = .white
		}
		if let color = dictionary["Cursor"] as? String {
			self.foregroundCursor = UIColor(propertyListValue: color)
			self.backgroundCursor = self.foregroundCursor
		} else {
			self.foregroundCursor = UIColor(white: 0.95, alpha: 1)
			self.backgroundCursor = UIColor(white: 0.4, alpha: 1)
		}
		if let isDark = dictionary["IsDark"] as? Bool {
			self.isDark = isDark
		} else {
			self.isDark = true
		}
		if let colorTable = dictionary["ColorTable"] as? [String],
			 colorTable.count == COLOR_MAP_MAX_COLORS {
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

	open func color(for termColor: Attribute.Color, isForeground: Bool, isBold: Bool) -> UIColor {
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
