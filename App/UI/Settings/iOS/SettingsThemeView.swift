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
		VStack(spacing: 0) {
			TerminalSampleView(fontMetrics: preferences.fontMetrics,
												 colorMap: preferences.colorMap)

			PreferencesList {
				PreferencesGroup(header: Text("Built in Themes")) {
					PreferencesPicker(selection: preferences.$themeName, label: EmptyView()) {
						ForEach(sortedThemes, id: \.key) { item in Text(item.key) }
					}
				}
			}
		}
			.navigationBarTitle("Theme")
	}

}

struct SettingsThemeView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SettingsThemeView()
		}
	}
}
