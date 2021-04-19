//
//  KeyboardToolbarView.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 4/18/21.
//

import SwiftUI

struct KeyboardToolbarView: View {
    @State var ctrlKeySelected = false
    @State var moreKeySelected = false
    var body: some View {
        HStack(spacing: 5){
            Group{
                Button(action: {
                    ctrlKeySelected.toggle()
                }, label: {
                    Text("Ctrl")
                }).buttonStyle(KeyboardToolbarButtonStyle(selected: ctrlKeySelected, fixedWidth: 35))
                Button(action: {}, label: {
                    Text("Esc")
                })
                Button(action: {}, label: {
                    Text("Tab")
                })
                Button(action: {
                    moreKeySelected.toggle()
                }, label: {
                    Image(systemName: "ellipsis")
                }).buttonStyle(KeyboardToolbarButtonStyle(selected: moreKeySelected, fixedWidth: 35))
            }.buttonStyle(KeyboardToolbarButtonStyle(fixedWidth: 35))
            Spacer()
            Group{
                Button(action: {}, label: {
                    Image(systemName: "arrow.up")
                })
                Button(action: {}, label: {
                    Image(systemName: "arrow.down")
                })
                Button(action: {}, label: {
                    Image(systemName: "arrow.left")
                })
                Button(action: {}, label: {
                    Image(systemName: "arrow.right")
                })
            }.buttonStyle(KeyboardToolbarButtonStyle(fixedWidth: 30))
        }.padding(.horizontal, 5)
        .frame(maxWidth: .infinity, maxHeight: isBigDevice ? 48 : 40)
        .background(Color(.keyboardToolbarBackground))
    }
}

struct KeyboardToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self, content: KeyboardToolbarView().preferredColorScheme)
            .previewLayout(.sizeThatFits)
    }
}
