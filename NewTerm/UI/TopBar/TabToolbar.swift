//
//  TabToolbar.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class TabToolbar: UIView {

	let backdropView = UIToolbar()

	var tabsCollectionView: UICollectionView!
	var addButton: UIButton!

	var topMargin = CGFloat(0)

	override init(frame: CGRect) {
		super.init(frame: frame)

		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		addSubview(backdropView)

		let collectionViewLayout = UICollectionViewFlowLayout()
		collectionViewLayout.scrollDirection = .horizontal
		collectionViewLayout.minimumInteritemSpacing = 0
		collectionViewLayout.minimumLineSpacing = 0

		// the weird frame is to appease ios 6 UICollectionView
		tabsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
		tabsCollectionView.backgroundColor = nil
		tabsCollectionView.indicatorStyle = .white
		tabsCollectionView.allowsMultipleSelection = false
		addSubview(tabsCollectionView)

		tabsCollectionView.register(TabCollectionViewCell.self, forCellWithReuseIdentifier: TabCollectionViewCell.reuseIdentifier)

		addButton = UIButton(type: .system)
		addButton.titleLabel!.font = UIFont.systemFont(ofSize: 18)
		addButton.setTitle("＋", for: .normal)
		addButton.accessibilityLabel = NSLocalizedString("NEW_TAB", comment: "VoiceOver label for the new tab button.")
		addSubview(addButton)

		let shadowHeight = CGFloat(1) / UIScreen.main.scale

		let shadowView = UIView(frame: CGRect(x: 0, y: frame.size.height - shadowHeight, width: frame.size.width, height: shadowHeight))
		shadowView.autoresizingMask = [ .flexibleWidth, .flexibleTopMargin ]
		shadowView.backgroundColor = UIColor(white: 64 / 255, alpha: 1)
		addSubview(shadowView)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let addButtonWidth = CGFloat(44)

		addButton.frame = CGRect(x: frame.size.width - addButtonWidth, y: topMargin, width: addButtonWidth, height: frame.size.height - topMargin)
		tabsCollectionView.frame = CGRect(x: 0, y: topMargin, width: addButton.frame.origin.x, height: addButton.frame.size.height)

		let newButtonSize = CGFloat(addButton.frame.size.height < 40 ? 18 : 24)

		if (addButton.titleLabel!.font.pointSize != newButtonSize) {
			addButton.titleLabel!.font = UIFont.systemFont(ofSize: newButtonSize)
		}
	}

}
