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

import SwiftUI
import Combine
import os.log

public enum KeyboardButtonStyle: Int, PropertyListValue {
	case text, icons
}

public enum KeyboardTrackpadSensitivity: Int, PropertyListValue {
	case off, low, medium, high
}

public enum PreferencesSyncService: Int, PropertyListValue, Identifiable {
	case none, icloud, folder

	public var id: Self { self }
}

public class Preferences: NSObject, ObservableObject {

	public static let didChangeNotification = Notification.Name(rawValue: "NewTermPreferencesDidChangeNotification")

	public static let shared = Preferences()

	public let objectWillChange = ObservableObjectPublisher()

	private let themesPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Themes", withExtension: "plist")!)!

	@Published public var fontMetrics = FontMetrics(font: AppFont(), fontSize: 12)
	@Published public var colorMap = ColorMap(theme: AppTheme())

	override init() {
		super.init()

		if let version = Bundle.main.infoDictionary!["CFBundleVersion"] as? String {
			lastVersion = Int(version) ?? 0
		}

		fontMetricsChanged()
		colorMapChanged()
	}

	@AppStorage("fontName")
	public var fontName: String = "SF Mono" {
		willSet { objectWillChange.send() }
		didSet { fontMetricsChanged() }
	}

	// TODO: Public just for testing, make it private later
	@AppStorage("fontSizePhone")
	public var fontSizePhone: Double = 12 {
		willSet { objectWillChange.send() }
		didSet { fontMetricsChanged() }
	}

	@AppStorage("fontSizePad")
	private var fontSizePad: Double = 13 {
		willSet { objectWillChange.send() }
		didSet { fontMetricsChanged() }
	}

	@AppStorage("fontSizeMac")
	public var fontSizeMac: Double = 13 {
		willSet { objectWillChange.send() }
		didSet { fontMetricsChanged() }
	}

	// TODO: Make this act like a DynamicProperty
	public var fontSize: Double {
		get {
			#if os(macOS)
			return fontSizeMac
			#else
			return isBigDevice ? fontSizePad : fontSizePhone
			#endif
		}
		set {
			#if os(macOS)
			fontSizeMac = newValue
			#else
			if isBigDevice {
				fontSizePad = newValue
			} else {
				fontSizePhone = newValue
			}
			#endif
		}
	}

	@AppStorage("themeName")
	public var themeName: String = "kirb" {
		willSet { objectWillChange.send() }
		didSet { fontMetricsChanged() }
	}

	#if os(iOS)
	@AppStorage("keyboardAccessoryStyle")
	public var keyboardAccessoryStyle: KeyboardButtonStyle = .text {
		willSet { objectWillChange.send() }
	}

	@AppStorage("keyboardTrackpadSensitivity")
	public var keyboardTrackpadSensitivity: KeyboardTrackpadSensitivity = .medium {
		willSet { objectWillChange.send() }
	}
	#endif

	@AppStorage("bellHUD")
	public var bellHUD: Bool = true {
		willSet { objectWillChange.send() }
	}

	@AppStorage("bellVibrate")
	public var bellVibrate: Bool = true {
		willSet { objectWillChange.send() }
	}

	@AppStorage("bellSound")
	public var bellSound: Bool = true {
		willSet { objectWillChange.send() }
	}

	@AppStorage("refreshRate")
	public var refreshRate: Int = 60 {
		willSet { objectWillChange.send() }
	}

	@AppStorage("reduceRefreshRateInLPM")
	public var reduceRefreshRateInLPM: Bool = true {
		willSet { objectWillChange.send() }
	}

	@AppStorage("preferencesSyncService")
	public var preferencesSyncService: PreferencesSyncService = .icloud {
		willSet { objectWillChange.send() }
	}

	@AppStorage("preferencesSyncPath")
	public var preferencesSyncPath: String? = nil {
		willSet { objectWillChange.send() }
	}

	@AppStorage("lastVersion")
	public var lastVersion: Int = 0 {
		willSet { objectWillChange.send() }
	}

	#if os(macOS)
	public var appearanceStyle: NSAppearance.Name { colorMap.appearanceStyle }
	#else
	public var userInterfaceStyle: UIUserInterfaceStyle { colorMap.userInterfaceStyle }
	#endif

	// MARK: - Handlers

	private func fontMetricsChanged() {
		let font = AppFont.predefined[fontName] ?? AppFont()
		fontMetrics = FontMetrics(font: font, fontSize: CGFloat(fontSize))
	}

	private func colorMapChanged() {
		let theme = AppTheme.predefined[themeName] ?? AppTheme()
		colorMap = ColorMap(theme: theme)

		#if os(macOS)
		NSApp.appearance = NSAppearance(named: colorMap.appearanceStyle)
		#endif
	}

}

