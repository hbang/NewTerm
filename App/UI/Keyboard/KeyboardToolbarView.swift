//
//  KeyboardToolbarView.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 11/21/21.
//

import SwiftUI
import NewTermCommon
import SwiftUIX

fileprivate struct Key {
	var label: String
	var glyph: String?
	var imageName: SFSymbolName?
	var preferredStyle: KeyboardButtonStyle?
	var isToggle = false
	var halfHeight = false
	var widthRatio: CGFloat?
}

enum Toolbar: CaseIterable {
	case primary, padPrimaryLeading, padPrimaryTrailing
	case secondary, fnKeys

	var keys: [ToolbarKey] {
		switch self {
		case .primary:
			return [
				.control, .escape, .tab, .more,
				.variableSpace,
				.arrows
			]

		case .padPrimaryLeading:
			return [.control, .escape, .tab, .more]

		case .padPrimaryTrailing:
			return [.arrows]

		case .secondary:
			return [
				.home, .end,
				.variableSpace,
				.pageUp, .pageDown,
				.variableSpace,
				.delete,
				.variableSpace,
				.fnKeys
			]

		case .fnKeys:
			return Array(1...12).map { .fnKey(index: $0) }
		}
	}
}

enum ToolbarKey: Hashable {
	// Special
	case fixedSpace, variableSpace, arrows
	// Primary - leading
	case control, escape, tab, more
	// Primary - trailing
	case up, down, left, right
	// Secondary - navigation
	case home, end, pageUp, pageDown
	// Secondary - extras
	case delete, fnKeys
	// Fn keys
	case fnKey(index: Int)

	fileprivate var key: Key {
		switch self {
		// Special
		case .fixedSpace, .variableSpace, .arrows:
			return Key(label: "")

		// Primary - leading
		case .control:  return Key(label: .localize("Control"),
															 glyph: .localize("Ctrl"),
															 imageName: .control,
															 isToggle: true)
		case .escape:   return Key(label: .localize("Escape"),
															 glyph: .localize("Esc"),
															 imageName: .escape)
		case .tab:      return Key(label: .localize("Tab"),
															 imageName: .arrowRightToLine)
		case .more:     return Key(label: .localize("More"),
															 imageName: .ellipsis,
															 preferredStyle: .icons,
															 isToggle: true)
		// Primary - trailing
		case .up:       return Key(label: .localize("Up"),
															 imageName: .arrowUp,
															 preferredStyle: .icons,
															 halfHeight: true,
															 widthRatio: 1)
		case .down:     return Key(label: .localize("Down"),
															 imageName: .arrowDown,
															 preferredStyle: .icons,
															 halfHeight: true,
															 widthRatio: 1)
		case .left:     return Key(label: .localize("Left"),
															 imageName: .arrowLeft,
															 preferredStyle: .icons,
															 halfHeight: true,
															 widthRatio: 1)
		case .right:    return Key(label: .localize("Right"),
															 imageName: .arrowRight,
															 preferredStyle: .icons,
															 halfHeight: true,
															 widthRatio: 1)
		// Secondary - navigation
		case .home:     return Key(label: .localize("Home"),
															 widthRatio: 1.25)
		case .end:      return Key(label: .localize("End"),
															 widthRatio: 1.25)
		case .pageUp:   return Key(label: .localize("Page Up"),
															 glyph: .localize("PgUp"),
															 widthRatio: 1.25)
		case .pageDown: return Key(label: .localize("Page Down"),
															 glyph: .localize("PgDn"),
															 widthRatio: 1.25)

		// Secondary - extras
		case .delete:   return Key(label: .localize("Delete Forward"),
															 glyph: .localize("Del"),
															 imageName: .deleteRight,
															 preferredStyle: .icons,
															 widthRatio: 1)
		case .fnKeys:   return Key(label: .localize("Function Keys"),
															 glyph: .localize("Fn"),
															 isToggle: true,
															 widthRatio: 1)

		// Fn keys
		case .fnKey(let index):
			return Key(label: "F\(index + 1)",
								 preferredStyle: .text,
								 widthRatio: 1.25)
		}
	}
}

protocol KeyboardToolbarViewDelegate: AnyObject {
	func keyboardToolbarDidPressKey(_ key: ToolbarKey)
}

class KeyboardToolbarViewState: ObservableObject {
	@Published var toggledKeys = Set<ToolbarKey>()
}

struct KeyboardToolbarKeyStack: View {
	weak var delegate: KeyboardToolbarViewDelegate?

	let toolbar: Toolbar
	var arrowsStyle: KeyboardArrowsStyle?

	@EnvironmentObject var state: KeyboardToolbarViewState

	@ObservedObject private var preferences = Preferences.shared

	var body: some View {
		HStack(alignment: .center, spacing: 5) {
			ForEach(toolbar.keys, id: \.self) { key in
				switch key {
				case .fixedSpace:    EmptyView()
				case .variableSpace: Spacer(minLength: 0)
				case .arrows:        AnyView(arrowsView)
				default:             button(for: key)
				}
			}
		}
	}

