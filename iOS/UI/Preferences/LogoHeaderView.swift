//
//  LogoHeaderView.swift
//  NewTerm
//
//  Created by Adam Demasi on 19/4/20.
//  Copyright © 2020 HASHBANG Productions. All rights reserved.
//

@objc(LogoHeaderView)
class LogoHeaderView: UIView {

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
		if #available(iOS 13, *) {
			let fontDescriptor = nameFont.fontDescriptor.withDesign(.rounded)!
			nameLabel.font = UIFont(descriptor: fontDescriptor, size: 40)
		} else {
			nameLabel.font = nameFont
		}
		nameLabel.textColor = .logoName
		nameLabel.text = "NewTerm"

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

		let topSuperOffset: CGFloat = 10000

		NSLayoutConstraint.activate([
			containerView.topAnchor.constraint(equalTo: self.topAnchor, constant: -topSuperOffset),
			containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -35),
			containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),

			stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topSuperOffset),
			stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -35),
			stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
			stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),

			leftSpacer.widthAnchor.constraint(equalTo: rightSpacer.widthAnchor),

			iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor),

			blockView.widthAnchor.constraint(equalTo: blockView.heightAnchor, multiplier: 0.5)
		])

		blockBlinkTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
			blockView.alpha = blockView.alpha == 1 ? 0 : 1
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		blockBlinkTimer?.invalidate()
	}

}
