//
//  SettingsAboutView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import SwiftUI
import SwiftUIX

struct SettingsAboutView: View {
	
	var windowScene: UIWindowScene?
	
	private let version: String = {
		let info = Bundle.main.infoDictionary!
		return "\(info["CFBundleShortVersionString"] as! String) (\(info["CFBundleVersion"] as! String))"
	}()
	
	@State private var showingAcknowledgements = false
	@State private var showingTipJar = false
	@State private var showingShare = false
	@State private var showingHashbangProductions = false
	
	var body: some View {
		let safariConfig = SafariView.Configuration(entersReaderIfAvailable: false,
																								barCollapsingEnabled: false)
		
		let guts = ScrollView {
			VStack(spacing: 15) {
				LogoHeaderViewRepresentable()
					.frame(height: 200)
					.ignoresSafeArea()
				
				Text("NewTerm \(version)")
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
					.font(.system(size: 16, weight: .semibold))
				
				VStack(alignment: .leading, spacing: 15) {
					Text("This is a beta — thanks for trying it out! If you find any issues, please let us know.")
						.fixedSize(horizontal: false, vertical: true)
						.padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
						.font(.system(size: 14))
					
					Button(
						action: {
							var url = URLComponents(string: "mailto:support@hbang.ws")!
							url.queryItems = [
								URLQueryItem(name: "subject", value: "NewTerm \(version) – Support")
							]
							UIApplication.shared.open(url.url!,
																				options: [:],
																				completionHandler: nil)
						},
						label: {
							Label(
								title: { Text("Email Support") },
								icon: {
									IconView(
										icon: Image(systemName: .envelope)
											.resizable(),
										backgroundColor: .blue
									)
								}
							)
						}
					)
						.buttonStyle(GroupedButtonStyle())
				}
				
				VStack(alignment: .leading, spacing: 15) {
					Text("If you like our work, please consider showing your appreciation with a small donation to the tip jar.")
						.fixedSize(horizontal: false, vertical: true)
						.padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
						.font(.system(size: 14))
					
					Button(
						action: {
							showingTipJar.toggle()
						},
						label: {
							Label(
								title: { Text("Tip Jar") },
								icon: {
									IconView(
										icon: Image(systemName: .heart)
											.resizable(),
										backgroundColor: .red
									)
								}
							)
						}
					)
						.buttonStyle(GroupedButtonStyle())
						.safariView(isPresented: $showingTipJar,
												url: URL(string: "https://hashbang.productions/donate/")!,
												configuration: safariConfig)
				}
				
				VStack(alignment: .leading, spacing: 15) {
					Text("…or just let your friends know about NewTerm. We really appreciate it!")
						.fixedSize(horizontal: false, vertical: true)
						.padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
						.font(.system(size: 14, weight: .regular, design: .rounded))
						.foregroundColor(.primary)
						.textCase(nil)
					
					Button(
						action: {
							showingShare.toggle()
						},
						label: {
							Label(
								title: { Text("Share NewTerm") },
								icon: {
									IconView(
										icon: Image(systemName: .squareAndArrowUp)
											.resizable(),
										backgroundColor: Color(UIColor.systemIndigo)
									)
								}
							)
						}
					)
						.buttonStyle(GroupedButtonStyle())
						.activityView(isPresented: $showingShare,
													activityItems: [
														"Check out NewTerm! 🧑‍💻",
														URL(string: "https://newterm.app/")!
													])
				}
				
				NavigationLink(
					destination: SettingsAcknowledgementsView(),
					label: {
						HStack {
							Spacer()
							Text("License & Acknowlegements")
								.font(.system(size: 12))
							Spacer()
						}
					}
				)
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
				
				Divider()
					.padding(15)
					.fixedSize(horizontal: false, vertical: true)
				
				Button(
					action: {
						showingHashbangProductions.toggle()
					},
					label: {
						VStack {
							Image("hashbang")
							Text("© HASHBANG Productions")
								.foregroundColor(.secondary)
								.padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
								.multilineTextAlignment(.center)
								.font(.system(size: 12, weight: .regular))
						}
					}
				)
					.buttonStyle(PlainButtonStyle())
					.padding()
					.safariView(isPresented: $showingHashbangProductions,
											url: URL(string: "https://hashbang.productions")!,
											configuration: safariConfig)
				
				Text("Dedicated to Dennis Bednarz (2000 – 2019), a friend and visionary of the iOS community taken from us too soon.")
					.fixedSize(horizontal: false, vertical: true)
					.frame(width: 260)
					.foregroundColor(.secondary)
					.padding(15)
					.multilineTextAlignment(.center)
					.font(.system(size: 12, weight: .regular))
			}
		}
		
		if windowScene == nil {
			return AnyView(
				guts
					.navigationBarTitle("", displayMode: .inline)
					.background(Color(UIColor.systemGroupedBackground))
			)
		} else {
			return AnyView(
				NavigationView {
					guts
						.ignoresSafeArea(edges: .top)
				}
					.navigationViewStyle(StackNavigationViewStyle())
					.navigationBarHidden(true)
			)
		}
	}
}

struct SettingsAboutView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SettingsAboutView()
		}
		NavigationView {
			SettingsAboutView()
		}
		.previewDevice("iPod touch (7th generation)")
	}
}
