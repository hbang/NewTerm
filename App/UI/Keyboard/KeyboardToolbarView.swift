//
//  KeyboardToolbarView.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 11/21/21.
//

import SwiftUI
import NewTermCommon
import SwiftUIX

struct Key {
	var label: String
	var glyph: String?
	var imageName: SFSymbolName?
	var preferredStyle: KeyboardButtonStyle?
	var isToggle = false
	var halfHeight = false
	var widthRatio: CGFloat?
}

enum Toolbar: CaseIterable {
	case primary, secondary, fnKeys

	var keys: [ToolbarKey] {
		switch self {
		case .primary:
			return [
				.control, .escape, .tab, .more,
				.variableSpace,
				.arrows
			]

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
			// TODO:
			return Array(1...12).map { i in .fnKey }
		}
	}
}

enum ToolbarKey: Int, CaseIterable {
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
	case fnKey

	var key: Key {
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
		case .fnKey: //(index: let index):
			let index = 1
			return Key(label: "F\(index + 1)", preferredStyle: .text, widthRatio: 1.25)
		}
	}
}

struct KeyboardToolbarView: View {

	let toolbars: [Toolbar] = [.fnKeys, .secondary, .primary]
	
	@State var toggledKeys = Set<ToolbarKey>()

	@State var outerSize = CGSize.zero
	
	@ObservedObject var preferences = Preferences.shared

	private func isToolbarVisible(_ toolbar: Toolbar) -> Bool {
		switch toolbar {
		case .primary:   return true
		case .secondary: return toggledKeys.contains(.more)
		case .fnKeys:    return toggledKeys.contains(.fnKeys)
		}
	}

	private func toolbarView(for toolbar: Toolbar) -> some View {
		let view = HStack(alignment: .center, spacing: 5) {
			ForEach(toolbar.keys, id: \.self) { key in
				switch key {
				case .fixedSpace:
					EmptyView()

				case .variableSpace:
					Spacer(minLength: 0)

				case .arrows:
					arrowsView

				default:
					button(for: key)
				}
			}
		}
			.padding(.horizontal, 4)
			.padding(.top, 5)

		switch toolbar {
		case .primary, .secondary:
			return AnyView(
				view
					.frame(width: outerSize.width)
			)

		case .fnKeys:
			return AnyView(
				CocoaScrollView(.horizontal, showsIndicators: false) {
					view
				}
					.frame(width: outerSize.width)
			)
		}
	}

	func button(for key: ToolbarKey, halfHeight: Bool = false) -> some View {
		Button {
			UIDevice.current.playInputClick()
			if key.key.isToggle {
				if toggledKeys.contains(key) {
					toggledKeys.remove(key)
				} else {
					toggledKeys.insert(key)
				}
			}
		} label: {
			switch key {
			case .up, .down, .left, .right:
				Image(systemName: key.key.imageName!)
					.frame(width: 14, height: 14, alignment: .center)
					.accessibilityLabel(key.key.label)

			default:
//				HStack(alignment: .center, spacing: 0) {
//					Spacer(minLength: 0)
					VStack(alignment: .trailing, spacing: 3) {
						HStack(spacing: 0) {
							if let imageName = key.key.imageName,
								 key.key.preferredStyle != .text {
								Image(systemName: imageName)
									.frame(width: 14, height: 14, alignment: .center)
									.padding(.trailing, 1.5)
									.accessibilityLabel(key.key.label)
							}
						}
						.frame(height: 16)

						Text((key.key.glyph ?? key.key.label).localizedLowercase)
					}
//				}
			}
		}
		.buttonStyle(.keyboardKey(selected: toggledKeys.contains(key),
															hasShadow: true,
															halfHeight: halfHeight,
															widthRatio: key.key.widthRatio))
	}

	var arrowsView: some View {
		// “Scissor”
//		VStack(alignment: .center, spacing: 1.5) {
//			button(for: .up, halfHeight: true)
//			HStack(spacing: 1.5) {
//				button(for: .left, halfHeight: true)
//				button(for: .down, halfHeight: true)
//				button(for: .right, halfHeight: true)
//			}
//		}

		// “Butterfly”
		HStack(spacing: 2) {
			button(for: .left)
			VStack(spacing: 2) {
				button(for: .up, halfHeight: true)
				button(for: .down, halfHeight: true)
			}
			button(for: .right)
		}
	}

	var body: some View {
		ZStack(alignment: .bottom) {
			Color.systemIndigo
				.frame(height: 0)
				.captureSize(in: $outerSize)

			VStack(spacing: 0) {
				ForEach(toolbars, id: \.self) { toolbar in
					if isToolbarVisible(toolbar) {
						toolbarView(for: toolbar)
					}
				}
			}
		}
	}
}

struct KeyboardToolbarView_Previews: PreviewProvider {
	static var previews: some View {
		ForEach(ColorScheme.allCases, id: \.self) { scheme in
			VStack{
				Spacer()
				KeyboardToolbarView()
					.preferredColorScheme(scheme)
					.previewLayout(.sizeThatFits)
			}
		}
	}
}
