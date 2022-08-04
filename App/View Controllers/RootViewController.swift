//
//  RootViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit
import SwiftUI
import NewTermCommon

class RootViewController: UIViewController {

	static let settingsViewDoneNotification = Notification.Name(rawValue: "RootViewControllerSettingsViewDoneNotification")

	var initialCommand: String?

	private var terminals: [BaseTerminalSplitViewControllerChild] = []
	private var selectedTabIndex = 0

	private var tabToolbar: TabToolbarViewController?

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationController!.isNavigationBarHidden = true

		#if !targetEnvironment(macCatalyst)
		tabToolbar = TabToolbarViewController()
		tabToolbar!.view.autoresizingMask = [.flexibleWidth]
		tabToolbar!.delegate = self
		tabToolbar!.dataSource = self
		addChild(tabToolbar!)
		view.addSubview(tabToolbar!.view)
		#endif

		addTerminal()

		addKeyCommand(UIKeyCommand(title: .localize("SETTINGS", comment: "Title of Settings page."),
															 image: UIImage(systemName: "gear"),
															 action: #selector(self.openSettings),
															 input: ",",
															 modifierFlags: .command))

		addKeyCommand(UIKeyCommand(title: .localize("NEW_TAB", comment: "VoiceOver label for the new tab button."),
															 action: #selector(self.newTab),
															 input: "t",
															 modifierFlags: .command))
		addKeyCommand(UIKeyCommand(title: .localize("CLOSE_TAB", comment: "VoiceOver label for the close tab button."),
															 action: #selector(self.removeCurrentTerminal),
															 input: "w",
															 modifierFlags: .command))

		#if !targetEnvironment(macCatalyst)
		addKeyCommand(UIKeyCommand(title: .localize("SHOW_PREVIOUS_TAB"),
															 action: #selector(self.selectPreviousTab),
															 input: "{",
															 modifierFlags: .command))
		addKeyCommand(UIKeyCommand(title: .localize("SHOW_NEXT_TAB"),
															 action: #selector(self.selectNextTab),
															 input: "}",
															 modifierFlags: .command))
		#endif

		let digits = (Array(1...9) + [0]).map { "\($0)" }
		for digit in digits {
			addKeyCommand(UIKeyCommand(action: #selector(self.selectTabFromKeyCommand),
																 input: digit,
																 modifierFlags: .command))
		}

		if UIApplication.shared.supportsMultipleScenes {
			addKeyCommand(UIKeyCommand(title: .localize("NEW_WINDOW", comment: "VoiceOver label for the new window button."),
																 action: #selector(self.addWindow),
																 input: "n",
																 modifierFlags: .command))
			addKeyCommand(UIKeyCommand(title: .localize("CLOSE_WINDOW", comment: "VoiceOver label for the close window button."),
																 action: #selector(self.closeCurrentWindow),
																 input: "w",
																 modifierFlags: [.command, .shift]))
		}

