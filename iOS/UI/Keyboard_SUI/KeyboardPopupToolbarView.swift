//
//  KeyboardPopupToolbarView.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 4/19/21.
//

import SwiftUI

struct KeyboardPopupToolbarView: View {
    var body: some View {
        VStack(spacing: 5){
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: 5){
                    ForEach(1...12, id: \.self) { index in
                        Button(action: {
                            switch index {
                            case 1:
                                print("f1")
                            case 2:
                                print("f2")
                            case 3:
                                print("f3")
                            case 4:
                                print("f4")
                            case 5:
                                print("f5")
                            case 6:
                                print("f6")
                            case 7:
                                print("f7")
                            case 8:
                                print("f8")
                            case 9:
                                print("f9")
                            case 10:
                                print("f10")
                            case 11:
                                print("f11")
                            case 12:
                                print("f12")
                            default:
                                print("unknown")
                            }
                        }, label: {
                            Text("F\(index)")
                        })
                        .buttonStyle(KeyboardToolbarButtonStyle(fixedWidth: 40))
                    }
                }.padding(.horizontal, 5)
            }
            
            HStack(spacing: 5){
                Group{
                    Button(action: {
                        print("home")
                    }, label: {
                        Text("Home")
                    })
                    Button(action: {
                        print("end")
                    }, label: {
                        Text("End")
                    })
                }.buttonStyle(KeyboardToolbarButtonStyle(fixedWidth: 60))
                Spacer()
                    .frame(width: 0)
                Group{
                    Button(action: {
                        print("pg up")
                    }, label: {
                        Text("PgUp")
                    })
                    Button(action: {
                        print("pg dn")
                    }, label: {
                        Text("PgDn")
                    })
                }.buttonStyle(KeyboardToolbarButtonStyle(fixedWidth: 60))
                Spacer()
                Button(action: {
                    print("frwd del")
                }, label: {
                    Image(systemName: "delete.right")
                })
            }
            .padding(.horizontal, 5)
        }
        .buttonStyle(KeyboardToolbarButtonStyle())
        .frame(maxWidth: .infinity, maxHeight: isBigDevice ? 90 : 74)
        .background(Color(.keyboardToolbarBackground))
    }
}

struct KeyboardPopupToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self, content: KeyboardPopupToolbarView().preferredColorScheme)
            .previewLayout(.sizeThatFits)
    }
}
