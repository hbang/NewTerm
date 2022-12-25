//
//  SettingsView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI

fileprivate extension KeyboardArrowsStyle {
	var name: String {
		switch self {
		case .butterfly:   return "Butterfly"
		case .scissor:     return "Scissor"
		case .classic:     return "Classic"
		case .vim:         return "Vim"
		case .vimInverted: return "Vim Inverted"
		}
	}
}

struct SettingsView: View {

	@Environment(\.presentationMode)
	var presentationMode

	@ObservedObject var preferences = Preferences.shared

	var windowScene: UIWindowScene?

	@State private var toggledKeys = Set<ToolbarKey>()

	private func dismiss() {
		if let windowScene = windowScene {
			UIApplication.shared.requestSceneSessionDestruction(windowScene.session, options: nil, errorHandler: nil)
		} else {
			// TODO: presentationMode seems useless when UIKit is presenting
			// the view controller rather than SwiftUI? Ugh
//			presentationMode.wrappedValue.dismiss()
			NotificationCenter.default.post(name: RootViewController.settingsViewDoneNotification, object: nil)
		}
	}

	var body: some View {
		let list = List() {
			PreferencesGroup(header: Text("Terminal")) {
				NavigationLink(destination: SettingsFontView(),
											 label: { KeyValueView(title: Text("Font"),
																						 value: Text("\(preferences.fontName), \(Int(preferences.fontSize))")) })

				NavigationLink(destination: SettingsThemeView(),
											 label: { KeyValueView(title: Text("Theme"),
																						 value: Text(preferences.themeName)) })
			}

			PreferencesGroup(header: Text("Keyboard")) {
				PreferencesPicker(selection: preferences.$keyboardArrowsStyle,
													label: Text("Arrow Keys"),
													valueLabel: Text(preferences.keyboardArrowsStyle.name),
													asLink: true) {
					ForEach(KeyboardArrowsStyle.allCases, id: \.self) { key in
						HStack(alignment: .center) {
							Text(key.name)
							Spacer()
							KeyboardToolbarKeyStack(toolbar: .padPrimaryTrailing,
																			arrowsStyle: key,
																			toggledKeys: $toggledKeys)
								.disabled(true)
						}
							.height(44)
					}
				}
			}


			PreferencesGroup {
				NavigationLink(destination: SettingsAdvancedView(),
											 label: { Text("Advanced") })
			}

			PreferencesGroup {
				NavigationLink(destination: SettingsAboutView(),
											 label: { Text("About") })
			}
		}
			.listStyle(InsetGroupedListStyle())

		return NavigationView {
			list
				.navigationBarTitle("SETTINGS", displayMode: .large)
				.navigationBarItems(trailing: Button(action: { self.dismiss() },
																						 label: { Text(verbatim: .done).bold() }))
		}
			.navigationViewStyle(StackNavigationViewStyle())
	}
}

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsView()
	}
}
