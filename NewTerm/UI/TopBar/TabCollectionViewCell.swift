//
//  TabCollectionViewCell.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import Foundation

class TabCollectionViewCell: UICollectionViewCell {

	static let reuseIdentifier = "TabCell"

	let textLabel = UILabel()
	let closeButton = UIButton()

	override init(frame: CGRect) {
		super.init(frame: frame)

		selectedBackgroundView = UIView()
		selectedBackgroundView!.backgroundColor = UIColor(white: 85 / 255, alpha: 0.7)

		textLabel.translatesAutoresizingMaskIntoConstraints = false
		textLabel.font = UIFont.systemFont(ofSize: 16)
		textLabel.textColor = .white
		textLabel.backgroundColor = .clear
		contentView.addSubview(textLabel)

		closeButton.translatesAutoresizingMaskIntoConstraints = false
		closeButton.accessibilityLabel = NSLocalizedString("CLOSE_TAB", comment: "VoiceOver label for the close tab button.")
		closeButton.titleLabel!.font = UIFont.systemFont(ofSize: 16)
		closeButton.setTitle("×", for: .normal)
		contentView.addSubview(closeButton)

		contentView.addCompactConstraints([
			"textLabel.centerY = contentView.centerY",
			"textLabel.left = contentView.left + 6",
			"closeButton.width = 24",
			"closeButton.height = contentView.height",
			"closeButton.left = textLabel.right",
			"closeButton.right = contentView.right"
		], metrics: nil, views: [
			"contentView": contentView,
			"textLabel": textLabel,
			"closeButton": closeButton
		])
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.height = isSmallDevice ? 32 : 40
		return size
	}

}
