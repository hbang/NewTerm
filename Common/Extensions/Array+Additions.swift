//
//  Array+Additions.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 22/3/2022.
//

import Foundation

extension Array where Element == String {
	var cStringArray: [UnsafeMutablePointer<CChar>?] {
		map(\.cString) + [nil]
	}
}

extension Array where Element == Optional<UnsafeMutablePointer<CChar>> {
	func deallocate() {
		for item in self {
			item?.deallocate()
		}
	}
}
