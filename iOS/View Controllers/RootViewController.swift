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

	let tabToolbar = TabToolbarViewController()

	override func loadView() {
		super.loadView()

		navigationController!.isNavigationBarHidden = true

		tabToolbar.view.autoresizingMask = [ .flexibleWidth ]
		tabToolbar.delegate = self
		tabToolbar.dataSource = self
		addChild(tabToolbar)
		view.addSubview(tabToolbar.view)

		addTerminal()

		addKeyCommand(UIKeyCommand(input: "t", modifierFlags: [ .command ], action: #selector(self.addTerminal), discoverabilityTitle: NSLocalizedString("NEW_TAB", comment: "VoiceOver label for the new tab button.")))
		addKeyCommand(UIKeyCommand(input: "w", modifierFlags: [ .command ], action: #selector(self.removeCurrentTerminal), discoverabilityTitle: NSLocalizedString("CLOSE_TAB", comment: "VoiceOver label for the close tab button.")))

		if #available(iOS 13.0, *), UIApplication.shared.supportsMultipleScenes {
			addKeyCommand(UIKeyCommand(input: "n", modifierFlags: [ .command ], action: #selector(self.addWindow), discoverabilityTitle: NSLocalizedString("NEW_WINDOW", comment: "VoiceOver label for the new window button.")))
			addKeyCommand(UIKeyCommand(input: "w", modifierFlags: [ .command, .shift ], action: #selector(self.closeCurrentWindow), discoverabilityTitle: NSLocalizedString("CLOSE_WINDOW", comment: "VoiceOver label for the close window button.")))

			tabToolbar.addButton.addInteraction(UIContextMenuInteraction(delegate: self))
		}
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let topMargin: CGFloat

		if #available(iOS 11.0, *) {
			topMargin = view.safeAreaInsets.top
		} else {
			topMargin = UIApplication.shared.statusBarFrame.size.height
		}

		tabToolbar.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: topMargin + 66)
		tabToolbar.topMargin = topMargin

		let barInsets = UIEdgeInsets(top: tabToolbar.view.frame.size.height, left: 0, bottom: 0, right: 0)

		for viewController in terminals {
			viewController.barInsets = barInsets
		}
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	// MARK: - Tab management

	@IBAction func addTerminal() {
		let terminalViewController = TerminalSessionViewController()

		addChild(terminalViewController)
		terminalViewController.willMove(toParent: self)
		view.insertSubview(terminalViewController.view, belowSubview: tabToolbar.view)
		terminalViewController.didMove(toParent: self)

		terminals.append(terminalViewController)

		tabToolbar.didAddTab(at: terminals.count - 1)
		selectTerminal(at: terminals.count - 1)
	}

	func removeTerminal(terminal terminalViewController: TerminalSessionViewController) {
		guard let index = terminals.firstIndex(of: terminalViewController) else {
			NSLog("asked to remove terminal that doesn’t exist? %@", terminalViewController)
			return
		}

		terminalViewController.removeFromParent()
		terminalViewController.view.removeFromSuperview()

		terminals.remove(at: index)

		// If this was the last tab, close the window (or make a new tab if not supported). Otherwise
		// select the closest tab we have available
		if terminals.count == 0 {
			if #available(iOS 13.0, *), UIApplication.shared.supportsMultipleScenes {
				closeCurrentWindow()
			} else {
				addTerminal()
			}
		} else {
			selectTerminal(at: index >= terminals.count ? index - 1 : index)
		}
	}

	func removeTerminal(at index: Int) {
		removeTerminal(terminal: terminals[index])
	}

	@IBAction func removeCurrentTerminal() {
		removeTerminal(at: selectedTabIndex)
	}

	@IBAction func removeAllTerminals() {
		for terminalViewController in terminals {
			terminalViewController.removeFromParent()
			terminalViewController.view.removeFromSuperview()
		}

		terminals.removeAll()
		addTerminal()
	}

	func selectTerminal(at index: Int) {
		tabToolbar.didSelectTab(at: index)

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
	}

	// MARK: - Window management

	@available(iOS 13.0, *)
	@IBAction func addWindow() {
		let options = UIWindowScene.ActivationRequestOptions()
		options.requestingScene = view.window!.windowScene
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: options, errorHandler: nil)
	}

	@available(iOS 13.0, *)
	@IBAction func closeCurrentWindow() {
		UIApplication.shared.requestSceneSessionDestruction(view.window!.windowScene!.session, options: nil, errorHandler: nil)
	}

}

extension RootViewController: TabToolbarDataSource {

	func numberOfTerminals() -> Int {
		return terminals.count
	}

	func selectedTerminalIndex() -> Int {
		return selectedTabIndex
	}

	func terminalName(at index: Int) -> String {
		return terminals[index].title ?? ""
	}

}

extension RootViewController: TabToolbarDelegate {

	func openSettings() {
		if presentedViewController == nil {
			let rootController = PreferencesRootController()
			rootController.modalPresentationStyle = .formSheet
			navigationController!.present(rootController, animated: true, completion: nil)
		}
	}

	func openPasswordManager() {
	}

}

@available(iOS 13.0, *)
extension RootViewController: UIContextMenuInteractionDelegate {

	func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		if !UIApplication.shared.supportsMultipleScenes {
			return nil
		}
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ -> UIMenu? in
			return UIMenu(title: "", children: [
				UICommand(title: NSLocalizedString("NEW_WINDOW", comment: "VoiceOver label for the new window button."), image: UIImage(systemName: "plus.rectangle.on.rectangle"), action: #selector(self.addWindow)),
				UICommand(title: NSLocalizedString("CLOSE_WINDOW", comment: "VoiceOver label for the close window button."), image: UIImage(systemName: "xmark.rectangle"), action: #selector(self.closeCurrentWindow))
			])
		})
	}

}
