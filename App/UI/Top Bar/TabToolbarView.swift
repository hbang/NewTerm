//
//  TabToolbar.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/8/2022.
//

import SwiftUI
import SwiftUIX
import NewTermCommon

struct TerminalTab: Hashable {
	var title: String
	var screenSize: ScreenSize
}

class TabToolbarState: ObservableObject {
	@Published var delegate: TabToolbarDelegate?
	@Published var terminals = [TerminalTab]()
	@Published var selectedIndex = 0
}

struct TabToolbarView: View {

	private static let height: CGFloat = 32

	@EnvironmentObject private var state: TabToolbarState

	@Environment(\.horizontalSizeClass)
	private var horizontalSizeClass

	var body: some View {
		if horizontalSizeClass == .compact {
			VStack(spacing: 2) {
				HStack(alignment: .center, spacing: 6) {
					Color.clear
						.frame(width: 3 + (Self.height + 6) * 3)
					titleLabel
					buttons
				}
					.frame(height: Self.height)
				tabs
					.frame(height: Self.height)
			}
		} else {
			HStack(alignment: .center, spacing: 6) {
				tabs
				buttons
			}
				.frame(height: Self.height)
		}
	}

	private var tabs: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			LazyHStack(spacing: 0) {
				ForEach(Array(zip(state.terminals, state.terminals.indices)), id: \.1) { terminal, index in
					HStack(spacing: -2) {
						Button {
							state.delegate?.removeTerminal(at: index)
						} label: {
							Image(systemName: .xmarkSquareFill)
								.font(.system(size: 12 * 1.15))
								.foregroundColor(.label.opacity(0.5))
						}
							.frame(width: Self.height, height: Self.height)
							.accessibilityLabel("Close Tab")

						Text(terminal.title)
							.font(.system(size: 12, weight: .semibold))
							.foregroundColor(.label)
					}
						.frame(height: Self.height)
						.padding(.trailing, 10)
						.background(state.selectedIndex == index ? Color(.tabSelected) : nil)
						.onTapGesture {
							state.delegate?.selectTerminal(at: index)
						}
				}
			}
		}
	}

	private var titleLabel: some View {
		HStack {
			Spacer()
			Text("Terminal")
				.font(.system(size: 17, weight: .semibold))
			Spacer()
		}
	}

	private var buttons: some View {
		HStack(spacing: 0) {
			Button {
				state.delegate?.openPasswordManager()
			} label: {
				Image(systemName: "key.fill")
			}
				.frame(width: Self.height, height: Self.height)
				.padding(.horizontal, 3)
				.accessibilityLabel("Password Manager")

			Button {
				state.delegate?.openSettings()
			} label: {
				Image(systemName: .gear)
			}
				.frame(width: Self.height, height: Self.height)
				.padding(.horizontal, 3)
				.accessibilityLabel("Settings")

			Button {
				state.delegate?.addTerminal()
			} label: {
				Image(systemName: .plus)
			}
				.frame(width: Self.height, height: Self.height)
				.padding(.horizontal, 3)
				.padding(.trailing, 3)
				.accessibilityLabel("New Tab")
		}
			.foregroundColor(.accentColor)
			.font(.system(size: 17 * 0.9, weight: .medium))
			.imageScale(.large)
	}

}

struct TabToolbarView_Previews: PreviewProvider {
	static var previews: some View {
		let state = TabToolbarState()
		state.selectedIndex = 0
		state.terminals = [
			TerminalTab(title: "nano",
									screenSize: ScreenSize(cols: 80, rows: 25)),
			TerminalTab(title: "mobile@iphone: ~",
									screenSize: ScreenSize(cols: 80, rows: 25)),
		]

		return ForEach(ColorScheme.allCases, id: \.self) { scheme in
			VStack {
				TabToolbarView()
					.environmentObject(state)
					.background(BlurEffectView(style: .systemChromeMaterial))
					.preferredColorScheme(scheme)
				Spacer()
			}
			.previewDisplayName("\(scheme)")
			.previewLayout(.fixed(width: 414, height: 100))
		}
	}
}
