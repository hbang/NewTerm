//
//  HUDView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 25/12/2022.
//

import SwiftUI
import SwiftUIX

class HUDViewState: ObservableObject {
	@Published var isVisible = false
}

struct HUDView: View {
	@EnvironmentObject private var state: HUDViewState

	var body: some View {
		VisualEffectBlurView(blurStyle: .systemMaterial,
												 vibrancyStyle: .label) {
			Image(systemName: .bell)
				.font(.system(size: 25, weight: .medium))
				.imageScale(.large)
				.foregroundColor(.label)
		}
			.frame(width: 54, height: 54)
			.cornerRadius(16, style: .continuous)
			.visible(state.isVisible, animation: state.isVisible ? nil : .linear(duration: 0.3))
			.onChange(of: state.isVisible) { isVisible in
				if isVisible {
					Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { _ in
						self.state.isVisible = false
					}
				}
			}
	}
}

struct HUDView_Previews: PreviewProvider {
	private static var state = HUDViewState()

	static var previews: some View {
		HUDView()
			.environmentObject(state)
			.onAppear {
				Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
					self.state.isVisible = true
				}
			}
	}
}