		addKeyCommand(UIKeyCommand(title: .localize("SPLIT_HORIZONTALLY"),
															 action: #selector(self.splitHorizontally),
															 input: "d",
															 modifierFlags: [.command, .shift]))
		addKeyCommand(UIKeyCommand(title: .localize("SPLIT_VERTICALLY"),
															 action: #selector(self.splitVertically),
															 input: "d",
															 modifierFlags: .command))


		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.dismissSettings), name: Self.settingsViewDoneNotification, object: nil)

		preferencesUpdated()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		// TODO: Cleanup
		#if !targetEnvironment(macCatalyst)
		let isWide = isBigDevice || view.frame.size.width > 450
		let topBarHeight: CGFloat = isWide ? 33 : 66
		tabToolbar?.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.safeAreaInsets.top + topBarHeight)

		for viewController in terminals {
			viewController.additionalSafeAreaInsets.top = topBarHeight
		}
		#endif
	}

	// MARK: - Preferences

	@objc private func preferencesUpdated() {
		let preferences = Preferences.shared
		view.backgroundColor = preferences.colorMap.background
	}

	// MARK: - Tab management

	@objc func newTab() {
		#if targetEnvironment(macCatalyst)
		if let sceneDelegate = view.window?.windowScene?.delegate as? TerminalSceneDelegate {
			sceneDelegate.createWindow(asTab: true)
		}
		#else
		addTerminal()
		#endif
	}

	func addTerminal() {
		let index = min(selectedTabIndex + 1, terminals.count)
		addTerminal(at: index, initialCommand: initialCommand)
		selectTerminal(at: index)
		initialCommand = nil
	}

	private func addTerminal(at index: Int, axis: NSLayoutConstraint.Axis? = nil, initialCommand: String? = nil) {
		let splitViewController = TerminalSplitViewController()
		splitViewController.view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		splitViewController.view.frame = view.bounds
		splitViewController.delegate = self

		let newTerminal = TerminalSessionViewController()
		newTerminal.initialCommand = initialCommand

		addChild(splitViewController)
		splitViewController.willMove(toParent: self)
		if let tabToolbar = tabToolbar {
			view.insertSubview(splitViewController.view, belowSubview: tabToolbar.view)
		} else {
			view.addSubview(splitViewController.view)
		}
		splitViewController.didMove(toParent: self)

		if index == terminals.count {
			splitViewController.viewControllers = [newTerminal]
			terminals.append(splitViewController)
			tabToolbar?.didAddTab(at: index)
		} else {
			if let axis = axis {
				let firstViewController = terminals[index]
				let secondViewController = newTerminal
				splitViewController.axis = axis
				splitViewController.viewControllers = [firstViewController, secondViewController]
			} else {
				splitViewController.viewControllers = [newTerminal]
			}

			terminals[index] = splitViewController
			tabToolbar?.tabDidUpdate(at: index)
		}
	}

	func removeTerminal(viewController: BaseTerminalSplitViewControllerChild) {
		guard let index = terminals.firstIndex(of: viewController) else {
			NSLog("asked to remove terminal that doesn’t exist? %@", viewController)
			return
		}

		viewController.removeFromParent()
		viewController.view.removeFromSuperview()

		terminals.remove(at: index)
		tabToolbar?.didRemoveTab(at: index)

		// If this was the last tab, close the window (or make a new tab if not supported). Otherwise
		// select the closest tab we have available.
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
		removeTerminal(viewController: terminals[index])
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
		let oldSelectedTabIndex = selectedTabIndex < terminals.count ? selectedTabIndex : nil

		// If the previous index is now out of bounds, just use nil as our previous. The tab and view
		// controller were removed so we don’t need to do anything
		let previousViewController = oldSelectedTabIndex == nil ? nil : terminals[oldSelectedTabIndex!]
		let newViewController = terminals[index]

		selectedTabIndex = index
		tabToolbar?.didSelectTab(at: index)
		handleTitleChange(at: index)

		// Call the appropriate view controller lifecycle methods on the previous and new view controllers
		previousViewController?.viewWillDisappear(false)
		previousViewController?.view.isHidden = true
		previousViewController?.viewDidDisappear(false)

		newViewController.viewWillAppear(false)
		newViewController.view.isHidden = false
		newViewController.viewDidAppear(false)
	}

	private func handleTitleChange(at index: Int) {
		if selectedTabIndex == index {
			view.window?.windowScene?.title = terminalName(at: index)

			if #available(iOS 15, *),
				 let size = terminals[index].screenSize {
				view.window?.windowScene?.subtitle = "\(size.cols)×\(size.rows)"
			}
		}
	}

	@objc private func selectPreviousTab() {
		if selectedTabIndex == 0 {
			selectTerminal(at: terminals.count - 1)
		} else {
			selectTerminal(at: selectedTabIndex - 1)
		}
	}

	@objc private func selectNextTab() {
		if selectedTabIndex == terminals.count - 1 {
			selectTerminal(at: 0)
		} else {
			selectTerminal(at: selectedTabIndex + 1)
		}
	}

	@objc private func selectTabFromKeyCommand(_ keyCommand: UIKeyCommand) {
		guard var digit = Int(keyCommand.input ?? ""),
					digit >= 0 && digit <= 9 else {
			return
		}

		if digit == 0 {
			digit = 10
		}
		digit -= 1

		if terminals.count > digit {
			selectTerminal(at: digit)
		}
	}

	// MARK: - Window management

	@objc func addWindow() {
		if let sceneDelegate = view.window?.windowScene?.delegate as? TerminalSceneDelegate {
			sceneDelegate.createWindow(asTab: false)
		}
	}

	@objc func closeCurrentWindow() {
		if terminals.count == 0 {
			destructScene()
			return
		}

		let title: String?
		let action: String
		if isBigDevice {
			title = String.localizedStringWithFormat(.localize("CLOSE_WINDOW_TITLE"), terminals.count)
			action = .close
		} else {
			title = nil
			action = String.localizedStringWithFormat(.localize("CLOSE_WINDOW_ACTION"), terminals.count)
		}

		let alertController = UIAlertController(title: title, message: nil, preferredStyle: isBigDevice ? .alert : .actionSheet)
		alertController.addAction(UIAlertAction(title: action, style: isBigDevice ? .default : .destructive, handler: { _ in
			self.destructScene()
		}))
		alertController.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: nil))
		present(alertController, animated: true, completion: nil)
	}

	private func destructScene() {
		if UIApplication.shared.supportsMultipleScenes {
			// TODO: Probably need to directly use NSWindow APIs for this on Catalyst.
			// https://developer.apple.com/forums/thread/127382
			UIApplication.shared.requestSceneSessionDestruction(view.window!.windowScene!.session, options: nil, errorHandler: nil)
		} else {
			removeAllTerminals()
		}
	}

	// MARK: - Split views

	@objc func splitHorizontally() {
		addTerminal(at: selectedTabIndex, axis: .vertical)
	}

	@objc func splitVertically() {
		addTerminal(at: selectedTabIndex, axis: .horizontal)
	}

}

