//
//  RootViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

	private var terminals: [TerminalSessionViewController] = []
	private var selectedTabIndex = Int(0)

	private let tabToolbar = TabToolbarViewController()

	private var titleObservers = [NSKeyValueObservation]()

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

		if #available(iOS 13, *), UIApplication.shared.supportsMultipleScenes {
			addKeyCommand(UIKeyCommand(input: "n", modifierFlags: [ .command ], action: #selector(self.addWindow), discoverabilityTitle: NSLocalizedString("NEW_WINDOW", comment: "VoiceOver label for the new window button.")))
			addKeyCommand(UIKeyCommand(input: "w", modifierFlags: [ .command, .shift ], action: #selector(self.closeCurrentWindow), discoverabilityTitle: NSLocalizedString("CLOSE_WINDOW", comment: "VoiceOver label for the close window button.")))
		}
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let topMargin: CGFloat
		if #available(iOS 11, *) {
			topMargin = view.safeAreaInsets.top
		} else {
			topMargin = UIApplication.shared.statusBarFrame.size.height
		}

		let topBarHeight: CGFloat = isBigDevice ? 33 : 66
		tabToolbar.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: topMargin + topBarHeight)
		tabToolbar.topMargin = topMargin

		let barInsets = UIEdgeInsets(top: tabToolbar.view.frame.size.height, left: 0, bottom: 0, right: 0)

		for viewController in terminals {
			viewController.barInsets = barInsets
		}
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		if #available(iOS 13, *) {
			return super.preferredStatusBarStyle
		} else {
			return .lightContent
		}
	}

	// MARK: - Tab management

	@IBAction func addTerminal() {
		let terminalViewController = TerminalSessionViewController()

		addChild(terminalViewController)
		terminalViewController.willMove(toParent: self)
		view.insertSubview(terminalViewController.view, belowSubview: tabToolbar.view)
		terminalViewController.didMove(toParent: self)

		terminals.append(terminalViewController)

		let index = terminals.count - 1
		tabToolbar.didAddTab(at: index)
		selectTerminal(at: index)

		titleObservers.append(terminalViewController.observe(\.title, changeHandler: { viewController, _ in
			self.tabToolbar.tabDidUpdate(at: index)
		}))
	}

	func removeTerminal(terminal terminalViewController: TerminalSessionViewController) {
		guard let index = terminals.firstIndex(of: terminalViewController) else {
			NSLog("asked to remove terminal that doesn’t exist? %@", terminalViewController)
			return
		}

		terminalViewController.removeFromParent()
		terminalViewController.view.removeFromSuperview()

		terminals.remove(at: index)
		titleObservers.remove(at: index)

		// If this was the last tab, close the window (or make a new tab if not supported). Otherwise
		// select the closest tab we have available
		if terminals.count == 0 {
			if #available(iOS 13, *), UIApplication.shared.supportsMultipleScenes {
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

		// If the previous index is now out of bounds, just use nil as our previous. The tab and view
		// controller were removed so we don’t need to do anything
		let previousViewController = oldSelectedTabIndex == nil ? nil : terminals[oldSelectedTabIndex!]
		let newViewController = terminals[index]

		selectedTabIndex = index

		// Call the appropriate view controller lifecycle methods on the previous and new view controllers
		previousViewController?.viewWillDisappear(false)
		previousViewController?.view.isHidden = true
		previousViewController?.viewDidDisappear(false)

		newViewController.viewWillAppear(false)
		newViewController.view.isHidden = false
		newViewController.viewDidAppear(false)
	}

	// MARK: - Window management

	@available(iOS 13, *)
	@objc func addWindow() {
		let options = UIWindowScene.ActivationRequestOptions()
		options.requestingScene = view.window!.windowScene
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: options, errorHandler: nil)
	}

	@available(iOS 13, *)
	@objc func closeCurrentWindow() {
		if terminals.count == 0 {
			destructScene()
			return
		}

		let title: String?
		let action: String
		let cancel = NSLocalizedString("Cancel", bundle: .uikit, comment: "")
		if isBigDevice {
			title = String.localizedStringWithFormat(NSLocalizedString("CLOSE_WINDOW_TITLE", comment: ""), terminals.count)
			action = NSLocalizedString("Close", bundle: .uikit, comment: "")
		} else {
			title = nil
			action = String.localizedStringWithFormat(NSLocalizedString("CLOSE_WINDOW_ACTION", comment: ""), terminals.count)
		}

		let alertController = UIAlertController(title: title, message: nil, preferredStyle: isBigDevice ? .alert : .actionSheet)
		alertController.addAction(UIAlertAction(title: action, style: isBigDevice ? .default : .destructive, handler: { _ in
			self.destructScene()
		}))
		alertController.addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
		present(alertController, animated: true, completion: nil)
	}

	@available(iOS 13, *)
	private func destructScene() {
		if UIApplication.shared.supportsMultipleScenes {
			UIApplication.shared.requestSceneSessionDestruction(view.window!.windowScene!.session, options: nil, errorHandler: nil)
		} else {
			removeAllTerminals()
		}
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
		let terminal = terminals[selectedTabIndex]
		terminal.activatePasswordManager()
	}

}
