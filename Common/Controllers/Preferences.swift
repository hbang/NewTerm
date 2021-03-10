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

import os.log

public enum KeyboardButtonStyle: Int {
	case text, icons
}

@objc(Preferences)
public class Preferences: NSObject {

	@objc public static let didChangeNotification = Notification.Name(rawValue: "NewTermPreferencesDidChangeNotification")

	@objc public static let shared = Preferences()

	let preferences = UserDefaults.standard

	let fontsPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Fonts", withExtension: "plist")!)!
	let themesPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Themes", withExtension: "plist")!)!

	public var fontMetrics: FontMetrics!
	@objc public var colorMap: VT100ColorMap!

	private var kvoContext = 0

	override init() {
		super.init()

		// TODO: Preferences really shouldn’t be responsible for loading fonts!
		FontMetrics.loadFonts()

		let defaultFontName: String
		if #available(iOS 13.0, macOS 10.15, *) {
			defaultFontName = "SF Mono"
		} else {
			defaultFontName = "Menlo"
		}
		let defaults: [String: Any] = [
			"fontName": defaultFontName,
			"fontSizePhone": 12,
			"fontSizePad": 13,
			"fontSizeMac": 12,
			"theme": "kirb",
			"bellHUD": true,
			"bellVibrate": true,
			"bellSound": true
		]
		preferences.register(defaults: defaults)

		let infoPlist = Bundle.main.infoDictionary!
		lastVersion = infoPlist["CFBundleVersion"] as? Int

		for key in defaults.keys {
			preferences.addObserver(self, forKeyPath: key, options: [], context: &kvoContext)
		}
		preferencesUpdated(fromNotification: false)
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

	public var bellVibrate: Bool {
		get { return preferences.bool(forKey: "bellVibrate") }
	}

	public var bellSound: Bool {
		get { return preferences.bool(forKey: "bellSound") }
	}

	public var lastVersion: Int? {
		get { return preferences.object(forKey: "lastVersion") as? Int }
		set { preferences.set(newValue, forKey: "lastVersion") }
	}

	#if os(iOS)
	@available(iOS 13, *)
	@objc public var userInterfaceStyle: UIUserInterfaceStyle {
		return colorMap.userInterfaceStyle
	}
	#elseif os(macOS)
	@objc public var appearanceStyle: NSAppearance.Name {
		return colorMap.appearanceStyle
	}
	#endif

	// MARK: - Callbacks

	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if context == &kvoContext {
			preferencesUpdated(fromNotification: true)
		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}

	func preferencesUpdated(fromNotification: Bool) {
		fontMetricsChanged()
		colorMapChanged()
		if fromNotification {
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
			os_log("Font %{public}@ size %{public}.1f could not be initialised", type: .error, fontName, fontSize)
			if #available(iOS 13.0, macOS 10.15, *) {
				fontName = "SF Mono"
			} else {
				fontName = "Menlo"
			}
			return
		}

		fontMetrics = FontMetrics(regularFont: regularFont!, boldFont: boldFont!)
	}

	private func colorMapChanged() {
		// if the theme doesn’t exist… how did we get here? force it to the default, which will call
		// this method again
		guard let theme = themesPlist[themeName] as? [String: Any] else {
			os_log("Theme %{public}@ doesn’t exist", type: .error, themeName)
			themeName = "Basic"
			return
		}

		colorMap = VT100ColorMap(dictionary: theme)

		#if os(macOS)
		NSApp.appearance = NSAppearance(named: colorMap.appearanceStyle)
		#endif
	}

}

