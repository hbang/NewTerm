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
	private var mainStackView: UIStackView!
	private var topStackView: UIStackView!
	private var leftSpacer: UIView!
	private var titleLabel: UILabel!

	private var tabsCollectionView: UICollectionView!

	var topMargin: CGFloat = 0
	private var previousWidth: CGFloat = 0

	override func viewDidLoad() {
		super.viewDidLoad()

		let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)

		let configuration = UIImage.SymbolConfiguration(pointSize: titleFont.pointSize * 0.9, weight: .medium)
		let gearImage = UIImage(systemName: "gear", withConfiguration: configuration)
		let plusImage = UIImage(systemName: "plus", withConfiguration: configuration)

		let passwordImage: UIImage?
		if #available(iOS 14, *) {
			passwordImage = UIImage(systemName: "key.fill", withConfiguration: configuration)
		} else {
			passwordImage = UIImage(named: "key.fill", in: nil, with: configuration)
		}

		backdropView = UIToolbar()
		backdropView.frame = view.bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		backdropView.delegate = self
		view.addSubview(backdropView)

		leftSpacer = UIView()
		let rightSpacer = UIView()

		titleLabel = UILabel()
		titleLabel.font = titleFont
		titleLabel.text = NSLocalizedString("TERMINAL", comment: "Generic title displayed before the terminal sets a proper title.")
		titleLabel.textAlignment = .center
		titleLabel.textColor = .label

		let passwordButton = UIButton(type: .system)
		passwordButton.setImage(passwordImage, for: .normal)
		passwordButton.accessibilityLabel = NSLocalizedString("NEW_TAB", comment: "VoiceOver label for the new tab button.")
		passwordButton.contentMode = .center
		passwordButton.addTarget(self, action: #selector(self.openPasswordManager), for: .touchUpInside)

		let settingsButton = UIButton(type: .system)
		settingsButton.setImage(gearImage, for: .normal)
		settingsButton.accessibilityLabel = NSLocalizedString("SETTINGS", comment: "Title of Settings page.")
		settingsButton.contentMode = .center
		settingsButton.addTarget(self, action: #selector(self.openSettings), for: .touchUpInside)

		let addButton = UIButton(type: .system)
		addButton.setImage(plusImage, for: .normal)
		addButton.accessibilityLabel = NSLocalizedString("PASSWORD_MANAGER", comment: "VoiceOver label for the button that reveals the password manager.")
		addButton.contentMode = .center
		addButton.addTarget(self, action: #selector(self.addTerminal), for: .touchUpInside)

		#if !targetEnvironment(macCatalyst)
		if #available(iOS 14, *) {
			addButton.menu = addButtonMenu
			addButton.addAction(UIAction { [weak self] _ in
				addButton.menu = self?.addButtonMenu
			}, for: .menuActionTriggered)
		} else {
			addButton.addInteraction(UIContextMenuInteraction(delegate: self))
		}
		#endif

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

		#if targetEnvironment(macCatalyst)
		passwordButton.isHidden = true
		settingsButton.isHidden = true
		#endif

		topStackView = UIStackView(arrangedSubviews: [ leftSpacer, titleLabel, passwordButton, settingsButton, addButton, rightSpacer ])
		topStackView.spacing = 6

		mainStackView = UIStackView(arrangedSubviews: [ topStackView, tabsCollectionView ])
		mainStackView.spacing = 2
		mainStackView.axis = .vertical

		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(mainStackView)

		#if targetEnvironment(macCatalyst)
		let barHeight: CGFloat = 26
		#else
		let barHeight: CGFloat = 32
		#endif

		NSLayoutConstraint.activate([
			mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

			tabsCollectionView.heightAnchor.constraint(equalToConstant: barHeight),

			topStackView.heightAnchor.constraint(equalToConstant: barHeight),
			leftSpacer.widthAnchor.constraint(equalTo: leftSpacer.heightAnchor, multiplier: 3, constant: 6 * 3),
			rightSpacer.widthAnchor.constraint(equalToConstant: 0),
			passwordButton.widthAnchor.constraint(equalTo: passwordButton.heightAnchor),
			settingsButton.widthAnchor.constraint(equalTo: settingsButton.heightAnchor),
			addButton.widthAnchor.constraint(equalTo: addButton.heightAnchor)
		])

		#if targetEnvironment(macCatalyst)
		NSLayoutConstraint.activate([
			mainStackView.topAnchor.constraint(equalTo: view.topAnchor),
			mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 67)
		])
		#else
		NSLayoutConstraint.activate([
			mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
		])
		#endif
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		if previousWidth != view.frame.size.width {
			previousWidth = view.frame.size.width

			let isWide = isBigDevice || view.frame.size.width > 450
			mainStackView.axis = isWide ? .horizontal : .vertical
			mainStackView.spacing = isWide ? 6 : 2
			leftSpacer.isHidden = isWide
			titleLabel.isHidden = isWide

			if isWide {
				mainStackView.insertArrangedSubview(tabsCollectionView, at: 0)
			} else {
				mainStackView.insertArrangedSubview(topStackView, at: 0)
			}

			DispatchQueue.main.async {
				self.updateTabWidth()
			}
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
		UIView.performWithoutAnimation {
			self.tabsCollectionView.insertItems(at: [ IndexPath(item: index, section: 0) ])
			self.tabsCollectionView.reloadItems(at: self.tabsCollectionView.indexPathsForVisibleItems)
		}
		updateTabWidth()
	}

	func didRemoveTab(at index: Int) {
		UIView.performWithoutAnimation {
			self.tabsCollectionView.deleteItems(at: [ IndexPath(item: index, section: 0) ])
			self.tabsCollectionView.reloadItems(at: self.tabsCollectionView.indexPathsForVisibleItems)
		}
		updateTabWidth()
	}

	func tabDidUpdate(at index: Int) {
		UIView.performWithoutAnimation {
			self.tabsCollectionView.reloadItems(at: [ IndexPath(item: index, section: 0) ])
		}
		updateTabWidth()

		if dataSource!.selectedTerminalIndex() == index {
			titleLabel.text = dataSource?.terminalName(at: index)
		}
	}

	private func selectTerminal(at index: Int) {
		delegate?.selectTerminal(at: index)
		titleLabel.text = dataSource?.terminalName(at: index)
	}

	private func updateTabWidth() {
		let numberOfTerminals = dataSource?.numberOfTerminals() ?? 0
		if numberOfTerminals == 0 {
			// Happens when the last tab is closed. We don’t need to do anything in that case. When the
			// window will be reused (on iPhone), we’ll get called again after a new terminal is created.
			return
		}

		let maxTerminals: Int
		if tabsCollectionView.frame.size.width < 400 {
			maxTerminals = 2
		} else if tabsCollectionView.frame.size.width < 900 {
			maxTerminals = 4
		} else {
			maxTerminals = 6
		}

		let width: CGFloat
		if numberOfTerminals <= maxTerminals {
			width = tabsCollectionView.frame.size.width / CGFloat(numberOfTerminals)
		} else {
			width = (tabsCollectionView.frame.size.width / (CGFloat(maxTerminals) + 1)) * 0.9
		}

		let itemSize = CGSize(width: width, height: tabsCollectionView.frame.size.height)

		// TODO: This works, but the animations are unpleasant. Why do the cells not animate their
		// contents when I do this?
		UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: {
			let layout = self.tabsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
			layout.itemSize = itemSize
			self.tabsCollectionView.performBatchUpdates(nil, completion: nil)
		}, completion: { _ in
			// Have the collection view scroll to the new location of the selected tab, in case it’s now
			// off-screen.
			if let index = self.dataSource?.selectedTerminalIndex() {
				self.didSelectTab(at: index)
			}
		})
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

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selectTerminal(at: indexPath.item)
	}

}

extension TabToolbarViewController: UIContextMenuInteractionDelegate {

	var addButtonMenu: UIMenu {
		var items = [UIMenuElement]()
		if UIApplication.shared.supportsMultipleScenes {
			items.append(UICommand(title: NSLocalizedString("NEW_WINDOW", comment: "VoiceOver label for the new window button."), image: UIImage(systemName: "plus.rectangle.on.rectangle"), action: #selector(RootViewController.addWindow)))
			items.append(UICommand(title: NSLocalizedString("CLOSE_WINDOW", comment: "VoiceOver label for the close window button."), image: UIImage(systemName: "xmark.rectangle"), action: #selector(RootViewController.closeCurrentWindow), attributes: .destructive))
		} else {
			let title = String.localizedStringWithFormat(NSLocalizedString("CLOSE_WINDOW_ACTION", comment: ""), dataSource?.numberOfTerminals() ?? 0)
			items.append(UICommand(title: title, image: UIImage(systemName: "xmark"), action: #selector(RootViewController.closeCurrentWindow), attributes: .destructive))
		}
		return UIMenu(children: items)
	}

	func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ -> UIMenu? in self.addButtonMenu })
	}

}
