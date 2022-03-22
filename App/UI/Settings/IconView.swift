//
//  IconView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 16/9/21.
//

import SwiftUI

struct IconView<Icon: View>: View {

	enum IconSize: CGFloat {
		case small = 29
		case medium = 40
		case large = 60
	}

	var size: IconSize = .small
	var icon: Icon
	var backgroundColor: Color
	var foregroundColor: Color = .white

	var body: some View {
		let size = self.size.rawValue
		RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
			.frame(width: size, height: size, alignment: .center)
			.foregroundColor(backgroundColor)
			.overlay(
				icon
					.aspectRatio(contentMode: .fit)
					.frame(width: size * 0.7, height: size * 0.7, alignment: .center)
					.foregroundColor(foregroundColor)
			)
	}

}

struct IconView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			List {
				NavigationLink(
					destination: List() {},
					label: {
						HStack {
							IconView(
								icon: Image(systemName: .envelope)
									.resizable(),
								backgroundColor: .blue
							)
							Text("Email Support")
						}
					}
				)
				NavigationLink(
					destination: List() {},
					label: {
						HStack {
							IconView(
								icon: Image(systemName: .heart)
									.resizable(),
								backgroundColor: .red
							)
							Text("Tip Jar")
						}
					}
				)
				NavigationLink(
					destination: List() {},
					label: {
						HStack {
							IconView(
								icon: Image(systemName: .doc)
									.resizable(),
								backgroundColor: .gray
							)
							Text("Acknowledgements")
						}
					}
				)
				NavigationLink(
					destination: List() {},
					label: {
						HStack {
							IconView(
								size: .medium,
								icon: Image(systemName: .star)
									.resizable(),
								backgroundColor: .yellow
							)
							VStack(alignment: .leading) {
								Text("Big button!")
								Text("With a subtitle")
									.foregroundColor(.secondary)
									.font(Font(UIFont.preferredFont(forTextStyle: .footnote)))
							}
						}
					}
				)
				NavigationLink(
					destination: List() {},
					label: {
						HStack {
							IconView(
								size: .large,
								icon: Image(systemName: .sparkles)
									.resizable(),
								backgroundColor: Color(UIColor.systemIndigo)
							)
							VStack(alignment: .leading) {
								Text("Huge icon!")
								Text("Maybe a little too big")
									.foregroundColor(.secondary)
									.font(Font(UIFont.preferredFont(forTextStyle: .footnote)))
							}
						}
					}
				)
			}
			.listStyle(GroupedListStyle())
		}
	}
}

