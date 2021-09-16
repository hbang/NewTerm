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
			Image(systemName: "chevron.right")
				.foregroundColor(Color(UIColor.separator))
				.imageScale(.small)
		}
		.padding(EdgeInsets(top: 7, leading: 15, bottom: 7, trailing: 15))
		.frame(minHeight: 44, alignment: .center)
		.background(
			VStack(spacing: 0) {
				Divider()
				Spacer()
				Divider()
			}
				.background(Color(configuration.isPressed ? UIColor.tertiarySystemGroupedBackground : UIColor.secondarySystemGroupedBackground))
		)
		#endif
	}

}

struct GroupedButtonStyle_Previews: PreviewProvider {
	static var previews: some View {
		Button(
			action: {},
			label: {
				HStack {
					IconView(
						icon: Image(systemName: "sparkles")
							.resizable(),
						backgroundColor: Color(UIColor.systemIndigo)
					)
					Text("Do stuff")
				}
			}
		)
			.buttonStyle(GroupedButtonStyle())
	}
}




