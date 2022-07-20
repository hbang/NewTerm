//
//  String+Localization.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import Foundation
import UIKit

public extension String {
	static func localize(_ key: String, bundle: Bundle? = nil, tableName: String? = nil, comment: String = "") -> String {
		NSLocalizedString(key, tableName: tableName, bundle: bundle ?? .main, comment: comment)
	}

	private static let uikitBundle = Bundle(for: UIView.self)

	static var ok: String     { .localize("OK",     bundle: uikitBundle) }
	static var done: String   { .localize("Done",   bundle: uikitBundle) }
	static var cancel: String { .localize("Cancel", bundle: uikitBundle) }
	static var close: String  { .localize("Close",  bundle: uikitBundle) }
}
