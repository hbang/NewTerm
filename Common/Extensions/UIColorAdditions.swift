//
//  UIColorAdditions.swift
//  Alderis
//
//  Created by Ryan Nair on 10/5/20.
//  Copyright © 2020 HASHBANG Productions. All rights reserved.
//

import UIKit

/// ColorPropertyListValue is a protocol representing types that can be passed to the\
/// `UIColor.init(propertyListValue:)` initialiser. `String` and `Array` both conform to this type.
///
/// - see: `UIColor.init(propertyListValue:)`
public protocol ColorPropertyListValue {}

/// A string can represent a `ColorPropertyListValue`.
///
/// - see: `UIColor.init(propertyListValue:)`
extension String: ColorPropertyListValue {}

/// An array of integers can represent a `ColorPropertyListValue`.
///
/// - see: `UIColor.init(propertyListValue:)`
extension Array: ColorPropertyListValue where Element: FixedWidthInteger {}

/// Alderis provides extensions to `UIColor` for the purpose of serializing and deserializing colors
/// into representations that can be stored in property lists, JSON, and similar formats.
public extension UIColor {

	/// Initializes and returns a color object using data from the specified object.
	///
	/// The value is expected to be one of:
	///
	/// * An array of 3 or 4 integer RGB or RGBA color components, with values between 0 and 255 (e.g.
	///   `[ 218, 192, 222 ]`)
	/// * A CSS-style hex string, with an optional alpha component (e.g. `#DAC0DE` or `#DACODE55`)
	/// * A short CSS-style hex string, with an optional alpha component (e.g. `#DC0` or `#DC05`)
	///
	/// Use `-[UIColor initWithHbcp_propertyListValue:]` to access this method from Objective-C.
	///
	/// - parameter value: The object to retrieve data from. See the discussion for the supported object
	/// types.
	/// - returns: An initialized color object, or nil if the value does not conform to the expected
	/// type. The color information represented by this object is in the device RGB colorspace.
	/// - see: `propertyListValue`
	@nonobjc convenience init?(propertyListValue: ColorPropertyListValue?) {
		if let array = propertyListValue as? [Int], array.count == 3 || array.count == 4 {
			let floats = array.map { CGFloat($0) }
			self.init(red: floats[0] / 255,
								green: floats[1] / 255,
								blue: floats[2] / 255,
								alpha: array.count == 4 ? floats[3] : 1)
			return
		} else if var string = propertyListValue as? String {
			if string.count == 4 || string.count == 5 {
				let r = String(repeating: string[string.index(string.startIndex, offsetBy: 1)], count: 2)
				let g = String(repeating: string[string.index(string.startIndex, offsetBy: 2)], count: 2)
				let b = String(repeating: string[string.index(string.startIndex, offsetBy: 3)], count: 2)
				let a = string.count == 5 ? String(repeating: string[string.index(string.startIndex, offsetBy: 4)], count: 2) : "FF"
				string = String(format: "%@%@%@%@", r, g, b, a)
			}

			var hex: UInt64 = 0
			let scanner = Scanner(string: string)
			guard scanner.scanString("#") != nil,
						scanner.scanHexInt64(&hex) else {
							return nil
						}


			if string.count == 9 {
				self.init(red: CGFloat((hex & 0xFF000000) >> 24) / 255,
									green: CGFloat((hex & 0x00FF0000) >> 16) / 255,
									blue: CGFloat((hex & 0x0000FF00) >> 8) / 255,
									alpha: CGFloat((hex & 0x000000FF) >> 0) / 255)
				return
			} else {
				var alpha: Float = 1
				if scanner.scanString(":") != nil {
					// Continue scanning to get the alpha component.
					alpha = scanner.scanFloat() ?? 1
				}

				self.init(red: CGFloat((hex & 0xFF0000) >> 16) / 255,
									green: CGFloat((hex & 0x00FF00) >> 8) / 255,
									blue: CGFloat((hex & 0x0000FF) >> 0) / 255,
									alpha: CGFloat(alpha))
				return
			}
		}

		return nil
	}

}
