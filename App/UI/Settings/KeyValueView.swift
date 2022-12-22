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

	init(icon: Image? = nil, title: Title, value: Value) {
		self.icon = icon
		self.title = title
		self.value = value
	}

	init(icon: Image? = nil, title: Title, @ViewBuilder value: () -> (Value)) {
		self.icon = icon
		self.title = title
		self.value = value()
	}

	var body: some View {
		HStack {
			icon
				.frame(width: 29, height: 29, alignment: .center)
			title
				.lineLimit(1)
			Spacer()
			value
				.lineLimit(1)
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

