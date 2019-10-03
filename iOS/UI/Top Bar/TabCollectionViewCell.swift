//
//  TabCollectionViewCell.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import Foundation
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
		selectedBackgroundView!.backgroundColor = UIColor(white: 1, alpha: 69 / 255)

		textLabel.translatesAutoresizingMaskIntoConstraints = false
		textLabel.font = UIFont.systemFont(ofSize: 16)
		textLabel.textColor = .white
		textLabel.textAlignment = .center
		contentView.addSubview(textLabel)

		closeButton.translatesAutoresizingMaskIntoConstraints = false
		closeButton.accessibilityLabel = NSLocalizedString("CLOSE_TAB", comment: "VoiceOver label for the close tab button.")
		closeButton.setImage(#imageLiteral(resourceName: "cross").withRenderingMode(.alwaysTemplate), for: .normal)
		closeButton.contentMode = .center
		closeButton.tintColor = .white
		closeButton.alpha = 0.5
		contentView.addSubview(closeButton)

		separatorView.translatesAutoresizingMaskIntoConstraints = false
		separatorView.backgroundColor = UIColor(white: 85 / 255, alpha: 0.4)
		contentView.addSubview(separatorView)

		contentView.addCompactConstraints([
			"textLabel.centerY = contentView.centerY",
			"textLabel.left = contentView.left + 6",
			"closeButton.width = 30",
			"closeButton.height = contentView.height",
			"closeButton.left = textLabel.right",
			"closeButton.right = contentView.right",
			"separatorView.top = contentView.top",
			"separatorView.bottom = contentView.bottom",
			"separatorView.right = contentView.right"
		], metrics: nil, views: [
			"contentView": contentView,
			"textLabel": textLabel,
			"closeButton": closeButton,
			"separatorView": separatorView
		])

		separatorViewWidthConstraint = separatorView.widthAnchor.constraint(equalToConstant: 1)
		separatorViewWidthConstraint.isActive = true
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
