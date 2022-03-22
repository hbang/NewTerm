//
//  SettingsGeneralView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 17/9/21.
//

import SwiftUI
import Combine
import CoreServices
import NewTermCommon

#if targetEnvironment(macCatalyst)
private struct FooterText: View {
	var text: Text

	var body: some View {
		text
			.font(.caption)
			.padding([.leading, .trailing, .bottom], 10)
			.foregroundColor(.secondary)
	}
}

struct SettingsGeneralView: View {

	@ObservedObject private var preferences = Preferences.shared

	@State private var syncPathBrowsePresented = false

	var body: some View {
		PreferencesList {
			PreferencesGroup(
				header: Text("Bell"),
				footer: Text("When a terminal application needs to notify you of something, it rings the bell.")
			) {
				Toggle("Make beep sound", isOn: preferences.$bellSound)
				Toggle("Show heads-up display", isOn: preferences.$bellHUD)
			}

			PreferencesGroup(
				header: Text("Settings Sync"),
				footer: Text("Keep your NewTerm settings in sync between your Mac, iPhone, and iPad by selecting iCloud sync. If you just want to keep a backup with a service such as Dropbox, select custom folder sync.")
			) {
				PreferencesPicker(selection: preferences.$preferencesSyncService, label: "Sync app settings:") {
					Text("Don’t sync")
						.tag(PreferencesSyncService.none)
					Text("via iCloud")
						.tag(PreferencesSyncService.icloud)
					Text("via custom folder")
						.tag(PreferencesSyncService.folder)
				}

				HStack {
					TextField("Sync path:", text: preferences.$preferencesSyncPath)
					Button("Browse") {
						syncPathBrowsePresented.toggle()
					}
					.fileImporter(isPresented: $syncPathBrowsePresented,
												allowedContentTypes: [.folder]) { result in
						preferences.preferencesSyncPath = (try? result.get())?.path ?? ""
					}
				}
				.disabled(preferences.preferencesSyncService != .folder)
			}
		}
		.navigationBarTitle("General")
	}

}

struct SettingsGeneralView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsGeneralView()
			.previewLayout(.fixed(width: 600, height: 500))
	}
}
#endif


