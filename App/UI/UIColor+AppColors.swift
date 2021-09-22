//
//  UIColor+AppColors.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 11/3/21.
//

import UIKit

extension UIColor {

	convenience init(lightColor: UIColor, darkColor: UIColor) {
		self.init(dynamicProvider: { traitCollection -> UIColor in
			switch traitCollection.userInterfaceStyle {
			case .light, .unspecified:
				return lightColor
			case .dark:
				return darkColor
			@unknown default:
				return lightColor
			}
		})
	}

	// TODO: Review moving all of these to asset catalog. Need to test iOS 10-12.

	static let tint = UIColor(red: 76 / 255, green: 161 / 255, blue: 1, alpha: 1)

	static let legacyText       = UIColor.white
	static let legacyBackground = UIColor(white: 26 / 255, alpha: 1)
	static let legacySeparator  = UIColor(white: 60 / 255, alpha: 1)

	static let keyboardToolbarBackground = UIColor(lightColor: UIColor(red: 202 / 255, green: 205 / 255, blue: 211 / 255, alpha: 0.73),
																								 darkColor: UIColor(white: 235 / 255, alpha: 0.055))

	static let keyBackgroundNormal      = UIColor(lightColor: UIColor(red: 180 / 255, green: 184 / 255, blue: 193 / 255, alpha: 1),
																								 darkColor: UIColor(white: 1, alpha: 69 / 255))
	static let keyBackgroundHighlighted = UIColor(lightColor: .white,
																								 darkColor: UIColor(white: 1, alpha: 32 / 255))
	static let keyBackgroundSelected    = UIColor(lightColor: .white,
																								 darkColor: UIColor(white: 1, alpha: 182 / 255))
	static let keyForegroundNormal      = UIColor(lightColor: .black,
																								darkColor: .white)
	static let keyForegroundHighlighted = UIColor(lightColor: .black,
																								darkColor: .white)
	static let keyForegroundSelected    = UIColor(lightColor: .black,
																								darkColor: .black)

	static let logoBackground = UIColor(white: 0, alpha: 229 / 255)
	static let logoName       = UIColor(white: 0.9, alpha: 1)
	static let logoCursor     = UIColor(red: 0, green: 217 / 255, blue: 0, alpha: 1)

	static let tabSelected  = UIColor(lightColor: UIColor(white: 0, alpha: 41 / 255),
																		darkColor: UIColor(white: 1, alpha: 69 / 255))
	static let tabSeparator = UIColor(white: 85 / 255, alpha: 0.4)

}
