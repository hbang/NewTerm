//
//  Preferences.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class Preferences {

	static let shared = Preferences()

#if THEOS_SWIFT
	let preferences = HBPreferences(identifier: "ws.hbang.Terminal")
#else
	let preferences = UserDefaults.standard
#endif

	let fontsPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Fonts", withExtension: "plist")!)!
	let themesPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Themes", withExtension: "plist")!)!

	var fontMetrics: FontMetrics!
	var colorMap: VT100ColorMap!

	init() {
		preferences.registerDefaults([
			"fontName": "Fira Code",
			"fontSizePhone": 12,
			"fontSizePad": 13,
			"theme": "kirb",
			"bellHUD": true,
			"bellSound": false
		])

#if THEOS_SWIFT
		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: UserDefaults.didChangeNotification, object: preferences)
#else
		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: HBPreferences.didChangeNotification, object: preferences)
#endif

		preferencesUpdated()
	}

	var fontName: String {
		get { return preferences.object(forKey: "fontName") as! String }
	}

	var fontSize: CGFloat {
		get { return preferences.object(forKey: isBigDevice ? "fontSizePad" : "fontSizePhone") as! CGFloat }
	}

	var themeName: String {
		get { return preferences.object(forKey: "theme") as! String }
	}

	var bellHUD: Bool {
		get { return preferences.bool(forKey: "bellHUD") }
	}

	var bellSound: Bool {
		get { return preferences.bool(forKey: "bellSound") }
	}

	// MARK: - Callbacks

	@objc private func preferencesUpdated() {
		fontMetricsChanged()
		colorMapChanged()
	}

	private func fontMetricsChanged() {
		var regularFont: UIFont?
		var boldFont: UIFont?

		if let family = fontsPlist[fontName] as? [String: String] {
			if family["Regular"] != nil && family["Bold"] != nil {
				regularFont = UIFont(name: family["Regular"]!, size: fontSize)
				boldFont = UIFont(name: family["Bold"]!, size: fontSize)
			}
		}

		if regularFont == nil || boldFont == nil {
			NSLog("font %@ size %f could not be initialised", fontName, fontSize)
			preferences.setObject("Courier", forKey: "fontName")
			return
		}

		fontMetrics = FontMetrics(font: regularFont, boldFont: boldFont)
	}

	func colorMapChanged() {
		// if the theme doesn’t exist… how did we get here? force it to the default, which will call
		// this method again
		guard let theme = themesPlist[themeName] as? [String: Any] else {
			NSLog("theme %@ doesn’t exist", themeName)
			preferences.setObject("kirb", forKey: "theme")
			return
		}

		colorMap = VT100ColorMap(dictionary: theme)
	}

}

