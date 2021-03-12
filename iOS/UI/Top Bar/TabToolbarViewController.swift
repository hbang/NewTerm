//
//  TabToolbarViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

protocol TabToolbarDataSource: AnyObject {
	func numberOfTerminals() -> Int
	func selectedTerminalIndex() -> Int
	func terminalName(at index: Int) -> String
}

protocol TabToolbarDelegate: AnyObject {
	func addTerminal()
	func selectTerminal(at index: Int)
	func removeTerminal(at index: Int)

	func openSettings()
	func openPasswordManager()
}

class TabToolbarViewController: UIViewController {

	weak var dataSource: TabToolbarDataSource?
	weak var delegate: TabToolbarDelegate?

	private var backdropView: UIToolbar!
	private var titleLabel: UILabel!
	private var settingsButton: UIButton!
	private var passwordButton: UIButton!

	private(set) var tabsCollectionView: UICollectionView!
	private(set) var addButton: UIButton!

	var topMargin: CGFloat = 0

	private var maximumTabsToFit = 0
	private var previousWidth: CGFloat = 0

	override func viewDidLoad() {
		super.viewDidLoad()

		let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)

		let gearImage: UIImage?
		let passwordImage: UIImage?
		let plusImage: UIImage?
		if #available(iOS 13, *) {
			let configuration = UIImage.SymbolConfiguration(pointSize: titleFont.pointSize * 0.9, weight: .medium)
			gearImage = UIImage(systemName: "gear", withConfiguration: configuration)
			passwordImage = UIImage(systemName: "key.fill", withConfiguration: configuration)
			plusImage = UIImage(systemName: "plus", withConfiguration: configuration)
		} else {
			gearImage = UIImage(named: "key-settings")
			passwordImage = UIImage()
			plusImage = UIImage(named: "add-small")
		}

		backdropView = UIToolbar()
		backdropView.frame = view.bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		backdropView.delegate = self
		view.addSubview(backdropView)

		let leftSpacer = UIView()
		let rightSpacer = UIView()

		titleLabel = UILabel()
		titleLabel.font = titleFont
		titleLabel.text = "Terminal"
		titleLabel.textAlignment = .center
		if #available(iOS 13, *) {
			titleLabel.textColor = .label
		} else {
			titleLabel.textColor = .white
		}

		passwordButton = UIButton(type: .system)
		passwordButton.setImage(passwordImage, for: .normal)
		passwordButton.accessibilityLabel = NSLocalizedString("NEW_TAB", comment: "VoiceOver label for the new tab button.")
		passwordButton.contentMode = .center
		passwordButton.addTarget(self, action: #selector(self.openPasswordManager), for: .touchUpInside)

		settingsButton = UIButton(type: .system)
		settingsButton.setImage(gearImage, for: .normal)
		settingsButton.accessibilityLabel = NSLocalizedString("NEW_TAB", comment: "VoiceOver label for the new tab button.")
		settingsButton.contentMode = .center
		settingsButton.addTarget(self, action: #selector(self.openSettings), for: .touchUpInside)

		addButton = UIButton(type: .system)
		addButton.setImage(plusImage, for: .normal)
		addButton.accessibilityLabel = NSLocalizedString("NEW_TAB", comment: "VoiceOver label for the new tab button.")
		addButton.contentMode = .center
		addButton.addTarget(self, action: #selector(self.addTerminal), for: .touchUpInside)

		let topStackView = UIStackView(arrangedSubviews: [ leftSpacer, titleLabel, passwordButton, settingsButton, addButton, rightSpacer ])
		topStackView.spacing = 6

		let collectionViewLayout = UICollectionViewFlowLayout()
		collectionViewLayout.scrollDirection = .horizontal
		collectionViewLayout.minimumInteritemSpacing = 0
		collectionViewLayout.minimumLineSpacing = 0

		tabsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
		tabsCollectionView.translatesAutoresizingMaskIntoConstraints = false
		tabsCollectionView.backgroundColor = nil
		tabsCollectionView.showsVerticalScrollIndicator = false
		tabsCollectionView.showsHorizontalScrollIndicator = false
		tabsCollectionView.allowsMultipleSelection = false
		tabsCollectionView.dataSource = self
		tabsCollectionView.delegate = self
		tabsCollectionView.register(TabCollectionViewCell.self, forCellWithReuseIdentifier: TabCollectionViewCell.reuseIdentifier)

		let mainStackView = UIStackView(arrangedSubviews: [ topStackView, tabsCollectionView ])
		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.spacing = 2
		mainStackView.axis = .vertical
		view.addSubview(mainStackView)

		let layoutGuide: LayoutGuide
		let statusBarMargin: CGFloat
		if #available(iOS 11, *) {
			layoutGuide = view.safeAreaLayoutGuide
			statusBarMargin = 0
		} else {
			layoutGuide = view
			statusBarMargin = UIApplication.shared.statusBarFrame.size.height
		}

		NSLayoutConstraint.activate([
			mainStackView.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: statusBarMargin),
			mainStackView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor),
			mainStackView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
			mainStackView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),

			topStackView.heightAnchor.constraint(equalToConstant: 32),
			tabsCollectionView.heightAnchor.constraint(equalToConstant: 32),

			leftSpacer.widthAnchor.constraint(equalTo: leftSpacer.heightAnchor, multiplier: 3, constant: 6 * 3),
			rightSpacer.widthAnchor.constraint(equalToConstant: 0),
			passwordButton.widthAnchor.constraint(equalTo: passwordButton.heightAnchor),
			settingsButton.widthAnchor.constraint(equalTo: settingsButton.heightAnchor),
			addButton.widthAnchor.constraint(equalTo: addButton.heightAnchor),
		])
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		if previousWidth != view.frame.size.width {
			previousWidth = view.frame.size.width

//			let layout = tabsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
//			layout.width
		}
	}

	@objc private func addTerminal() {
		delegate?.addTerminal()
	}

	@objc private func openSettings() {
		delegate?.openSettings()
	}

	@objc private func openPasswordManager() {
		delegate?.openPasswordManager()
	}

	@objc private func removeTerminalButtonTapped(_ button: UIButton) {
		delegate?.removeTerminal(at: button.tag)
	}

	func didSelectTab(at index: Int) {
		// If this is what’s already selected, just select it again and return
		let selectedTabIndex = dataSource!.selectedTerminalIndex()
		if index == selectedTabIndex {
			tabsCollectionView.selectItem(at: IndexPath(item: selectedTabIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
		}

		let oldSelectedTabIndex = selectedTabIndex < dataSource!.numberOfTerminals() ? selectedTabIndex : nil

		tabsCollectionView.performBatchUpdates({
			if oldSelectedTabIndex != nil {
				self.tabsCollectionView.deselectItem(at: IndexPath(item: oldSelectedTabIndex!, section: 0), animated: false)
			}

			self.tabsCollectionView.selectItem(at: IndexPath(item: selectedTabIndex, section: 0),
																				 animated: true,
																				 scrollPosition: .centeredHorizontally)
		}, completion: { _ in
			// TODO: Hack because the previous tab doesn’t deselect for some reason and ugh I hate this
			self.tabsCollectionView.reloadData()
		})
	}

	func didAddTab(at index: Int) {
		tabsCollectionView.reloadData()
		tabsCollectionView.layoutIfNeeded()
	}

	func didRemoveTab(at index: Int) {
		tabsCollectionView.reloadData()
		tabsCollectionView.layoutIfNeeded()
	}

}

extension TabToolbarViewController: UIToolbarDelegate {

	func position(for bar: UIBarPositioning) -> UIBarPosition {
		// Helps UIToolbar figure out where to place the shadow line
		return .top
	}

}

extension TabToolbarViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return dataSource?.numberOfTerminals() ?? 0
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabCollectionViewCell.reuseIdentifier, for: indexPath) as! TabCollectionViewCell
		cell.textLabel.text = dataSource?.terminalName(at: indexPath.item)
		cell.isSelected = dataSource?.selectedTerminalIndex() == indexPath.item
		cell.closeButton.tag = indexPath.item
		cell.closeButton.addTarget(self, action: #selector(self.removeTerminalButtonTapped(_:)), for: .touchUpInside)
		cell.isLastItem = indexPath.row == (dataSource?.numberOfTerminals() ?? 0) - 1
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: 94, height: tabsCollectionView.frame.size.height)
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		delegate?.selectTerminal(at: indexPath.item)
	}

}
