//
//  Preferences.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class Preferences {

	static let didChangeNotification = Notification.Name(rawValue: "NewTermPreferencesDidChangeNotification")

	static let shared = Preferences()

#if LINK_CEPHEI
	let preferences = HBPreferences(identifier: "ws.hbang.Terminal")
#else
	let preferences = UserDefaults.standard
#endif

	let fontsPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Fonts", withExtension: "plist")!)!
	let themesPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Themes", withExtension: "plist")!)!

	var fontMetrics: FontMetrics!
	var colorMap: VT100ColorMap!

	private init() {
#if TARGET_UIKITONMAC
		let defaultFontName = "Menlo"
#else
		let defaultFontName = "Fira Code"
#endif

		preferences.register(defaults: [
			"fontName": defaultFontName,
			"fontSizePhone": 12,
			"fontSizePad": 13,
			"theme": "kirb",
			"bellHUD": true,
			"bellSound": false
		])

#if LINK_CEPHEI
		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated(notification:)), name: HBPreferences.didChangeNotification, object: preferences)
#else
		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated(notification:)), name: UserDefaults.didChangeNotification, object: preferences)
#endif

		preferencesUpdated(notification: nil)
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

	@objc func preferencesUpdated(notification: Notification?) {
		fontMetricsChanged()
		colorMapChanged()

		if notification != nil {
			NotificationCenter.default.post(name: Preferences.didChangeNotification, object: nil)
		}
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
			preferences.set("Courier", forKey: "fontName")
			return
		}

		fontMetrics = FontMetrics(font: regularFont, boldFont: boldFont)
	}

	private func colorMapChanged() {
		// if the theme doesn’t exist… how did we get here? force it to the default, which will call
		// this method again
		guard let theme = themesPlist[themeName] as? [String: Any] else {
			NSLog("theme %@ doesn’t exist", themeName)
			preferences.set("kirb", forKey: "theme")
			return
		}

		colorMap = VT100ColorMap(dictionary: theme)
	}

}

