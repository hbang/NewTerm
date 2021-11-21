//
//  KeyboardPopupToolbarView.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 11/21/21.
//

import SwiftUI
import NewTermCommon

struct KeyboardPopupToolbarView: View {
	
	struct KeyType {
		enum function: Int, Equatable, CaseIterable {
			case f1
			case f2
			case f3
			case f4
			case f5
			case f6
			case f7
			case f8
			case f9
			case f10
			case f11
			case f12
			
			var text: String {
				return "F\(self.rawValue)"
			}
		}
		
		enum leading: Int, CaseIterable {
			case home
			case end
			
			var text: String {
				switch self {
				case .home:
					return "Home"
				case .end:
					return "End"
				}
			}
		}
		
		enum paging: Int, CaseIterable {
			case pgUp
			case pgDn
			
			var text: String {
				switch self {
				case .pgUp:
					return "PgUp"
				case .pgDn:
					return "PgDn"
				}
			}
		}
		
		enum trailing: Int, CaseIterable {
			case frwdDel
			
			var imageName: String {
				switch self {
				case .frwdDel:
					return "delete.forward"
				}
			}
			
		}
	}

	var functionButtonGroup: some View {
		HStack(alignment: .center, spacing: 5) {
			ForEach(KeyType.function.allCases, id: \.self) { button in
				Button {
					switch button {
					case .f1:
						break
					case .f2:
						break
					case .f3:
						break
					case .f4:
						break
					case .f5:
						break
					case .f6:
						break
					case .f7:
						break
					case .f8:
						break
					case .f9:
						break
					case .f10:
						break
					case .f11:
						break
					case .f12:
						break
					}
				} label: {
					Text("\(button.text)")
				}
				.buttonStyle(
					.keyboardKey(fixedWidth: 35)
				)
			}
		}
	}
	
	var leadingButtonGroup: some View {
		HStack(alignment: .center, spacing: 5) {
			// 1: home; 2: end
			ForEach(KeyType.leading.allCases, id: \.self) { button in
				Button {
					switch button {
					case .home:
						break
					case .end:
						break
					}
				} label: {
					Text(button.text)
				}
				.buttonStyle(
					.keyboardKey(fixedWidth: 50)
				)
			}
		}
	}
	
	var pagingButtonGroup: some View {
		HStack(alignment: .center, spacing: 5) {
			ForEach(KeyType.paging.allCases, id: \.self) { button in
				Button {
					switch button {
					case .pgUp:
						break
					case .pgDn:
						break
					}
				} label: {
					Text(button.text)
				}
				.buttonStyle(
					.keyboardKey(fixedWidth: 50)
				)
			}
		}
	}
	
	var trailingButtonGroup: some View {
		HStack(alignment: .center, spacing: 5) {
			ForEach(KeyType.trailing.allCases, id: \.self) { button in
				Button {
					switch button {
					case .frwdDel:
						break
					}
				} label: {
					Image(systemName: button.imageName)
				}
				.buttonStyle(.keyboardKey())
			}
		}
	}
	
	var body: some View {
		VStack(spacing: 5) {
			ScrollView(.horizontal, showsIndicators: false) {
				functionButtonGroup
					.padding(.horizontal, 5)
			}
			HStack(alignment: .center, spacing: 10) {
				leadingButtonGroup
				pagingButtonGroup
				Spacer()
				trailingButtonGroup
			}
			.padding(.horizontal, 5)
		}
		.frame(maxWidth: .infinity, maxHeight: isBigDevice ? 96 : 80)
		.background(Color(.keyboardToolbarBackground))
	}
	
}

struct KeyboardPopupToolbarView_Previews: PreviewProvider {
	static var previews: some View {
		ForEach(ColorScheme.allCases, id: \.self) { scheme in
			KeyboardPopupToolbarView()
				.preferredColorScheme(scheme)
				.previewLayout(.sizeThatFits)
		}
	}
}
