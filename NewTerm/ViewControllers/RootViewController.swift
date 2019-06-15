//
//  RootViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

	var terminals: [TerminalSessionViewController] = []
	var selectedTabIndex = Int(0)

	var tabToolbar = TabToolbar()

	var tabsCollectionView: UICollectionView {
		return tabToolbar.tabsCollectionView
	}

	override func loadView() {
		super.loadView()

		navigationController!.isNavigationBarHidden = true

		tabToolbar.autoresizingMask = [ .flexibleWidth ]
		tabToolbar.addButton.addTarget(self, action: #selector(self.addTerminal), for: .touchUpInside)

		tabsCollectionView.dataSource = self
		tabsCollectionView.delegate = self

		view.addSubview(tabToolbar)

		addTerminal()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let barHeight = CGFloat(isSmallDevice ? 32 : 40)

		let topMargin: CGFloat

		if #available(iOS 11.0, *) {
			topMargin = view.safeAreaInsets.top
		} else {
			topMargin = UIApplication.shared.statusBarFrame.size.height
		}

		tabToolbar.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: topMargin + barHeight)
		tabToolbar.topMargin = topMargin

		let barInsets = UIEdgeInsets(top: tabToolbar.frame.size.height, left: 0, bottom: 0, right: 0)

		for viewController in terminals {
			viewController.barInsets = barInsets
		}
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	// MARK: - Tab management

	@objc func addTerminal() {
		let terminalViewController = TerminalSessionViewController()

		addChild(terminalViewController)
		terminalViewController.willMove(toParent: self)
		view.insertSubview(terminalViewController.view, belowSubview: tabToolbar)
		terminalViewController.didMove(toParent: self)

		terminals.append(terminalViewController)

		tabsCollectionView.reloadData()
		tabsCollectionView.layoutIfNeeded()
		switchToTab(index: terminals.count - 1)
		tabsCollectionView.reloadData()
	}

	func removeTerminal(terminal terminalViewController: TerminalSessionViewController) {
		guard let index = terminals.firstIndex(of: terminalViewController) else {
			NSLog("asked to remove terminal that doesn’t exist? %@", terminalViewController)
			return
		}

		terminalViewController.removeFromParent()
		terminalViewController.view.removeFromSuperview()

		terminals.remove(at: index)

		// if this was the last tab, make a new tab. otherwise select the closest tab we have available
		if terminals.count == 0 {
			addTerminal()
		} else {
			tabsCollectionView.reloadData()
			tabsCollectionView.layoutIfNeeded()
			switchToTab(index: index >= terminals.count ? index - 1 : index)
		}
	}

	func removeTerminal(index: Int) {
		removeTerminal(terminal: terminals[index])
	}

	@objc func removeTerminalButtonTapped(_ button: UIButton) {
		removeTerminal(index: button.tag)
	}

	func switchToTab(index: Int) {
		// if this is what’s already selected, just select it again and return
		if index == selectedTabIndex {
			tabsCollectionView.selectItem(at: IndexPath(item: selectedTabIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
		}

		let oldSelectedTabIndex = selectedTabIndex < terminals.count ? selectedTabIndex : nil

		// if the previous index is now out of bounds, just use nil as our previous. the tab and view
		// controller were removed so we don’t need to do anything
		let previousViewController = oldSelectedTabIndex == nil ? nil : terminals[oldSelectedTabIndex!]
		let newViewController = terminals[index]

		selectedTabIndex = index

		// call the appropriate view controller lifecycle methods on the previous and new view controllers
		previousViewController?.viewWillDisappear(false)
		previousViewController?.view.isHidden = true
		previousViewController?.viewDidDisappear(false)

		newViewController.viewWillAppear(false)
		newViewController.view.isHidden = false
		newViewController.viewDidAppear(false)

		tabsCollectionView.performBatchUpdates({
			if oldSelectedTabIndex != nil {
				self.tabsCollectionView.deselectItem(at: IndexPath(item: oldSelectedTabIndex!, section: 0), animated: false)
			}

			self.tabsCollectionView.selectItem(at: IndexPath(item: selectedTabIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
		}, completion: { (_) in
			// TODO: hack because the previous tab doesn’t deselect for some reason and ugh i hate this
			self.tabsCollectionView.reloadData()
		})
	}

}

extension RootViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return terminals.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let terminalViewController = terminals[indexPath.row]

		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabCollectionViewCell.reuseIdentifier, for: indexPath) as! TabCollectionViewCell
		cell.textLabel.text = terminalViewController.title
		cell.isSelected = selectedTabIndex == indexPath.row
		cell.closeButton.tag = indexPath.row
		cell.closeButton.addTarget(self, action: #selector(self.removeTerminalButtonTapped(_:)), for: .touchUpInside)
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: 100, height: tabsCollectionView.frame.size.height)
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		switchToTab(index: indexPath.row)
	}

}
