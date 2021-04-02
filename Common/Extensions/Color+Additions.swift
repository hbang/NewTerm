//
//  Color+Additions.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 2/4/21.
//

import SwiftTerm

extension Color {

	convenience init(_ uiColor: UIColor) {
		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
		self.init(red: UInt16(r * 255),
							green: UInt16(g * 255),
							blue: UInt16(b * 255))
	}

}
