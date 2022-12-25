//
//  SettingsView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI
import CoreHaptics
import NewTermCommon

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

fileprivate extension KeyboardTrackpadSensitivity {
	var name: String {
		switch self {
		case .off:    return "Off"
		case .low:    return "Low"
		case .medium: return "Medium"
		case .high:   return "High"
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

			PreferencesGroup(header: Text("Keyboard"),
											 footer: Text("Touch and hold the Space bar, then drag around the keyboard to move the cursor.")) {
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

				PreferencesPicker(selection: preferences.$keyboardTrackpadSensitivity,
													label: Text("Trackpad Sensitivity"),
													valueLabel: Text(preferences.keyboardTrackpadSensitivity.name),
													asStepper: true)
			}

			PreferencesGroup(header: Text("Bell"),
											 footer: Text("When a terminal application needs to notify you of something, it rings the bell.")) {
				Toggle("Make beep sound", isOn: preferences.$bellSound)
				if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
					Toggle("Make haptic vibration", isOn: preferences.$bellVibrate)
				}
				Toggle("Show heads-up display", isOn: preferences.$bellHUD)
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
			.onChange(of: [preferences.bellVibrate, preferences.bellSound]) { _ in
				HapticController.playBell()
			}

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
