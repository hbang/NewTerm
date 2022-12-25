//
//  SettingsInterfaceView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 17/9/21.
//

import SwiftUI
import Combine

#if targetEnvironment(macCatalyst)
struct SettingsInterfaceView: View {

	private let predefinedFonts = AppFont.predefined
	private let sortedFonts = AppFont.predefined
		.sorted(by: { a, b in a.key < b.key })

	private let predefinedThemes = AppTheme.predefined
	private let sortedThemes = AppTheme.predefined
		.sorted(by: { a, b in a.key < b.key })

	@ObservedObject var preferences = Preferences.shared

	@State var isSystemFont = false

	var body: some View {
		let sampleView = VStack(spacing: 0) {
			Rectangle()
				.frame(height: 26)
				.foregroundColor(.secondarySystemBackground)
				.overlay(
					HStack(spacing: 8) {
						Circle()
							.frame(width: 12, height: 12, alignment: .center)
							.foregroundColor(.red)
						Circle()
							.frame(width: 12, height: 12, alignment: .center)
							.foregroundColor(.yellow)
						Circle()
							.frame(width: 12, height: 12, alignment: .center)
							.foregroundColor(.green)
						Spacer()
						Text("Preview")
							.fontWeight(.semibold)
							.foregroundColor(.label)
						Spacer()
						Rectangle()
							.foregroundColor(.clear)
							.frame(width: 52)
					}
						.padding([.leading, .trailing], 7)
				)
				.padding([.top, .leading, .trailing], 1 / UIScreen.main.scale)
			Divider()
				.padding([.leading, .trailing], 1 / UIScreen.main.scale)
			TerminalSampleView(fontMetrics: preferences.fontMetrics,
												 colorMap: preferences.colorMap)
		}
			.frame(width: 320)
			.clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 8, style: .continuous)
					.strokeBorder(.tertiarySystemBackground, lineWidth: 1 / UIScreen.main.scale)
					.foregroundColor(.clear)
			)
			.padding([.top, .bottom, .leading], 20)

		let themes = PreferencesPicker(selection: preferences.$themeName,
																	 label: Text("Theme")) {
			ForEach(sortedThemes, id: \.key) { key, _ in
				Text(key)
			}
		}
			.pickerStyle(MenuPickerStyle())

		let fonts = PreferencesPicker(selection: preferences.$fontName,
																	label: Text("Font")) {
			Text("Default (SF Mono)")
				.id("SF Mono")
			HStack {
				Text("Custom: \(preferences.fontName)")
				Button(action: {},
							 label: { Label("Choose Font…", systemImage: "textformat").labelStyle(TitleOnlyLabelStyle()) })
			}
		}

		let fontSize = TextField("Font Size",
														 text: Binding(get: {
			let numberFormatter = NumberFormatter()
			numberFormatter.numberStyle = .decimal
			numberFormatter.minimumFractionDigits = 0
			numberFormatter.maximumFractionDigits = 2
			return numberFormatter.string(for: preferences.fontSizeMac) ?? "12"
		},
																					 set: { value in
			if let value = Double(value ?? "") {
				preferences.fontSizeMac = value
			}
		}))
			.keyboardType(.decimalPad)

		return HStack(spacing: 0) {
			sampleView
			PreferencesList {
				Text("Note: You currently need to restart the app to have theme updates apply.")
				themes
				fonts
				fontSize
			}
		}
		.navigationBarTitle("Interface", displayMode: .inline)
	}

}

struct SettingsInterfaceView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsInterfaceView()
			.previewLayout(.fixed(width: 600, height: 500))
	}
}
#endif
