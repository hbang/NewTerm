//
//  SettingsAboutView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI

struct SettingsAboutView: View {

	private let version: String = {
		let info = Bundle.main.infoDictionary!
		return "\(info["CFBundleShortVersionString"] as! String) (\(info["CFBundleVersion"] as! String))"
	}()
    
    @State var showingAcknowledgements = false
    @State var showingTipJar = false
    @State var showingHashbangProductions = false

	var body: some View {
		ScrollView {
			VStack(spacing: 15) {
				LogoHeaderViewRepresentable()
					.frame(height: 200)

				Text("Version \(version)")
					.fixedSize(horizontal: false, vertical: true)
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
					.multilineTextAlignment(.center)
					.font(.system(size: 14, weight: .semibold))

				Text("This is a beta — thanks for trying it out! If you find any issues, please let us know.")
					.fixedSize(horizontal: false, vertical: true)
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
					.multilineTextAlignment(.center)
					.font(.system(size: 12, weight: .regular))

                Button(action: {
                    showingAcknowledgements = true
                }, label: {
                    Text("Acknowledgements")
                })
                .sheet(isPresented: $showingAcknowledgements){
                    SafariView(url: URL(string: "https://github.com/hbang/NewTerm/blob/master/LICENSE.md")!, configuration: SafariView.Configuration(entersReaderIfAvailable: false, barCollapsingEnabled: false))
                }
                .padding()

				Text("If you like our work, please consider showing your appreciation with a small donation to the tip jar.")
					.fixedSize(horizontal: false, vertical: true)
					.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
					.multilineTextAlignment(.center)
					.font(.system(size: 12, weight: .regular))

                Button(action: {
                    showingTipJar = true
                }, label: {
                    Text("Tip Jar")
                })
                .sheet(isPresented: $showingTipJar){
                    SafariView(url: URL(string: "https://hashbang.productions/donate/")!, configuration: SafariView.Configuration(entersReaderIfAvailable: false, barCollapsingEnabled: false))
                }
                .padding()

				Divider()
                    .padding(15)
					.fixedSize(horizontal: false, vertical: true)
                
                Button(action: {
                    showingHashbangProductions = true
                }, label: {
                    VStack {
                        Image("hashbang")
                        Text("© HASHBANG Productions")
                            .foregroundColor(.secondary)
                            .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 12, weight: .regular))
                    }
                })
                .sheet(isPresented: $showingHashbangProductions){
                    SafariView(url: URL(string: "https://hashbang.productions")!, configuration: SafariView.Configuration(entersReaderIfAvailable: false, barCollapsingEnabled: false))
                }
                .padding()

				Text("Dedicated to Dennis Bednarz (2000 — 2019), a friend and visionary of the iOS community taken from us too soon.")
					.fixedSize(horizontal: false, vertical: true)
					.frame(width: 260)
					.foregroundColor(.secondary)
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 30, trailing: 15))
					.multilineTextAlignment(.center)
					.font(.system(size: 12, weight: .regular))
			}
		}
		.navigationBarTitle("", displayMode: .inline)
		.background(Color(UIColor.systemGroupedBackground))
	}
}

struct SettingsAboutView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsAboutView()
		SettingsAboutView()
			.previewDevice("iPod touch (7th generation)")
	}
}

