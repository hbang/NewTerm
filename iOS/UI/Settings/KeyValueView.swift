//
//  KeyValueView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI

struct KeyValueView<Title: View, Value: View>: View {

	var icon: Image?
	var title: Title
	var value: Value

	var body: some View {
		HStack {
			icon
				.frame(width: 29, height: 29, alignment: .center)
			title
			Spacer()
			value
				.foregroundColor(.secondary)
		}
	}

}

struct KeyValueView_Previews: PreviewProvider {
	static var previews: some View {
		List {
			NavigationLink(
				destination: List() {},
				label: {
					KeyValueView(
						title: Text("Font"),
						value: Text("SF Mono")
					)
				}
			)
		}
		.listStyle(GroupedListStyle())
	}
}

