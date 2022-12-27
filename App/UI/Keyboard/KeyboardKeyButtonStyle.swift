//
//  KeyboardButtonStyle.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 11/21/21.
//

import SwiftUI
import SwiftUIX

struct KeyboardKeyButtonStyle: ButtonStyle {
	var selected = false
	var shadow = false
	var halfHeight = false
	var widthRatio: CGFloat?

	func makeBody(configuration: Configuration) -> some View {
		var height: CGFloat = 45
		let widthRatio = (widthRatio ?? 1) * (isBigDevice ? 1.3 : 1)
		let width = widthRatio == nil ? nil : height * widthRatio
		var fontSize: CGFloat = isBigDevice ? 18 : 15
		var cornerRadius: CGFloat = isBigDevice ? 6 : 4
		if halfHeight {
			height = (height / 2) - 1
			fontSize *= 0.9
			cornerRadius *= 0.75
		}

		let backgroundColor: Color
		if configuration.isPressed {
			backgroundColor = Color(.keyBackgroundHighlighted)
		} else if selected {
			backgroundColor = Color(.keyBackgroundSelected)
		} else {
			backgroundColor = Color(.keyBackgroundNormal)
		}

		return HStack(alignment: .center, spacing: 0) {
			configuration.label
				.font(.system(size: fontSize, weight: .regular).monospacedDigit())
				.padding(.horizontal, halfHeight ? 2 : 8)
				.padding(.vertical, halfHeight ? 0 : 6)
				.foregroundColor(selected && !configuration.isPressed ? .black : .white)
		}
			.frame(minWidth: height, maxWidth: width)
			.frame(height: height)
			.background(
				backgroundColor
					.cornerRadius(cornerRadius)
					.shadow(color: shadow ? .black.opacity(0.8) : .clear,
									radius: 0,
									x: 0,
									y: shadow ? 1 : 0)
			)
			.animation(nil)
	}

	init(selected: Bool = false, hasShadow shadow: Bool = false, halfHeight: Bool = false, widthRatio: CGFloat? = nil) {
		self.selected = selected
		self.shadow = shadow
		self.halfHeight = halfHeight
		self.widthRatio = widthRatio
	}
}

extension ButtonStyle where Self == KeyboardKeyButtonStyle {
	/// A button style that mimicks the keys of the software keyboard.
	static func keyboardKey(selected: Bool = false, hasShadow shadow: Bool = false, halfHeight: Bool = false, widthRatio: CGFloat? = nil) -> KeyboardKeyButtonStyle {
		KeyboardKeyButtonStyle(selected: selected, hasShadow: shadow, halfHeight: halfHeight, widthRatio: widthRatio)
	}
}

struct KeyboardKeyButtonStyleContainer: View {
	var body: some View {
		HStack(alignment: .center, spacing: 5) {
			Button {

			} label: {
				Text("Ctrl")
			}
			.buttonStyle(.keyboardKey())

			Button {

			} label: {
				Image(systemName: .arrowDown)
			}
			.buttonStyle(.keyboardKey(widthRatio: 1))
		}
		.padding()
	}
}

struct KeyboardKeyButtonStyleContainer_Previews: PreviewProvider {
	static var previews: some View {
		ForEach(ColorScheme.allCases, id: \.self) { scheme in
			KeyboardKeyButtonStyleContainer()
				.preferredColorScheme(scheme)
				.previewLayout(.sizeThatFits)
		}
	}
}

