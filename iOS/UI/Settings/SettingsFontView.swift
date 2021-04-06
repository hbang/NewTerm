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
		let sampleView = TerminalSampleViewRepresentable(
			fontMetrics: preferences.fontMetrics,
			colorMap: preferences.colorMap
		)

		let fontsList = ForEach(sortedFonts, id: \.key) { key, value in
			Button(
				action: {
					preferences.fontName = key
				},
				label: {
					HStack {
						Text(key)
							.foregroundColor(.primary)
							.font(Font(value.previewFont ?? UIFont.preferredFont(forTextStyle: .body)))
						Spacer()

						if value.previewFont == nil {
							Image(systemName: "arrow.down.circle")
								.accessibility(label: Text("Download"))
						}

						if key == preferences.$fontName.wrappedValue {
							Image(systemName: "checkmark")
								.accessibility(label: Text("Selected"))
						}
					}
				}
			)
			.animation(.default)
		}

		let list = List {
			Section(header: Spacer()) {
				fontsList
			}

			#if os(iOS) && !targetEnvironment(macCatalyst)
			Section() {
				Stepper(
					value: Binding(
						get: { preferences.fontSizePhone },
						set: { value in preferences.fontSizePhone = value }
					),
					in: 10...20,
					step: 1
				) {
					Text("Font Size: \(Int(preferences.fontSizePhone))")
				}
			}
			#endif
		}
		.listStyle(GroupedListStyle())

		return VStack {
			sampleView
			list
		}
		.navigationBarTitle("Font", displayMode: .inline)
	}

}

struct SettingsFontView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SettingsFontView()
		}
	}
}
