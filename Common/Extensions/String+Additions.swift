//
//  String+Additions.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 22/3/2022.
//

import Foundation

extension String {
	var cString: UnsafeMutablePointer<CChar>? {
		strdup(self)
	}
}
