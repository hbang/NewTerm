//
//  KeyboardToolbarView.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 11/21/21.
//

import SwiftUI
import NewTermCommon

struct KeyboardToolbarView: View {
	
	struct KeyType {
		enum leading: Int, CaseIterable {
			case control
			case escape
			case tab
			case more
			
			var text: String {
				switch self {
				case .control:
					return "Ctrl"
				case .escape:
					return "Esc"
				case .tab:
					return "Tab"
				case .more:
					return "More"
				}
			}
			
			var imageName: String {
				switch self {
				case .control:
					return "control"
				case .escape:
					return "escape"
				case .tab:
					return "arrow.right.to.line"
				case .more:
					return "ellipsis"
				}
			}
		}
		
		enum trailing: Int, CaseIterable {
			case up
			case down
			case left
			case right
			
			var imageName: String {
				switch self {
				case .up:
					return "arrow.up"
				case .down:
					return "arrow.down"
				case .left:
					return "arrow.left"
				case .right:
					return "arrow.right"
				}
			}
		}
	}
	
	@State var ctrlKeySelected = false
	@State var moreKeySelected = false
	
	@ObservedObject var preferences = Preferences.shared
	
	var leadingButtonGroup: some View {
		HStack(alignment: .center, spacing: 5) {
			ForEach(KeyType.leading.allCases, id: \.self) { button in
				Button {
					switch button {
					case .control:
						ctrlKeySelected.toggle()
					case .escape:
						break
					case .tab:
						break
					case .more:
						moreKeySelected.toggle()
					}
				} label: {
					switch preferences.keyboardAccessoryStyle {
					case .icons:
						Image(systemName: button.imageName)
					case .text:
						Text(button.text)
					}
				}
				.buttonStyle(
					button == .control ? .keyboardKey(selected: ctrlKeySelected) : button == .more ? .keyboardKey(selected: moreKeySelected) : .keyboardKey()
				)
			}
		}
	}
	
	var trailingButtonGroup: some View {
		HStack(alignment: .center, spacing: 5) {
			ForEach(KeyType.trailing.allCases, id: \.self) { button in
				Button {
					switch button {
					case .up:
						break
					case .down:
						break
					case .left:
						break
					case .right:
						break
					}
				} label: {
					Image(systemName: button.imageName)
				}
				.buttonStyle(
					.keyboardKey(fixedWidth: 30)
				)
			}
		}
	}
	
	var body: some View {
		VStack(spacing: 0) {
			if moreKeySelected {
				KeyboardPopupToolbarView()
			}
			HStack(alignment: .center, spacing: 5) {
				leadingButtonGroup
				Spacer()
				trailingButtonGroup
			}
			.padding(.horizontal, 5)
			.frame(maxWidth: .infinity, maxHeight: isBigDevice ? 48 : 40)
			.background(Color(.keyboardToolbarBackground))
		}
	}
}

struct KeyboardToolbarView_Previews: PreviewProvider {
	static var previews: some View {
		ForEach(ColorScheme.allCases, id: \.self) { scheme in
			VStack{
				Spacer()
				KeyboardToolbarView()
				//					.padding()
					.preferredColorScheme(scheme)
					.previewLayout(.sizeThatFits)
			}
		}
	}
}