extension RootViewController: TerminalSplitViewControllerDelegate {

	func terminal(viewController: BaseTerminalSplitViewControllerChild, titleDidChange title: String) {
		guard let index = terminals.firstIndex(of: viewController) else {
			return
		}

		handleTitleChange(at: index)
		tabToolbar?.tabDidUpdate(at: index)
	}

	func terminal(viewController: BaseTerminalSplitViewControllerChild, screenSizeDidChange screenSize: ScreenSize) {
		guard let index = terminals.firstIndex(of: viewController) else {
			return
		}

		handleTitleChange(at: index)
		tabToolbar?.tabDidUpdate(at: index)
	}

	func terminalDidBecomeActive(viewController: BaseTerminalSplitViewControllerChild) {
		guard let index = terminals.firstIndex(of: viewController) else {
			return
		}

		handleTitleChange(at: index)
		tabToolbar?.tabDidUpdate(at: index)
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
		let title = terminals[index].title
		return title == nil || title!.isEmpty
			? .localize("TERMINAL", comment: "Generic title displayed before the terminal sets a proper title.")
			: title!
	}

}

extension RootViewController: TabToolbarDelegate {

	@objc func openSettings() {
		if UIApplication.shared.supportsMultipleScenes {
			UIApplication.shared.activateScene(userActivity: .settingsScene,
																				 requestedByScene: view.window?.windowScene,
																				 withProminentPresentation: true)
		} else {
			if presentedViewController == nil {
				let viewController = UIHostingController(rootView: SettingsView())
				viewController.modalPresentationStyle = .formSheet
				navigationController?.present(viewController, animated: true, completion: nil)
			}
		}
	}

	@objc private func dismissSettings() {
		presentedViewController?.dismiss(animated: true, completion: nil)
	}

	func openPasswordManager() {
		// TODO
//		let terminal = terminals[selectedTabIndex]
//		terminal.activatePasswordManager()
	}

}
