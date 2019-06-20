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
		backdropView.delegate = self
		addSubview(backdropView)

		let collectionViewLayout = UICollectionViewFlowLayout()
		collectionViewLayout.scrollDirection = .horizontal
		collectionViewLayout.minimumInteritemSpacing = 0
		collectionViewLayout.minimumLineSpacing = 0

		tabsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
		tabsCollectionView.backgroundColor = nil
		tabsCollectionView.indicatorStyle = .white
		tabsCollectionView.allowsMultipleSelection = false
		addSubview(tabsCollectionView)

		tabsCollectionView.register(TabCollectionViewCell.self, forCellWithReuseIdentifier: TabCollectionViewCell.reuseIdentifier)

		addButton = UIButton(type: .system)
		addButton.setImage(isSmallDevice ? #imageLiteral(resourceName: "add-small") : #imageLiteral(resourceName: "add"), for: .normal)
		addButton.accessibilityLabel = NSLocalizedString("NEW_TAB", comment: "VoiceOver label for the new tab button.")
		addButton.contentMode = .center
		addSubview(addButton)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let addButtonWidth = CGFloat(44)

		addButton.frame = CGRect(x: frame.size.width - addButtonWidth, y: topMargin, width: addButtonWidth, height: frame.size.height - topMargin)
		tabsCollectionView.frame = CGRect(x: 0, y: topMargin, width: addButton.frame.origin.x, height: addButton.frame.size.height)
	}

}

extension TabToolbar: UIToolbarDelegate {

	func position(for bar: UIBarPositioning) -> UIBarPosition {
		// helps UIToolbar figure out where to place the shadow line
		return .top
	}

}
