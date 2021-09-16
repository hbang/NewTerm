//
//  SettingsPerformanceView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 16/9/21.
//

import SwiftUI

struct SettingsPerformanceView: View {

	private let refreshRates = [
		15,
		30,
		60,
		120
	].filter { item in item <= UIScreen.main.maximumFramesPerSecond }

	@ObservedObject var preferences = Preferences.shared

	var body: some View {
		let list = ForEach(refreshRates, id: \.self) { key in
			Button(
				action: {
					preferences.refreshRate = key
				},
				label: {
					HStack {
						Text("\(key) updates per second")
							.foregroundColor(Color(.label))
						Spacer()

						if key == preferences.$refreshRate.wrappedValue {
							Image(systemName: "checkmark")
								.accessibility(label: Text("Selected"))
						}
					}
				}
			)
				.animation(.default)
		}

		return List {
			Section(
				header: Text("Refresh Rate"),
				footer: Text("Reducing the refresh rate can improve \(UIDevice.current.localizedModel) energy usage, but will cause the terminal display to feel sluggish.\nThe default setting of 60 updates per second is recommended.")
			) {
				list
			}

			if #available(macOS 12, *) {
				Section(
					footer: Text("Preserve battery life by reducing refresh rate to 15 fps when Low Power Mode is enabled.")
				) {
					Toggle(
						"Reduce Performance in Low Power Mode",
						isOn: preferences.$reduceRefreshRateInLPM
					)
				}
			}
		}
		.listStyle(GroupedListStyle())
		.navigationBarTitle("Performance", displayMode: .inline)
	}

}

struct SettingsPerformanceView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SettingsPerformanceView()
		}
		.previewDevice("iPhone 13 Pro")

		NavigationView {
			SettingsPerformanceView()
		}
		.previewDevice("iPhone 12 Pro")
	}
}

