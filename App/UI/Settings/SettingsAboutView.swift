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
	@State private var showingShare = false

	var body: some View {
		var supportURL = URLComponents(string: "mailto:support@hbang.ws")!
		supportURL.queryItems = [
			URLQueryItem(name: "subject", value: "NewTerm \(version) – Support")
		]

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

					Link(
						destination: supportURL.url!,
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
					SponsorsView()
						.fixedSize(horizontal: false, vertical: true)
						.padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
						.font(.system(size: 14))

					Link(
						destination: URL(string: "https://hashbang.productions/donate/")!,
						label: {
							Label(
								title: { Text("Support NewTerm Development") },
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
														String.localize("Check out NewTerm, a modern, super fast terminal app for iOS and macOS! 🧑‍💻"),
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
								.buttonStyle(PlainButtonStyle())
							Spacer()
						}
					}
				)
					.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))

				Divider()
					.padding(15)
					.fixedSize(horizontal: false, vertical: true)

				Link(
					destination: URL(string: "https://hashbang.productions/")!,
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
