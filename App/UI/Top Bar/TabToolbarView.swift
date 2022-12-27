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
	var isDirty: Bool
	var hasBell: Bool
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
					TabToolbarItemView(terminal: terminal,
														 isSelected: state.selectedIndex == index,
														 height: Self.height,
														 selectTerminal: { state.delegate?.selectTerminal(at: index) },
														 removeTerminal: { state.delegate?.removeTerminal(at: index) })
				}
			}
		}
	}

	private var titleLabel: some View {
		HStack {
			Spacer()
			Text(state.terminals[state.selectedIndex].title)
				.font(.system(size: 17, weight: .semibold))
			Spacer()
		}
	}

	private var buttons: some View {
		HStack(spacing: 0) {
			Button(action: { state.delegate?.openPasswordManager() },
						 label: { Image(systemName: "key.fill") })
				.squareFrame(sideLength: Self.height)
				.padding(.horizontal, 3)
				.accessibilityLabel("Password Manager")

			Button(action: { state.delegate?.openSettings() },
						 label: { Image(systemName: .gear) })
				.squareFrame(sideLength: Self.height)
				.padding(.horizontal, 3)
				.accessibilityLabel("Settings")

			Button(action: { state.delegate?.addTerminal() },
						 label: { Image(systemName: .plus) })
				.squareFrame(sideLength: Self.height)
				.padding(.horizontal, 3)
				.padding(.trailing, 3)
				.accessibilityLabel("New Tab")
		}
			.foregroundColor(.accentColor)
			.font(.system(size: 17 * 0.9, weight: .medium))
			.imageScale(.large)
	}

}

struct TabToolbarItemView: View {
	var terminal: TerminalTab
	var isSelected: Bool
	var height: CGFloat
	var selectTerminal: () -> Void
	var removeTerminal: () -> Void

	var body: some View {
		let accessibilityLabel: String
		switch true {
		case terminal.hasBell: accessibilityLabel = "\(terminal.title), \(String.localize("has bell"))"
		case terminal.isDirty: accessibilityLabel = "\(terminal.title), \(String.localize("has activity"))"
		default:               accessibilityLabel = terminal.title
		}

		return HStack(spacing: -2) {
			Button(action: removeTerminal,
						 label: {
				switch true {
				case terminal.hasBell:
					Image(systemName: .bellFill)
						.font(.system(size: 12 * 1.05))
						.foregroundColor(.label)

				case terminal.isDirty:
					Image(systemName: .circleFill)
						.font(.system(size: 12 * 0.9))
						.foregroundColor(.label.opacity(0.5))

				default:
					Image(systemName: .xmarkSquareFill)
						.font(.system(size: 12 * 1.15))
						.foregroundColor(.label.opacity(0.5))
				}
			})
				.squareFrame(sideLength: height)
				.accessibilityLabel("Close Tab")

			Text(terminal.title)
				.font(.system(size: 12, weight: .semibold))
				.foregroundColor(.label)
				.accessibilityHidden(true)
		}
			.height(height)
			.padding(.trailing, 10)
			.background(isSelected ? Color(.tabSelected) : nil)
			.accessibilityLabel(accessibilityLabel)
			.accessibilityAddTraits(.isButton)
			.accessibilityAddTraits(isSelected ? .isSelected : [])
			.onTapGesture(perform: selectTerminal)
	}
}

struct TabToolbarView_Previews: PreviewProvider {
	static var previews: some View {
		let state = TabToolbarState()
		state.selectedIndex = 0
		state.terminals = [
			TerminalTab(title: "nano",
									screenSize: ScreenSize(cols: 80, rows: 25),
								  isDirty: false,
								  hasBell: false),
			TerminalTab(title: "mobile@iphone: ~",
									screenSize: ScreenSize(cols: 80, rows: 25),
									isDirty: true,
									hasBell: true),
			TerminalTab(title: "ssh",
									screenSize: ScreenSize(cols: 80, rows: 25),
									isDirty: true,
									hasBell: false),
		]

		return VStack {
			TabToolbarView()
				.environmentObject(state)
				.background(BlurEffectView(style: .systemChromeMaterial))
			Spacer()
		}
	}
}
