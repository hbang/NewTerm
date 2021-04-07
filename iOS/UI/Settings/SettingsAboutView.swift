//
//  SettingsAboutView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI

struct SettingsAboutView: View {

	private let version: String = {
		let info = Bundle.main.infoDictionary!
		return "\(info["CFBundleShortVersionString"] as! String) (\(info["CFBundleVersion"] as! String))"
	}()

	var body: some View {
		ScrollView {
			VStack {
				LogoHeaderViewRepresentable()
					.frame(height: 200)

				Text("Version \(version)")
					.fixedSize(horizontal: false, vertical: true)
					.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
					.multilineTextAlignment(.center)
					.font(.system(size: 14, weight: .semibold))

				Text("This is a beta — thanks for trying it out! If you find any issues, please let us know.")
					.fixedSize(horizontal: false, vertical: true)
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
					.multilineTextAlignment(.center)
					.font(.system(size: 12, weight: .regular))

				NavigationLink(
					destination: SafariViewControllerRepresentable(url: URL(string: "https://github.com/hbang/NewTerm/blob/master/LICENSE.md")!)
						.navigationBarHidden(true),
					label: { Text("Acknowledgements") }
				)
					.fixedSize(horizontal: false, vertical: true)
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))

				Text("If you like our work, please consider showing your appreciation with a small donation to the tip jar.")
					.fixedSize(horizontal: false, vertical: true)
					.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
					.multilineTextAlignment(.center)
					.font(.system(size: 12, weight: .regular))

				NavigationLink(
					destination: SafariViewControllerRepresentable(url: URL(string: "https://hashbang.productions/donate/")!)
						.navigationBarHidden(true),
					label: { Text("Tip Jar") }
				)
					.fixedSize(horizontal: false, vertical: true)
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))

				Divider()
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
					.fixedSize(horizontal: false, vertical: true)

				NavigationLink(
					destination: SafariViewControllerRepresentable(url: URL(string: "https://hashbang.productions/")!)
						.navigationBarHidden(true),
					label: {
						VStack {
							Image("hashbang")
							Text("© HASHBANG Productions")
								.foregroundColor(.secondary)
								.padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
								.multilineTextAlignment(.center)
								.font(.system(size: 12, weight: .regular))
						}
					}
				)
					.fixedSize(horizontal: false, vertical: true)
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
			}
		}
		.navigationBarTitle("", displayMode: .inline)
		.background(Color(UIColor.systemGroupedBackground))
	}
}

struct SettingsAboutView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsAboutView()
		SettingsAboutView()
			.previewDevice("iPod touch (7th generation)")
	}
}

