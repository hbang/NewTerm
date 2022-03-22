//
//  GroupedButtonStyle.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 16/9/21.
//

import SwiftUI

#if targetEnvironment(macCatalyst)
fileprivate typealias ButtonStyleSuperclass = PrimitiveButtonStyle
#else
fileprivate typealias ButtonStyleSuperclass = ButtonStyle
#endif

struct GroupedButtonStyle: ButtonStyleSuperclass {

	func makeBody(configuration: Configuration) -> some View {
#if targetEnvironment(macCatalyst)
		HStack {
			Spacer()
			Button(configuration)
			Spacer()
		}
#else
		HStack {
			configuration.label
			Spacer()
			Text(Image(systemName: .chevronRight))
				.foregroundColor(Color(UIColor.systemGray2))
				.fontWeight(.semibold)
				.imageScale(.small)
		}
		.padding([.top, .bottom], 7)
		.padding([.leading, .trailing], 15)
		.frame(minHeight: 44, alignment: .center)
		.background(Color(configuration.isPressed ? UIColor.tertiarySystemGroupedBackground : UIColor.secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
		.padding([.leading, .trailing], 15)
#endif
	}

}

struct GroupedButtonStyle_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			VStack(spacing: 0) {
				Button(
					action: {},
					label: {
						HStack {
							IconView(
								icon: Image(systemName: .sparkles)
									.resizable(),
								backgroundColor: Color(UIColor.systemIndigo)
							)
							Text("Do stuff")
						}
					}
				)
					.buttonStyle(GroupedButtonStyle())

				List {
					NavigationLink(
						destination: EmptyView(),
						label: {
							HStack {
								IconView(
									icon: Image(systemName: .sparkles)
										.resizable(),
									backgroundColor: Color(UIColor.systemGreen)
								)
								Text("List button comparison")
							}
						}
					)
				}
				.listStyle(InsetGroupedListStyle())
			}
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}
}

