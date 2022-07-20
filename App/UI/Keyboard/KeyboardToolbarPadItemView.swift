//
//  KeyboardToolbarPadItemView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 19/7/2022.
//

import UIKit
import SwiftUIX

class KeyboardToolbarPadItemView: UIView {

	private var hostingView: UIHostingView<KeyboardToolbarKeyStack>!

	init(delegate: KeyboardToolbarViewDelegate?, toolbar: Toolbar, toggledKeys: Binding<Set<ToolbarKey>>) {
		super.init(frame: .zero)

		translatesAutoresizingMaskIntoConstraints = false
		setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
		setContentHuggingPriority(.fittingSizeLevel, for: .vertical)

		hostingView = UIHostingView(rootView: KeyboardToolbarKeyStack(delegate: delegate,
																																	toolbar: toolbar,
																																	toggledKeys: toggledKeys))
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		hostingView.shouldResizeToFitContent = true
		hostingView.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
		hostingView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
		addSubview(hostingView)

		NSLayoutConstraint.activate([
			hostingView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			hostingView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			hostingView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor),
			hostingView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor),
			hostingView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

extension KeyboardToolbarPadItemView: UIInputViewAudioFeedback {
	var enableInputClicksWhenVisible: Bool {
		// Conforming to <UIInputViewAudioFeedback> allows the buttons to make the click sound
		// when tapped
		true
	}
}
