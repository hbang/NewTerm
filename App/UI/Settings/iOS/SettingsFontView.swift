//
//  SettingsFontView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI
import Combine

struct SettingsFontView: View {

	private let predefinedFonts = AppFont.predefined
	private let sortedFonts = AppFont.predefined
		.sorted(by: { a, b in a.key < b.key })

	@ObservedObject var preferences = Preferences.shared

	var body: some View {
		VStack(spacing: 0) {
			TerminalSampleViewRepresentable(
				fontMetrics: preferences.fontMetrics,
				colorMap: preferences.colorMap
			)

			PreferencesList {
				PreferencesGroup(header: Text("Font")) {
					PreferencesPicker(selection: preferences.$fontName, label: EmptyView()) {
						ForEach(sortedFonts, id: \.key) { key, value in
							HStack(alignment: .center) {
								if value.previewFont == nil {
									Image(systemName: "arrow.down.circle")
										.font(.body.weight(.medium))
										.foregroundColor(.accentColor)
										.accessibility(label: Text("Not installed. Tap to download."))
								}

								Text(key)
									.font(Font(value.previewFont ?? UIFont.preferredFont(forTextStyle: .body)))
								Spacer()
							}
						}
					}
				}

#if !targetEnvironment(macCatalyst)
				PreferencesGroup {
					Stepper(value: preferences.$fontSizePhone, in: 10...20, step: 1) {
						Text("Font Size: \(Int(preferences.fontSizePhone))")
					}
				}
#endif
			}
		}
		.navigationBarTitle("Font")
	}

}

struct SettingsFontView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SettingsFontView()
		}
	}
}
