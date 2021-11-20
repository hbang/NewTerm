//
//  PreferencesList.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 25/9/21.
//

import SwiftUI

struct PreferencesList<Content: View>: View {

	var content: Content

	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	var body: some View {
#if targetEnvironment(macCatalyst)
		ScrollView {
			VStack(alignment: .leading, spacing: 10) {
				content
			}
			.padding([.top, .bottom], 16)
			.padding([.leading, .trailing], 20)
		}
			.navigationBarTitleDisplayMode(.inline)
#else
		List {
			content
		}
			.listStyle(InsetGroupedListStyle())
			.navigationBarTitleDisplayMode(.inline)
#endif
	}

}
