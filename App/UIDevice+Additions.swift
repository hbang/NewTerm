//
//  UIDevice+Additions.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 25/9/21.
//

import UIKit
import Darwin
import UniformTypeIdentifiers

#if targetEnvironment(macCatalyst)
import IOKit.ps
#endif

extension UTTagClass {
	static let deviceModelCode = UTTagClass(rawValue: "com.apple.device-model-code")
}

extension UIDevice {

	var isPortable: Bool {
		switch userInterfaceIdiom {
		case .phone, .pad, .carPlay, .unspecified:
			return true
		case .tv:
			return false
		case .mac:
			#if targetEnvironment(macCatalyst)
			// Consider a Mac “portable” if it has an internal battery.
			if let powerSourcesInfo = IOPSCopyPowerSourcesInfo()?.takeUnretainedValue(),
				 let powerSourcesList = IOPSCopyPowerSourcesList(powerSourcesInfo)?.takeUnretainedValue() as? [CFTypeRef] {
				return powerSourcesList.contains {
					let description = IOPSGetPowerSourceDescription(powerSourcesInfo, $0)?.takeUnretainedValue() as? [String: Any] ?? [:]
					return description["Type"] as? String == "InternalBattery"
				}
			}
			#endif
			return false
		@unknown default:
			return true
		}
	}

	var machine: String {
		#if targetEnvironment(macCatalyst)
		let key = "hw.model"
		#else
		let key = "hw.machine"
		#endif
		var size = size_t()
		sysctlbyname(key, nil, &size, nil, 0)
		let value = malloc(size)
		defer {
			value?.deallocate()
		}
		sysctlbyname(key, value, &size, nil, 0)
		guard let cChar = value?.bindMemory(to: CChar.self, capacity: size) else {
			#if targetEnvironment(macCatalyst)
			return "Mac"
			#else
			return model
			#endif
		}
		return String(cString: cChar)
	}

	var deviceModel: String {
		#if targetEnvironment(macCatalyst)
		// localizedModel on macOS always returns “iPad” 🙁
		// Grab the device machine identifier directly, then find its name via CoreTypes.
		return UTType(tag: machine,
									tagClass: .deviceModelCode,
									conformingTo: nil)?.localizedDescription ?? "Mac"
		#else
		return localizedModel
		#endif
	}

}
