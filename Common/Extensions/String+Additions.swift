//
//  String+Additions.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 22/3/2022.
//

import Foundation

extension String {
	public var cString: UnsafeMutablePointer<CChar>? {
		strdup(self)
	}

	public var utf8Array: [UTF8Char] {
		Array(utf8)
	}
}
