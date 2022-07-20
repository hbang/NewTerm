//
//  Preferences.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import os.log

public enum KeyboardButtonStyle: Int {
	case text, icons
}

public enum KeyboardTrackpadSensitivity: Int {
	case off, low, medium, high
}

public enum PreferencesSyncService: Int, Identifiable {
	case none, icloud, folder

	public var id: Self { self }
}

public class Preferences: NSObject, ObservableObject {

	public static let didChangeNotification = Notification.Name(rawValue: "NewTermPreferencesDidChangeNotification")

	public static let shared = Preferences()

	@Published public private(set) var fontMetrics = FontMetrics(font: AppFont(), fontSize: 12) {
		willSet { objectWillChange.send() }
	}
	@Published public private(set) var colorMap = ColorMap(theme: AppTheme()) {
		willSet { objectWillChange.send() }
	}

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
			#if targetEnvironment(macCatalyst)
			return fontSizeMac
			#else
			return isBigDevice ? fontSizePad : fontSizePhone
			#endif
		}
		set {
			#if targetEnvironment(macCatalyst)
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
	public var themeName: String = "Basic (Dark)" {
		willSet { objectWillChange.send() }
		didSet { colorMapChanged() }
	}

	@AppStorage("keyboardAccessoryStyle")
	public var keyboardAccessoryStyle: KeyboardButtonStyle = .text {
		willSet { objectWillChange.send() }
	}

	@AppStorage("keyboardTrackpadSensitivity")
	public var keyboardTrackpadSensitivity: KeyboardTrackpadSensitivity = .medium {
		willSet { objectWillChange.send() }
	}

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

	@AppStorage("refreshRateOnAC")
	public var refreshRateOnAC: Int = 60 {
		willSet { objectWillChange.send() }
	}

	@AppStorage("refreshRateOnBattery")
	public var refreshRateOnBattery: Int = 60 {
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
	public var preferencesSyncPath: String = "" {
		willSet { objectWillChange.send() }
	}

	@AppStorage("preferredLocale")
	public var preferredLocale: String = "" {
		willSet { objectWillChange.send() }
	}

	@AppStorage("lastVersion")
	public var lastVersion: Int = 0 {
		willSet { objectWillChange.send() }
	}

	public var userInterfaceStyle: UIUserInterfaceStyle { colorMap.userInterfaceStyle }

	// MARK: - Handlers

	private func fontMetricsChanged() {
		let font = AppFont.predefined[fontName] ?? AppFont()
		objectWillChange.send()
		fontMetrics = FontMetrics(font: font, fontSize: CGFloat(fontSize))
	}

	private func colorMapChanged() {
		let theme = AppTheme.predefined[themeName] ?? AppTheme()
		objectWillChange.send()
		colorMap = ColorMap(theme: theme)
	}

}

