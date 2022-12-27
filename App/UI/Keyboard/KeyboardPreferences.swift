//
//  KeyboardPreferences.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 27/12/2022.
//

import Foundation

struct KeyboardPreferences {

	private static let defaults: UserDefaults = {
		#if targetEnvironment(macCatalyst)
		// If key repeat is disabled by the user, the initial repeat value will be set to a crazy
		// high sentinel number.
		.standard
		#else
		UserDefaults(suiteName: "com.apple.Accessibility") ?? .standard
		#endif
	}()

	static var isKeyRepeatEnabled: Bool {
		#if targetEnvironment(macCatalyst)
		// If key repeat is disabled by the user, the initial repeat value will be set to a crazy
		// high sentinel number.
		defaults.object(forKey: "InitialKeyRepeat") as? TimeInterval != 300000
		#else
		defaults.object(forKey: "KeyRepeatEnabled") as? Bool ?? true
		#endif
	}

	static var keyRepeatDelay: TimeInterval {
		#if targetEnvironment(macCatalyst)
		// No idea what these key repeat preference values are meant to calculate out to, but
		// this seems about right. Tested by counting frames in a screen recording.
		(defaults.object(forKey: "InitialKeyRepeat") as? TimeInterval ?? 84) * 0.012
		#else
		defaults.object(forKey: "KeyRepeatDelay") as? TimeInterval ?? 0.4
		#endif
	}

	static var keyRepeat: TimeInterval {
		#if targetEnvironment(macCatalyst)
		(defaults.object(forKey: "KeyRepeat") as? TimeInterval ?? 8) * 0.012
		#else
		defaults.object(forKey: "KeyRepeatInterval") as? TimeInterval ?? 0.1
		#endif
	}

	private init() {}

}
