//
//  SettingsThemeView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI

struct SettingsThemeView: View {

	private let predefinedThemes = AppTheme.predefined
	private let sortedThemes = AppTheme.predefined
		.sorted(by: { a, b in a.key < b.key })

	@ObservedObject var preferences = Preferences.shared

	var body: some View {
		let sampleView = TerminalSampleViewRepresentable(
			fontMetrics: preferences.fontMetrics,
			colorMap: preferences.colorMap
		)

		let themesList = ForEach(sortedThemes, id: \.key) { key, value in
			Button(
				action: {
					preferences.themeName = key
				},
				label: {
					HStack {
						Text(key)
							.foregroundColor(.primary)
						Spacer()

						if key == preferences.themeName {
							Image(systemName: "checkmark")
								.accessibility(label: Text("Selected"))
						}
					}
				}
			)
			.animation(.default)
		}

		let list = List {
			Section(footer: Text("Note: You currently need to restart the app to have theme updates apply.")) {}
			Section() {
				themesList
			}
		}
		.listStyle(GroupedListStyle())

		return VStack {
			sampleView
			list
		}
		.navigationBarTitle("Theme", displayMode: .inline)
	}

}

struct SettingsThemeView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SettingsThemeView()
		}
	}
}
