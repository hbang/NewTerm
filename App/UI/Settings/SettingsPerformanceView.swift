//
//  SettingsPerformanceView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 16/9/21.
//

import SwiftUI
import SwiftUIX

struct SettingsPerformanceView: View {

	private struct RefreshRate: Hashable {
		var rate: Int
		var name: String
	}

	private let refreshRates = [
		RefreshRate(rate:  15, name: "Power Saver"),
		RefreshRate(rate:  30, name: "Balanced"),
		RefreshRate(rate:  60, name: "Performance"),
		RefreshRate(rate: 120, name: "Speed Demon")
	].filter { item in item.rate <= UIScreen.main.maximumFramesPerSecond }

	@ObservedObject var preferences = Preferences.shared

	private var batteryImageName: SFSymbolName {
		let device = UIDevice.current
		device.isBatteryMonitoringEnabled = true
		let percent = device.batteryLevel
		let state = device.batteryState
		device.isBatteryMonitoringEnabled = false
		if state != .unknown {
			if percent < 0.2 {
				return .battery0
			} else if percent < 0.4 {
				return .battery25
			} else if #available(iOS 15, *) {
				if percent < 0.6 {
					return .battery50
				} else if percent < 0.8 {
					return .battery75
				}
			}
		}
		return .battery100
	}

	var body: some View {
		let list = ForEach(refreshRates, id: \.rate) { item in
			Text("\(item.rate) fps: \(String.localize(item.name))")
				.font(.body.monospacedDigit())
		}

		return PreferencesList {
			PreferencesGroup(header: UIDevice.current.isPortable
												? AnyView(Label(title: { Text("On AC Power") },
																				icon: { Image(systemName: .boltFill).imageScale(.medium) }))
												: AnyView(Text("Refresh Rate")),
											 footer: UIDevice.current.isPortable
												? AnyView(EmptyView())
												: AnyView(Text("The Performance setting is recommended."))) {
				PreferencesPicker(selection: preferences.$refreshRateOnAC,
													label: EmptyView()) {
					list
				}
			}

			if UIDevice.current.isPortable {
				PreferencesGroup(header: Label(title: { Text("On Battery") },
																			 icon: { Image(systemName: batteryImageName).imageScale(.medium) }),
												 footer: Text("A lower refresh rate improves \(UIDevice.current.deviceModel) battery life, but may cause the terminal display to feel sluggish.\nThe Performance setting is recommended.")
													.fixedSize(horizontal: false, vertical: true)) {
						PreferencesPicker(selection: preferences.$refreshRateOnBattery,
															label: EmptyView()) {
							list
						}
					}

				if #available(macOS 12, *) {
					PreferencesGroup(footer: Text("Preserve battery life by switching to Power Saver when Low Power Mode is enabled.")) {
						Toggle("Reduce Performance in Low Power Mode",
									 isOn: preferences.$reduceRefreshRateInLPM)
					}
				}
			}
		}
		.navigationBarTitle("Performance")
	}

}

struct SettingsPerformanceView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SettingsPerformanceView()
		}
		.previewDevice("iPhone 12 Pro")
		.previewDisplayName("60 Hz device")

		NavigationView {
			SettingsPerformanceView()
		}
		.previewDevice("iPhone 13 Pro")
		.previewDisplayName("120 Hz device")
	}
}

