//
//  PreferencesPicker.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 5/12/21.
//

import SwiftUI

struct PreferencesPicker<Label: View, SelectionValue: Hashable, Content: View>: View {

	var label: Label
	var selectionBinding: Binding<SelectionValue>
	var content: Content

	init(selection: Binding<SelectionValue>, label: Label, @ViewBuilder content: () -> Content) {
		self.label = label
		self.selectionBinding = selection
		self.content = content()
	}

	var body: some View {
#if targetEnvironment(macCatalyst)
		Picker(
			selection: selectionBinding,
			content: { content },
			label: { label }
		)
#else
		Section(
			header: label
		) {
			Picker(
				selection: selectionBinding,
				content: { content },
				label: { label }
			)
		}
			.pickerStyle(InlinePickerStyle())
#endif
	}

}

extension PreferencesPicker where Label == Text {
	init(selection: Binding<SelectionValue>, label: String, @ViewBuilder content: () -> Content) {
		self.label = Text(label)
		self.selectionBinding = selection
		self.content = content()
	}
}
