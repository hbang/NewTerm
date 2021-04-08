//
//  SettingsView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI

struct SettingsView: View {

	@Environment(\.presentationMode)
	var presentationMode

	@ObservedObject var preferences = Preferences.shared

	var body: some View {
		#if targetEnvironment(macCatalyst)
		let title = "SETTINGS_MAC"
		#else
		let title = "SETTINGS"
		#endif

		return NavigationView {
			List() {
				Section(header: Text("Interface")) {
					NavigationLink(
						destination: SettingsFontView(),
						label: {
							KeyValueView(
								title: Text("Font"),
								value: Text("\(preferences.fontName), \(Int(preferences.fontSize))")
							)
						}
					)
					NavigationLink(
						destination: SettingsThemeView(),
						label: {
							KeyValueView(
								title: Text("Theme"),
								value: Text(preferences.themeName)
							)
						}
					)
				}

				Section {
					NavigationLink(
						destination: SettingsAboutView(),
						label: { Text("About") }
					)
				}
			}
			.listStyle(GroupedListStyle())
			.navigationBarTitle(LocalizedStringKey(title), displayMode: .large)
			.navigationBarItems(trailing:
														Button(
															action: {
																// TODO: presentationMode seems useless when UIKit is presenting the
																// view controller rather than SwiftUI? Ugh
//																presentationMode.wrappedValue.dismiss()
																NotificationCenter.default.post(name: RootViewController.settingsViewDoneNotification, object: nil)
															},
															label: { Text(uikitKey: "Done") }
														)
			)
		}
	}
}

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsView()
	}
}

