//
//  KeyboardToolbarInputView.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit
import SwiftUIX

class KeyboardToolbarInputView: UIInputView {

	private var hostingView: UIHostingView<AnyView>!

	init(delegate: KeyboardToolbarViewDelegate?, toolbars: [Toolbar], state: KeyboardToolbarViewState) {
		super.init(frame: .zero, inputViewStyle: .keyboard)

		translatesAutoresizingMaskIntoConstraints = false
		allowsSelfSizing = true

		hostingView = UIHostingView(rootView: AnyView(
			KeyboardToolbarView(delegate: delegate, toolbars: toolbars)
				.environmentObject(state)
		))
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		hostingView.shouldResizeToFitContent = true
		hostingView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
		addSubview(hostingView)

		NSLayoutConstraint.activate([
			hostingView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
			hostingView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
			hostingView.topAnchor.constraint(equalTo: self.topAnchor),
			hostingView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

extension KeyboardToolbarInputView: UIInputViewAudioFeedback {
	var enableInputClicksWhenVisible: Bool {
		// Conforming to <UIInputViewAudioFeedback> allows the buttons to make the click sound
		// when tapped
		true
	}
}
