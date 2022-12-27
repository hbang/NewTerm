//
//  TabToolbarViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit
import SwiftUIX

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
	weak var delegate: TabToolbarDelegate? {
		didSet {
			state.delegate = delegate
		}
	}

	private let state = TabToolbarState()

	private var backdropView: UIToolbar!
	private var hostingView: UIHostingView<AnyView>!

	override func viewDidLoad() {
		super.viewDidLoad()

		view.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)

		backdropView = UIToolbar()
		backdropView.frame = view.bounds
		backdropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		backdropView.delegate = self
		view.addSubview(backdropView)

		hostingView = UIHostingView(rootView: AnyView(TabToolbarView()
			.environmentObject(state)))
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		hostingView.shouldResizeToFitContent = true
		hostingView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
		view.addSubview(hostingView)

		NSLayoutConstraint.activate([
			hostingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			hostingView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
			hostingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			hostingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
		])
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
		state.selectedIndex = dataSource!.selectedTerminalIndex()
	}

	func didAddTab(at index: Int) {
		let terminal = TerminalTab(title: "",
															 screenSize: .default,
															 isDirty: false,
															 hasBell: false)
		if index == state.terminals.count {
			state.terminals.append(terminal)
		} else {
			state.terminals.insert(terminal, at: index)
		}
	}

	func didRemoveTab(at index: Int) {
		state.terminals.remove(at: index)
	}

	func tabDidUpdate(at index: Int) {
		state.terminals[index].title = dataSource?.terminalName(at: index) ?? .localize("Terminal")
	}

	private func selectTerminal(at index: Int) {
		state.selectedIndex = index
		delegate?.selectTerminal(at: index)
	}

}

extension TabToolbarViewController: UIToolbarDelegate {

	func position(for bar: UIBarPositioning) -> UIBarPosition {
		// Helps UIToolbar figure out where to place the shadow line
		return .top
	}

}
