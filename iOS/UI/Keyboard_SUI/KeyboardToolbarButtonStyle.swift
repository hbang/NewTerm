//
//  KeyboardToolbarButtonStyle.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 4/18/21.
//

import SwiftUI

struct KeyboardToolbarButtonStyle: ButtonStyle {
    var selected: Bool = false
    var shadow: Bool = false
    var fixedWidth: CGFloat = 0
    func makeBody(configuration: Configuration) -> some View {
        if fixedWidth.isZero {
            return configuration.label
                .font(.system(size: isBigDevice ? 15 : 13))
                .frame(height: (isBigDevice ? 35 : 30))
                .padding(.horizontal, 8)
                .background(configuration.isPressed ? Color(.keyBackgroundHighlighted) : (selected ? Color(.keyBackgroundSelected) : Color(.keyBackgroundNormal)))
                .cornerRadius(isBigDevice ? 6 : 4)
                .shadow(color: shadow ? Color.black.opacity(0.8) : .clear, radius: 0, x: 0, y: shadow ? 1 : 0)
                .animation(nil)
        } else {
            return configuration.label
                .font(.system(size: isBigDevice ? 18 : 15))
                .frame(width: fixedWidth, height: (isBigDevice ? 35 : 30))
                .background(configuration.isPressed ? Color(.keyBackgroundHighlighted) : (selected ? Color(.keyBackgroundSelected) : Color(.keyBackgroundNormal)))
                .cornerRadius(isBigDevice ? 6 : 4)
                .shadow(color: shadow ? Color.black.opacity(0.8) : .clear, radius: 0, x: 0, y: shadow ? 1 : 0)
                .animation(nil)
        }
    }
}

struct KeyboardToolbarButtonStyle_TestView: View {
    var body: some View {
        Button(action: {
            print("tapped")
        }, label: {
            Image(systemName: "arrow.up")
        }).buttonStyle(KeyboardToolbarButtonStyle())
    }
}

struct KeyboardToolbarButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self, content: KeyboardToolbarButtonStyle_TestView().preferredColorScheme)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