	func button(for key: ToolbarKey, halfHeight: Bool = false) -> some View {
		Button {
			UIDevice.current.playInputClick()

			if key.key.isToggle {
				if state.toggledKeys.contains(key) {
					state.toggledKeys.remove(key)
				} else {
					state.toggledKeys.insert(key)
				}
			}

			delegate?.keyboardToolbarDidPressKey(key)
		} label: {
			switch key {
			case .up, .down, .left, .right:
				Image(systemName: key.key.imageName!)
					.frame(width: 14, height: 14, alignment: .center)
					.accessibilityLabel(key.key.label)

			default:
				VStack(alignment: .trailing, spacing: 2) {
					HStack(spacing: 0) {
						if let imageName = key.key.imageName,
							 key.key.preferredStyle != .text {
							Image(systemName: imageName)
								.imageScale(.small)
								.opacity(0.5)
								.frame(width: 14, height: 14, alignment: .center)
								.padding(.trailing, 1)
								.accessibilityLabel(key.key.label)
						}
					}
					.frame(height: 14)

					Text((key.key.glyph ?? key.key.label).localizedLowercase)
				}
			}
		}
		.buttonStyle(.keyboardKey(selected: state.toggledKeys.contains(key),
															hasShadow: true,
															halfHeight: halfHeight,
															widthRatio: key.key.widthRatio))
	}

	var arrowsView: any View {
		switch arrowsStyle ?? preferences.keyboardArrowsStyle {
		case .butterfly:
			return HStack(spacing: 2) {
				button(for: .left)
				VStack(spacing: 2) {
					button(for: .up, halfHeight: true)
					button(for: .down, halfHeight: true)
				}
				button(for: .right)
			}

		case .scissor:
			return VStack(alignment: .center, spacing: 1.5) {
				button(for: .up, halfHeight: true)
				HStack(spacing: 1.5) {
					button(for: .left, halfHeight: true)
					button(for: .down, halfHeight: true)
					button(for: .right, halfHeight: true)
				}
			}

		case .classic:
			return HStack(spacing: 5) {
				button(for: .up)
				button(for: .down)
				button(for: .left)
				button(for: .right)
			}

		case .vim:
			return HStack(spacing: 5) {
				button(for: .left)
				button(for: .down)
				button(for: .up)
				button(for: .right)
			}

		case .vimInverted:
			return HStack(spacing: 5) {
				button(for: .left)
				button(for: .up)
				button(for: .down)
				button(for: .right)
			}
		}
	}
}

struct KeyboardToolbarView: View {
	weak var delegate: KeyboardToolbarViewDelegate?

	let toolbars: [Toolbar]

	@State private var outerSize = CGSize.zero

	@EnvironmentObject var state: KeyboardToolbarViewState

	@ObservedObject private var preferences = Preferences.shared

	private func isToolbarVisible(_ toolbar: Toolbar) -> Bool {
		switch toolbar {
		case .primary, .padPrimaryLeading, .padPrimaryTrailing:
			return true
		case .secondary:
			return state.toggledKeys.contains(.more)
		case .fnKeys:
			return state.toggledKeys.contains(.fnKeys)
		}
	}

	var body: some View {
		ZStack(alignment: .bottom) {
			Color.black
				.frame(height: 0)
				.captureSize(in: $outerSize)

			VStack(spacing: 0) {
				ForEach(toolbars, id: \.self) { toolbar in
					if isToolbarVisible(toolbar) {
						let view = KeyboardToolbarKeyStack(delegate: delegate,
																							 toolbar: toolbar)
							.padding(.horizontal, 4)
							.padding(.top, 5)

						switch toolbar {
						case .primary, .padPrimaryLeading, .padPrimaryTrailing, .secondary:
							AnyView(view)
								.frame(width: outerSize.width)

						case .fnKeys:
							AnyView(
								CocoaScrollView(.horizontal, showsIndicators: false) {
									view
								}
									.frame(width: outerSize.width)
							)
						}
					}
				}
			}
		}
	}
}

struct KeyboardToolbarView_Previews: PreviewProvider {
	@State private static var state = KeyboardToolbarViewState()

	static var previews: some View {
		ForEach(ColorScheme.allCases, id: \.self) { scheme in
			VStack {
				Spacer()
				KeyboardToolbarView(toolbars: [.fnKeys, .secondary, .primary])
					.environmentObject(state)
					.padding(.bottom, 4)
					.background(BlurEffectView(style: .systemChromeMaterial))
					.preferredColorScheme(scheme)
					.previewLayout(.sizeThatFits)
			}
				.previewDisplayName("\(scheme)")
				.previewLayout(.fixed(width: 414, height: 100))
		}

		VStack() {
			Spacer()
			HStack {
				KeyboardToolbarKeyStack(toolbar: .padPrimaryLeading)
					.environmentObject(state)
				Spacer()
				KeyboardToolbarKeyStack(toolbar: .padPrimaryTrailing)
					.environmentObject(state)
			}
				.previewLayout(.sizeThatFits)
		}
			.previewDisplayName("iPad Toolbar")
			.previewLayout(.fixed(width: 600, height: 100))
	}
}
