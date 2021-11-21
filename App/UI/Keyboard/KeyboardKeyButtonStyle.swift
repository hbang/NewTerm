//
//  KeyboardButtonStyle.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 11/21/21.
//

import SwiftUI

struct KeyboardKeyButtonStyle: ButtonStyle {
	var selected: Bool = false
	var shadow: Bool = false
	var fixedWidth: CGFloat?
	
	func makeBody(configuration: Configuration) -> some View {
		if fixedWidth == nil {
			configuration.label
				.font(.system(size: isBigDevice ? 15 : 13))
				.frame(height: (isBigDevice ? 35 : 30))
				.padding(.horizontal, 8)
				.background(configuration.isPressed ? Color(.keyBackgroundHighlighted) : (selected ? Color(.keyBackgroundSelected) : Color(.keyBackgroundNormal)))
				.cornerRadius(isBigDevice ? 6 : 4)
				.shadow(color: shadow ? Color.black.opacity(0.8) : .clear, radius: 0, x: 0, y: shadow ? 1 : 0)
				.animation(nil)
		} else {
			configuration.label
				.font(.system(size: isBigDevice ? 15 : 13))
				.frame(width: fixedWidth!, height: (isBigDevice ? 35 : 30))
				.background(configuration.isPressed ? Color(.keyBackgroundHighlighted) : (selected ? Color(.keyBackgroundSelected) : Color(.keyBackgroundNormal)))
				.cornerRadius(isBigDevice ? 6 : 4)
				.shadow(color: shadow ? Color.black.opacity(0.8) : .clear, radius: 0, x: 0, y: shadow ? 1 : 0)
				.animation(nil)
		}
	}
	
	init(selected: Bool = false, hasShadow shadow: Bool = false, fixedWidth: CGFloat? = nil) {
		self.selected = selected
		self.shadow = shadow
		self.fixedWidth = fixedWidth
	}
}

extension ButtonStyle where Self == KeyboardKeyButtonStyle {
	
	///A button style that mimicks the keys of the software keyboard.
	static func keyboardKey(selected: Bool = false, hasShadow shadow: Bool = false, fixedWidth: CGFloat? = nil) -> KeyboardKeyButtonStyle {
		return KeyboardKeyButtonStyle(selected: selected, hasShadow: shadow, fixedWidth: fixedWidth)
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
				Image(systemName: "arrow.down")
			}
			.buttonStyle(.keyboardKey(fixedWidth: 31))
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
