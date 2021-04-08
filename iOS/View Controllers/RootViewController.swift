//
//  RootViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit
import SwiftUI

class RootViewController: UIViewController {

	static let settingsViewDoneNotification = Notification.Name(rawValue: "RootViewControllerSettingsViewDoneNotification")

	private var terminals: [TerminalSessionViewController] = []
	private var selectedTabIndex = Int(0)

	private let tabToolbar = TabToolbarViewController()

	private var titleObservers = [NSKeyValueObservation]()

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationController!.isNavigationBarHidden = true

		tabToolbar.view.autoresizingMask = [ .flexibleWidth ]
		tabToolbar.delegate = self
		tabToolbar.dataSource = self
		addChild(tabToolbar)
		view.addSubview(tabToolbar.view)

		addTerminal()

		addKeyCommand(UIKeyCommand(title: NSLocalizedString("SETTINGS", comment: "Title of Settings page."),
															 image: UIImage(systemName: "gear"),
															 action: #selector(self.openSettings),
															 input: ",",
															 modifierFlags: .command))

		addKeyCommand(UIKeyCommand(title: NSLocalizedString("NEW_TAB", comment: "VoiceOver label for the new tab button."),
															 action: #selector(self.addTerminal),
															 input: "t",
															 modifierFlags: .command))
		addKeyCommand(UIKeyCommand(title: NSLocalizedString("CLOSE_TAB", comment: "VoiceOver label for the close tab button."),
															 action: #selector(self.removeCurrentTerminal),
															 input: "w",
															 modifierFlags: .command))

		if UIApplication.shared.supportsMultipleScenes {
			addKeyCommand(UIKeyCommand(title: NSLocalizedString("NEW_WINDOW", comment: "VoiceOver label for the new window button."),
																 action: #selector(self.addWindow),
																 input: "n",
																 modifierFlags: .command))
			addKeyCommand(UIKeyCommand(title: NSLocalizedString("CLOSE_WINDOW", comment: "VoiceOver label for the close window button."),
																 action: #selector(self.closeCurrentWindow),
																 input: "w",
																 modifierFlags: [ .command, .shift ]))
		}

		NotificationCenter.default.addObserver(self, selector: #selector(self.dismissSettings), name: Self.settingsViewDoneNotification, object: nil)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		// TODO: Cleanup
		#if targetEnvironment(macCatalyst)
		let topBarHeight: CGFloat = 4
		tabToolbar.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 33)
		tabToolbar.topMargin = 0
		#else
		let topBarHeight: CGFloat = isBigDevice ? 33 : 66
		tabToolbar.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.safeAreaInsets.top + topBarHeight)
		tabToolbar.topMargin = view.safeAreaInsets.top
		#endif

		for viewController in terminals {
			viewController.additionalSafeAreaInsets.top = topBarHeight
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
			if UIApplication.shared.supportsMultipleScenes {
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

	@objc func addWindow() {
		let options = UIWindowScene.ActivationRequestOptions()
		options.requestingScene = view.window!.windowScene
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: options, errorHandler: nil)
	}

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

	@objc func openSettings() {
		if presentedViewController == nil {
			let viewController = UIHostingController(rootView: SettingsView())
			viewController.modalPresentationStyle = .formSheet
			navigationController?.present(viewController, animated: true, completion: nil)
		}
	}

	@objc private func dismissSettings() {
		presentedViewController?.dismiss(animated: true, completion: nil)
	}

	func openPasswordManager() {
		let terminal = terminals[selectedTabIndex]
		terminal.activatePasswordManager()
	}

}
