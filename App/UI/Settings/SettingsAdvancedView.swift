//
//  SettingsAdvancedView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 16/9/21.
//

import SwiftUI

struct SettingsAdvancedView: View {

	private struct LocaleItem: Identifiable, Comparable {
		let locale: Locale
		let name: String
		var id: String { locale == .autoupdatingCurrent ? "" : locale.identifier }

		static func < (lhs: Self, rhs: Self) -> Bool {
			lhs.name < rhs.name
		}
	}

	private var systemLocale: LocaleItem {
		let mainLocale = Locale.autoupdatingCurrent
		let name = String(format: .localize("LOCALE_SYSTEM"),
											mainLocale.localizedString(forIdentifier: mainLocale.identifier) ?? mainLocale.identifier)
		return LocaleItem(locale: mainLocale, name: name)
	}

	private let locales: [LocaleItem] = {
		let mainLocale = Locale.autoupdatingCurrent
		let items = try! FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/usr/share/locale"),
																														 includingPropertiesForKeys: [],
																														 options: .skipsSubdirectoryDescendants)
		return items
			.compactMap { item in
				guard let code = item.pathComponents.last,
							code.hasSuffix(".UTF-8") else {
								return nil
							}
				let locale = Locale(identifier: code)
				return LocaleItem(locale: locale,
													name: mainLocale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
			}
			.sorted()
	}()

	@ObservedObject var preferences = Preferences.shared

	var body: some View {
		let systemLocale = self.systemLocale
		let list = ForEach(locales) { item in
			Text(item.name)
		}

		return PreferencesList {
			#if !targetEnvironment(macCatalyst)
			PreferencesGroup {
				NavigationLink(
					destination: SettingsPerformanceView(),
					label: { Text("Performance") }
				)
			}
			#endif

			PreferencesGroup(
				header: Text("Locale"),
				footer: Text("NewTerm will ask terminal programs to use this locale. Not all programs support this. This will not apply to currently open tabs, and may be overridden by shell startup scripts.")
			) {
				PreferencesPicker(
					selection: preferences.$preferredLocale,
					label: Text("Language")
				) {
					Text(systemLocale.name)
						.tag(systemLocale.id)
					Divider()
					list
				}
				#if targetEnvironment(macCatalyst)
				.pickerStyle(MenuPickerStyle())
				#else
//				.pickerStyle(RadioGroupPickerStyle())
				#endif
			}
		}
		.navigationBarTitle("Advanced")
	}

}

struct SettingsAdvancedView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SettingsAdvancedView()
		}
	}
}
