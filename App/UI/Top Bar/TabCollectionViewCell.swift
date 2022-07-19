//
//  TabCollectionViewCell.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit
import NewTermCommon

class TabCollectionViewCell: UICollectionViewCell {

	static let reuseIdentifier = "TabCell"

	let textLabel = UILabel()
	let closeButton = UIButton()
	let separatorView = UIView()

	var separatorViewWidthConstraint: NSLayoutConstraint!

	var isLastItem: Bool {
		get { return separatorView.isHidden }
		set { separatorView.isHidden = newValue }
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		selectedBackgroundView = UIView()
		selectedBackgroundView!.backgroundColor = .tabSelected

		textLabel.translatesAutoresizingMaskIntoConstraints = false
		textLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
		textLabel.textColor = .label
		textLabel.textAlignment = .center
		contentView.addSubview(textLabel)

		closeButton.translatesAutoresizingMaskIntoConstraints = false
		let configuration = UIImage.SymbolConfiguration(pointSize: textLabel.font.pointSize * 1.12, weight: .unspecified, scale: .unspecified)
		closeButton.setImage(UIImage(systemName: "xmark.square.fill", withConfiguration: configuration), for: .normal)
		closeButton.accessibilityLabel = .localize("CLOSE_TAB", comment: "VoiceOver label for the close tab button.")
		closeButton.contentMode = .center
		closeButton.tintColor = textLabel.textColor
		closeButton.alpha = 0.5
		contentView.addSubview(closeButton)

		separatorView.translatesAutoresizingMaskIntoConstraints = false
		separatorView.backgroundColor = .tabSeparator
		contentView.addSubview(separatorView)

		separatorViewWidthConstraint = separatorView.widthAnchor.constraint(equalToConstant: 1)

		NSLayoutConstraint.activate([
			closeButton.topAnchor.constraint(equalTo: contentView.topAnchor),
			closeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			closeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			closeButton.widthAnchor.constraint(equalToConstant: 32),

			textLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
			textLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			textLabel.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: -2),
			textLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

			separatorView.topAnchor.constraint(equalTo: contentView.topAnchor),
			separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			separatorViewWidthConstraint
		])
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func willMove(toWindow newWindow: UIWindow?) {
		super.willMove(toWindow: newWindow)

		if newWindow != nil {
			separatorViewWidthConstraint.constant = 1 / newWindow!.screen.scale
		}
	}

	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.height = isSmallDevice ? 36 : 44
		return size
	}

}
