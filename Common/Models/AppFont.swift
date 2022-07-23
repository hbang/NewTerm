//
//  AppFont.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 3/4/21.
//

import UIKit

public struct AppFont: Codable {

	public static let predefined: [String: AppFont] = {
		let data = try! Data(contentsOf: Bundle.main.url(forResource: "Fonts", withExtension: "plist")!)
		return try! PropertyListDecoder().decode([String: AppFont].self, from: data)
	}()

	public let regular: String?
	public let bold: String?
	public let italic: String?
	public let boldItalic: String?
	public let light: String?
	public let lightItalic: String?
	public let systemMonospaceFont: Bool?

	public var previewFont: UIFont? {
		if systemMonospaceFont ?? false {
			let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
				.withDesign(.monospaced)!
			return UIFont(descriptor: descriptor, size: 0)
		}
		if let regular = regular,
			 let font = UIFont(name: regular, size: 13) {
			return UIFontMetrics(forTextStyle: .body)
				.scaledFont(for: font)
		}
		return nil
	}

	public init() {
		// Fallback values
		regular = nil
		bold = nil
		italic = nil
		boldItalic = nil
		light = nil
		lightItalic = nil
		systemMonospaceFont = true
	}

}
