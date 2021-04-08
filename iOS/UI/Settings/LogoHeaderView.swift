//
//  LogoHeaderView.swift
//  NewTerm
//
//  Created by Adam Demasi on 19/4/20.
//  Copyright © 2020 HASHBANG Productions. All rights reserved.
//

import UIKit
import SwiftUI

class LogoHeaderView: UIView {

	private var iconWidthConstraint: NSLayoutConstraint!
	private var nameAttributedString: NSAttributedString!

	private var titleTypingTimer: Timer?
	private var blockBlinkTimer: Timer?

	override init(frame: CGRect) {
		super.init(frame: frame)

		let containerView = UIView()
		containerView.translatesAutoresizingMaskIntoConstraints = false
		containerView.backgroundColor = .logoBackground
		addSubview(containerView)

		let iconImageView = UIImageView(image: UIImage(named: "app-icon-big"))
		iconImageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

		let nameLabel = UILabel()
		nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		let nameFont = UIFont.systemFont(ofSize: 40, weight: .semibold)
		let fontDescriptor = nameFont.fontDescriptor.withDesign(.rounded)!
		nameLabel.font = UIFont(descriptor: fontDescriptor, size: 40)
		nameLabel.textColor = .logoName
		nameLabel.text = ""

		let blockView = UIView()
		blockView.backgroundColor = .logoCursor

		let nameStackView = UIStackView(arrangedSubviews: [ nameLabel, blockView ])
		nameStackView.axis = .horizontal
		nameStackView.alignment = .fill
		nameStackView.spacing = 4

		let leftSpacer = UIView()
		let rightSpacer = UIView()

		let stackView = UIStackView(arrangedSubviews: [ leftSpacer, iconImageView, nameStackView, rightSpacer ])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .horizontal
		stackView.alignment = .center
		stackView.spacing = 20
		containerView.addSubview(stackView)

		let titleString = "NewTerm"
		nameAttributedString = NSAttributedString(string: titleString,
																							attributes: [
																								.font: nameLabel.font!
																							])
		iconWidthConstraint = iconImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 0)

		let topSuperOffset: CGFloat = 10000
		let outerMargins: CGFloat = self.hasOuterMargins ? 15 : 0

		NSLayoutConstraint.activate([
			containerView.topAnchor.constraint(equalTo: self.topAnchor, constant: -topSuperOffset),
			containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),

			stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topSuperOffset),
			stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
			stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: outerMargins),
			stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -outerMargins),

			leftSpacer.widthAnchor.constraint(equalTo: rightSpacer.widthAnchor),

			iconWidthConstraint,
			iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

			blockView.widthAnchor.constraint(equalTo: blockView.heightAnchor, multiplier: 0.5)
		])

		Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
			var i = 0

			self.titleTypingTimer = Timer.scheduledTimer(withTimeInterval: 0.225, repeats: true) { timer in
				nameLabel.text! += String(titleString[titleString.index(titleString.startIndex, offsetBy: i)])
				i += 1

				if i == titleString.count {
					timer.invalidate()
				}
			}

			self.blockBlinkTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
				blockView.alpha = blockView.alpha == 1 ? 0 : 1
			}
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let nameFrame = nameAttributedString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
																											options: [],
																											context: nil)
		let nameWidth = abs(nameFrame.origin.x) + nameFrame.size.width.rounded(.up)
		iconWidthConstraint.constant = min(96, frame.size.width - nameWidth - (nameFrame.size.height * 0.5) - 4 - (20 * 3) - (self.hasOuterMargins ? 15 * 2 : 0))
	}

	private var hasOuterMargins: Bool { (window?.screen ?? UIScreen.main).bounds.size.width > 400 }

	deinit {
		titleTypingTimer?.invalidate()
		blockBlinkTimer?.invalidate()
	}

}

struct LogoHeaderViewRepresentable: UIViewRepresentable {
	func makeUIView(context: Context) -> LogoHeaderView {
		LogoHeaderView()
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct LogoHeaderViewRepresentable_Previews: PreviewProvider {
	static var previews: some View {
		ScrollView {
			VStack {
				LogoHeaderViewRepresentable()
					.frame(height: 200)
			}
		}
		.previewDevice("iPod touch (7th generation)")
	}
}
