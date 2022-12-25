//
//  PreferencesGroup.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 25/9/21.
//

import SwiftUI

struct PreferencesGroup<Header: View, Footer: View, Content: View>: View {

	var header: Header
	var footer: Footer
	var content: Content

	init(header: Header, footer: Footer, @ViewBuilder content: () -> Content) {
		self.header = header
		self.footer = footer
		self.content = content()
	}

	var body: some View {
		#if targetEnvironment(macCatalyst)
		VStack(alignment: .leading, spacing: 6) {
			GroupBox(label: header) {
				VStack(alignment: .leading, spacing: 0) {
					content
						.padding([.leading, .trailing], 6)
						.padding([.top, .bottom], 4)
						.frame(maxWidth: .infinity, minHeight: 0, alignment: .leading)
				}
			}
			footer
				.font(.caption)
				.padding([.leading, .trailing], 10)
				.foregroundColor(.secondary)
		}
			.pickerStyle(InlinePickerStyle())
		#else
		Section(header: header,
						footer: footer) {
			content
		}
		#endif
	}

}

extension PreferencesGroup where Header == EmptyView, Footer: View, Content: View {
	init(footer: Footer, @ViewBuilder content: () -> Content) {
		self.init(header: EmptyView(), footer: footer, content: content)
	}
}

extension PreferencesGroup where Header: View, Footer == EmptyView, Content: View {
	init(header: Header, @ViewBuilder content: () -> Content) {
		self.init(header: header, footer: EmptyView(), content: content)
	}
}

extension PreferencesGroup where Header == EmptyView, Footer == EmptyView, Content: View {
	init(@ViewBuilder content: () -> Content) {
		self.init(header: EmptyView(), footer: EmptyView(), content: content)
	}
}
