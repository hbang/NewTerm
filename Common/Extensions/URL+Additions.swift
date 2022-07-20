//
//  URL+Additions.swift
//  NewTerm (Common)
//
//  Created by Adam Demasi on 20/7/2022.
//

import Foundation

extension URL {
	static func / (lhs: URL, rhs: String) -> URL {
		rhs == ".." ? lhs.deletingLastPathComponent() : lhs.appendingPathComponent(rhs)
	}
}
