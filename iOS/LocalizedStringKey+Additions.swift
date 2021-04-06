//
//  LocalizedStringKey+Additions.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI

extension LocalizedStringKey {
	init(uikitKey key: String) {
		let string = Bundle.uikit.localizedString(forKey: key, value: key, table: nil)
		self.init(string)
	}
}

extension Text {
	init(uikitKey key: String) {
		self.init(LocalizedStringKey(uikitKey: key))
	}
}
