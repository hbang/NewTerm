//
//  HapticController.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 23/12/2022.
//

import Foundation
import CoreHaptics
import AudioToolbox

fileprivate let kSystemSoundID_UserPreferredAlert: SystemSoundID = 0x00001000

class HapticController {

	private static let engine = try? CHHapticEngine()

	private static let bellHapticPattern: [CHHapticEvent] = {
		return [
			CHHapticEvent(eventType: .hapticTransient,
										parameters: [
											CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
											CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
										],
										relativeTime: 0,
										duration: 0.2)
		]
	}()

	private static let bellHapticSound: [CHHapticEvent] = {
		guard let bellURL = Bundle.main.url(forResource: "bell", withExtension: "m4a"),
					let bellResource = try? engine?.registerAudioResource(bellURL, options: [:]) else {
			return []
		}
		return [CHHapticEvent(audioResourceID: bellResource, parameters: [], relativeTime: 0)]
	}()

	static func playBell() {
		let preferences = Preferences.shared
		var events = [CHHapticEvent]()

		if preferences.bellSound {
			#if targetEnvironment(macCatalyst)
			AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert)
			#else
			events += bellHapticSound
			#endif
		}

		if preferences.bellVibrate {
			events += bellHapticPattern
		}

		guard let pattern = try? CHHapticPattern(events: events, parameters: []),
					let player = try? engine?.makePlayer(with: pattern) else {
			return
		}

		try? engine?.start()
		try? player.start(atTime: 0)
	}

}
