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
					.multilineTextAlignment(.center)
					.font(.system(size: 14, weight: .semibold))

				Spacer(minLength: 15)

				Text("This is a beta — thanks for trying it out! If you find any issues, please let us know.")
					.multilineTextAlignment(.center)
					.font(.system(size: 12, weight: .regular))
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

