//
//  KeyboardPopupToolbar.swift
//  NewTerm
//
//  Created by Adam Demasi on 7/7/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class KeyboardPopupToolbar: UIView {

	// TODO: Localise
	let homeKey = KeyboardButton(title: "Home", glyph: "Home")
	let endKey = KeyboardButton(title: "End", glyph: "End")
	let pageUpKey = KeyboardButton(title: "Page Up", glyph: "PgUp")
	let pageDownKey = KeyboardButton(title: "Page Down", glyph: "PgDn")
	let deleteKey = KeyboardButton(title: "Delete Forward", systemImage: "delete.right", systemHighlightedImage: "delete.right.fill")
	let fnKeys: [KeyboardButton]!

	private(set) var buttons: [KeyboardButton]!

	override init(frame: CGRect) {
		fnKeys = Array(1...12).map { i in KeyboardButton(title: "F\(i)") }

		super.init(frame: frame)

		translatesAutoresizingMaskIntoConstraints = false

		let backdropView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		addSubview(backdropView)

		let backdropColorView = UIView()
		backdropColorView.frame = backdropView.contentView.bounds
		backdropColorView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		backdropColorView.backgroundColor = .keyboardToolbarBackground
		backdropView.contentView.addSubview(backdropColorView)

		let buttonSpacing: CGFloat = 6
		let topSpacing: CGFloat = isSmallDevice ? 3 : 4
		let rowSpacing: CGFloat = isSmallDevice ? 1 : 2

		let fnStackView = UIStackView(arrangedSubviews: fnKeys + [ UIView() ])
		fnStackView.translatesAutoresizingMaskIntoConstraints = false
		fnStackView.axis = .horizontal
		fnStackView.spacing = buttonSpacing

		let homeEndSpacerView = UIView()
		let pageUpDownSpacerView = UIView()

		let sortedViews = [
			homeKey, endKey, homeEndSpacerView,
			pageUpKey, pageDownKey, pageUpDownSpacerView,
			deleteKey
		]

		buttons = [
			homeKey, endKey,
			pageUpKey, pageDownKey,
			deleteKey
		] + fnKeys

		let bottomStackView = UIStackView(arrangedSubviews: sortedViews)
		bottomStackView.translatesAutoresizingMaskIntoConstraints = false
		bottomStackView.axis = .horizontal
		bottomStackView.spacing = buttonSpacing

		let scrollViews = [ fnStackView, bottomStackView ].map { stackView -> UIScrollView in
			let scrollView = UIScrollView()
			scrollView.translatesAutoresizingMaskIntoConstraints = false
			scrollView.showsHorizontalScrollIndicator = false
			scrollView.showsVerticalScrollIndicator = false
			scrollView.addSubview(stackView)

			NSLayoutConstraint.activate([
				stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: topSpacing),
				stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -rowSpacing),
				stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 3),
				stackView.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.trailingAnchor, constant: -3),
				stackView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor, constant: -6),
				stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -topSpacing - rowSpacing)
			])

			return scrollView
		}

		let stackView = UIStackView(arrangedSubviews: scrollViews)
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .vertical
		stackView.spacing = 0
		addSubview(stackView)

		NSLayoutConstraint.activate([
			self.heightAnchor.constraint(equalToConstant: isSmallDevice ? 72 : 88),

			stackView.topAnchor.constraint(equalTo: self.topAnchor),
			stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

			homeEndSpacerView.widthAnchor.constraint(equalToConstant: 0),
			pageUpDownSpacerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),

			endKey.widthAnchor.constraint(equalTo: homeKey.widthAnchor),
			pageUpKey.widthAnchor.constraint(equalTo: homeKey.widthAnchor),
			pageDownKey.widthAnchor.constraint(equalTo: homeKey.widthAnchor),
			deleteKey.widthAnchor.constraint(equalTo: deleteKey.heightAnchor)
		])

		// Size the scroll views and F# keys to match each other.
		NSLayoutConstraint.activate(
			scrollViews.map { view in view.heightAnchor.constraint(equalTo: scrollViews.first!.heightAnchor) } +
			fnKeys.map { view in view.widthAnchor.constraint(equalTo: fnKeys.first!.widthAnchor) }
		)

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
		preferencesUpdated()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc func preferencesUpdated() {
		let preferences = Preferences.shared
		let style = preferences.keyboardAccessoryStyle

		for button in buttons {
			button.style = style
		}
	}

	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.height = isSmallDevice ? 37 : 45
		return size
	}

}

extension KeyboardPopupToolbar: UIToolbarDelegate {

	func position(for bar: UIBarPositioning) -> UIBarPosition {
		// Helps UIToolbar figure out where to place the shadow line
		return .bottom
	}

}

extension KeyboardPopupToolbar: UIInputViewAudioFeedback {

	var enableInputClicksWhenVisible: Bool {
		// Conforming to <UIInputViewAudioFeedback> allows the buttons to make the click sound when tapped
		return true
	}

}
