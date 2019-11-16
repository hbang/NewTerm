//
//  Preferences.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public enum KeyboardButtonStyle: Int {
	case text = 0, icons = 1
}

public class Preferences {

	public static let didChangeNotification = Notification.Name(rawValue: "NewTermPreferencesDidChangeNotification")

	public static let shared = Preferences()

#if LINK_CEPHEI
	let preferences = HBPreferences(identifier: "ws.hbang.Terminal")
#else
	let preferences = UserDefaults.standard
#endif

	let fontsPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Fonts", withExtension: "plist")!)!
	let themesPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Themes", withExtension: "plist")!)!

	public var fontMetrics: FontMetrics!
	public var colorMap: VT100ColorMap!

	private init() {
		let defaultFontName: String
		if #available(iOS 13.0, macOS 10.15, *) {
			defaultFontName = "SF Mono"
		} else {
			defaultFontName = "Fira Code"
		}

		preferences.register(defaults: [
			"fontName": defaultFontName,
			"fontSizePhone": 12,
			"fontSizePad": 13,
			"fontSizeMac": 12,
			"theme": "kirb",
			"bellHUD": true,
			"bellSound": false
		])

		// Fix the default font for users of NewTerm 2.2.1 on iOS 13
		if #available(iOS 13.0, *), fontName == "Courier" && lastVersion == nil {
			fontName = defaultFontName
		}

		let infoPlist = Bundle.main.infoDictionary!
		lastVersion = infoPlist["CFBundleVersion"] as? Int

		#if LINK_CEPHEI
		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated(notification:)), name: HBPreferences.didChangeNotification, object: preferences)
		#else
		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated(notification:)), name: UserDefaults.didChangeNotification, object: preferences)
		#endif

		preferencesUpdated(notification: nil)
	}

	public var fontName: String {
		get { return preferences.object(forKey: "fontName") as! String }
		set { preferences.set(newValue, forKey: "fontName") }
	}

	public var fontSize: CGFloat {
		get {
			#if os(macOS)
			return preferences.object(forKey: "fontSizeMac") as! CGFloat
			#else
			return preferences.object(forKey: isBigDevice ? "fontSizePad" : "fontSizePhone") as! CGFloat
			#endif
		}
	}

	public var themeName: String {
		get { return preferences.object(forKey: "theme") as! String }
		set { preferences.set(newValue, forKey: "theme") }
	}

	#if os(iOS)
	public var keyboardAccessoryStyle: KeyboardButtonStyle {
		get { return KeyboardButtonStyle(rawValue: preferences.integer(forKey: "keyboardAccessoryStyle")) ?? .text }
	}
	#endif

	public var bellHUD: Bool {
		get { return preferences.bool(forKey: "bellHUD") }
	}

	public var bellSound: Bool {
		get { return preferences.bool(forKey: "bellSound") }
	}

	public var lastVersion: Int? {
		get { return preferences.object(forKey: "lastVersion") as? Int }
		set { preferences.set(newValue, forKey: "lastVersion") }
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
		var regularFont: Font?
		var boldFont: Font?

		if fontName == "SF Mono" {
			if #available(iOS 13.0, macOS 10.15, *) {
				regularFont = Font.monospacedSystemFont(ofSize: fontSize, weight: .regular)
				boldFont = Font.monospacedSystemFont(ofSize: fontSize, weight: .bold)
			}
		} else {
			if let family = fontsPlist[fontName] as? [String: String] {
				if family["Regular"] != nil && family["Bold"] != nil {
					regularFont = Font(name: family["Regular"]!, size: fontSize)
					boldFont = Font(name: family["Bold"]!, size: fontSize)
				}
			}
		}

		if regularFont == nil || boldFont == nil {
			NSLog("font %@ size %f could not be initialised", fontName, fontSize)
			fontName = "Courier"
			return
		}

		fontMetrics = FontMetrics(regularFont: regularFont!, boldFont: boldFont!)
	}

	private func colorMapChanged() {
		// if the theme doesn’t exist… how did we get here? force it to the default, which will call
		// this method again
		guard let theme = themesPlist[themeName] as? [String: Any] else {
			NSLog("theme %@ doesn’t exist", themeName)
			themeName = "kirb"
			return
		}

		colorMap = VT100ColorMap(dictionary: theme)
	}

}

