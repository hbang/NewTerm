//
//  PreferencesPicker.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 5/12/21.
//

import SwiftUI

struct PreferencesPicker<Label: View, ValueLabel: View, SelectionValue: Hashable, Content: View, InnerContent: View>: View {

	let selectionBinding: Binding<SelectionValue>
	let label: Label
	let keyValueLabel: KeyValueView<Label, ValueLabel>?
	let asLink: Bool
	let asStepper: Bool
	let content: InnerContent

	@State private var isLinkActive = false

	private init() {
		fatalError()
	}

	var body: some View {
#if targetEnvironment(macCatalyst)
		Picker(selection: selectionBinding,
					 content: { content },
					 label: { label })
#else
		if asStepper {
			content
		} else if asLink,
							let label = label as? Text {
			NavigationLink(isActive: $isLinkActive,
										 destination: { PreferencesPickerPage(selection: selectionBinding,
																													isLinkActive: $isLinkActive,
																													label: label,
																													content: { content }) },
										 label: { keyValueLabel })
		} else {
			Section(header: label) {
				Picker(selection: selectionBinding,
							 content: { content },
							 label: { label })
			}
				.pickerStyle(InlinePickerStyle())
		}
#endif
	}

}

extension PreferencesPicker where ValueLabel == EmptyView, InnerContent == Content {
	init(selection: Binding<SelectionValue>,
			 label: Label,
			 @ViewBuilder content: () -> Content) {
		self.selectionBinding = selection
		self.label = label
		self.keyValueLabel = KeyValueView(title: label, value: EmptyView())
		self.asLink = false
		self.asStepper = false
		self.content = content()
	}
}

extension PreferencesPicker where Label == Text, ValueLabel == Text, InnerContent == Content {
	init(selection: Binding<SelectionValue>,
			 label: Label,
			 valueLabel: ValueLabel,
			 asLink: Bool = false,
			 @ViewBuilder content: () -> Content) {
		self.selectionBinding = selection
		self.label = label
		self.keyValueLabel = KeyValueView(title: label, value: valueLabel)
		self.asLink = asLink
		self.asStepper = false
		self.content = content()
	}

	init(selection: Binding<SelectionValue>,
			 label: String,
			 valueLabel: String,
			 asLink: Bool = false,
			 @ViewBuilder content: () -> Content) {
		self.selectionBinding = selection
		self.label = Text(label)
		self.keyValueLabel = KeyValueView(title: Text(label), value: Text(valueLabel))
		self.asLink = asLink
		self.asStepper = false
		self.content = content()
	}
}

extension PreferencesPicker where Label == Text, ValueLabel == Text,
																	InnerContent == Content, InnerContent == Stepper<KeyValueView<Label, ValueLabel>>,
																	SelectionValue: RawRepresentable & CaseIterable, SelectionValue.RawValue: FixedWidthInteger {
	init(selection: Binding<SelectionValue>,
			 label: Label,
			 valueLabel: ValueLabel,
			 asStepper: Bool = false) {
		self.selectionBinding = selection
		self.label = label
		let keyValueLabel = KeyValueView(title: label, value: valueLabel)
		self.keyValueLabel = keyValueLabel
		self.asLink = false
		self.asStepper = asStepper
		self.content = Stepper(label: { keyValueLabel },
													 onIncrement: {
			let allCases = SelectionValue.allCases
			if let oldIndex = allCases.firstIndex(of: selection.wrappedValue),
				 allCases.index(oldIndex, offsetBy: 1) < allCases.endIndex {
				selection.wrappedValue = allCases[allCases.index(oldIndex, offsetBy: 1)]
			}
		},
													 onDecrement: {
			let allCases = SelectionValue.allCases
			if let oldIndex = allCases.firstIndex(of: selection.wrappedValue),
				 allCases.index(oldIndex, offsetBy: -1) >= allCases.startIndex {
				selection.wrappedValue = allCases[allCases.index(oldIndex, offsetBy: -1)]
			}
		},
													 onEditingChanged: { _ in })
	}
}

struct PreferencesPickerPage<Label: View, SelectionValue: Hashable, Content: View>: View {

	private let selectionBinding: Binding<SelectionValue>
	private var isLinkActive: Binding<Bool>
	private let label: Text
	private let asLink: Bool
	private let content: Content

	private init() {
		fatalError()
	}

	var body: some View {
		PreferencesList {
			Picker(selection: selectionBinding,
						 content: { content },
						 label: { EmptyView() })
		}
			.pickerStyle(InlinePickerStyle())
			.navigationBarTitle(label)
			.onChange(of: selectionBinding.wrappedValue) { _ in
				self.isLinkActive.wrappedValue = false
			}
	}

}

extension PreferencesPickerPage where Label == Text {
	init(selection: Binding<SelectionValue>,
			 isLinkActive: Binding<Bool>,
			 label: Label,
			 asLink: Bool = false,
			 @ViewBuilder content: () -> Content) {
		self.selectionBinding = selection
		self.isLinkActive = isLinkActive
		self.label = label
		self.asLink = asLink
		self.content = content()
	}
}
