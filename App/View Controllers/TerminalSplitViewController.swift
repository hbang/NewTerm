//
//  TerminalSplitViewController.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 10/4/21.
//

import UIKit

protocol TerminalSplitViewControllerDelegate: AnyObject {
	func terminal(viewController: BaseTerminalSplitViewControllerChild, titleDidChange title: String)
	func terminal(viewController: BaseTerminalSplitViewControllerChild, screenSizeDidChange screenSize: ScreenSize)
	func terminalDidBecomeActive(viewController: BaseTerminalSplitViewControllerChild)
}

class BaseTerminalSplitViewControllerChild: UIViewController {
	weak var delegate: TerminalSplitViewControllerDelegate?

	var screenSize: ScreenSize?
	var isSplitViewResizing = false
	var showsTitleView = false
}

class TerminalSplitViewController: BaseTerminalSplitViewControllerChild {

	private static let splitSnapPoints: [Double] = [
		1 / 2, // 50%
		1 / 4, // 25%
		1 / 3, // 33%
		2 / 3, // 66%
		3 / 4  // 75%
	]

	var viewControllers: [BaseTerminalSplitViewControllerChild]! {
		didSet { updateViewControllers() }
	}
	var axis: NSLayoutConstraint.Axis = .horizontal {
		didSet { stackView.axis = axis }
	}

	override var isSplitViewResizing: Bool {
		didSet { updateIsSplitViewResizing() }
	}
	override var showsTitleView: Bool {
		didSet { updateShowsTitleView() }
	}

	private let stackView = UIStackView()
	private var splitPercentages = [Double]()
	private var oldSplitPercentages = [Double]()
	private var constraints = [NSLayoutConstraint]()

	private var selectedIndex = 0

	private var keyboardVisible = false
	private var keyboardHeight: CGFloat = 0

	override func loadView() {
		super.loadView()

		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = axis
		stackView.spacing = 0
		view.addSubview(stackView)

		NSLayoutConstraint.activate([
			view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
			view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
			view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
			view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
		])
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardVisibilityChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		// Removing keyboard notification observers should come first so we don’t trigger a bunch of
		// probably unnecessary screen size changes.
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
	}

	override func updateViewConstraints() {
		super.updateViewConstraints()
		updateConstraints()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		updateConstraints()
	}

	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		updateConstraints()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateConstraints()
	}

	// MARK: - Split View

	private func updateViewControllers() {
		loadViewIfNeeded()

		for view in stackView.arrangedSubviews {
			view.removeFromSuperview()
		}

		for (viewController, i) in zip(viewControllers, viewControllers.indices) {
			let containerView = UIView()
			containerView.translatesAutoresizingMaskIntoConstraints = false

			addChild(viewController)
			viewController.delegate = self
			viewController.view.frame = containerView.bounds
			viewController.view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
			containerView.addSubview(viewController.view)
			stackView.addArrangedSubview(containerView)
			viewController.didMove(toParent: self)

			if i != viewControllers.count - 1 {
				let splitGrabberView = SplitGrabberView(axis: axis)
				splitGrabberView.translatesAutoresizingMaskIntoConstraints = false
				splitGrabberView.delegate = self
				stackView.addArrangedSubview(splitGrabberView)
			}
		}

		if splitPercentages.count != viewControllers.count {
			let split = Double(1) / Double(viewControllers.count)
			splitPercentages = Array(repeating: split, count: viewControllers.count)
		}

		let attribute: NSLayoutConstraint.Attribute
		let otherAttribute: NSLayoutConstraint.Attribute
		switch axis {
		case .horizontal:
			attribute = .width
			otherAttribute = .height
		case .vertical:
			attribute = .height
			otherAttribute = .width
		@unknown default: fatalError()
		}

		NSLayoutConstraint.deactivate(constraints)
		constraints = viewControllers.map { viewController in
			NSLayoutConstraint(item: viewController.view.superview!,
												 attribute: attribute,
												 relatedBy: .equal,
												 toItem: nil,
												 attribute: .notAnAttribute,
												 multiplier: 1,
												 constant: 0)
		}
		NSLayoutConstraint.activate(constraints)
		NSLayoutConstraint.activate(viewControllers.map { viewController in
			NSLayoutConstraint(item: viewController.view.superview!,
												 attribute: otherAttribute,
												 relatedBy: .equal,
												 toItem: stackView,
												 attribute: otherAttribute,
												 multiplier: 1,
												 constant: 0)
		})
	}

	func remove(viewController: UIViewController) {
		guard let viewController = viewController as? BaseTerminalSplitViewControllerChild,
					let index = viewControllers.firstIndex(where: { item in viewController == item }) else {
			return
		}

		viewControllers.remove(at: index)

		if viewControllers.isEmpty {
			// All view controllers in the split have been removed, so remove ourselves.
			if let parentSplitView = parent as? TerminalSplitViewController {
				parentSplitView.remove(viewController: self)
			} else if let rootViewController = parent as? RootViewController {
				rootViewController.removeTerminal(viewController: self)
			}
		}
		updateViewControllers()
	}

	private func updateConstraints() {
		let totalSpace: CGFloat
		switch axis {
		case .horizontal: totalSpace = stackView.frame.size.width - 10
		case .vertical:   totalSpace = stackView.frame.size.height - 10
		@unknown default: fatalError()
		}

		for (i, constraint) in constraints.enumerated() {
			constraint.constant = totalSpace * CGFloat(splitPercentages[i])
		}
	}

	private func updateIsSplitViewResizing() {
		// A parent split view is resizing. Let our children know.
		for viewController in viewControllers {
			viewController.isSplitViewResizing = isSplitViewResizing
		}
	}

	private func updateShowsTitleView() {
		// A parent split view wants title views. Let our children know.
		for viewController in viewControllers {
			viewController.showsTitleView = showsTitleView
		}
	}

	// MARK: - Keyboard

	@objc func keyboardVisibilityChanged(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
					let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
					let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
					let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
			return
		}

		// We do this to avoid the scroll indicator from appearing as soon as the terminal appears.
		// We only want to see it after the keyboard has appeared.
//		if !hasAppeared {
//			hasAppeared = true
//			textView.showsVerticalScrollIndicator = true
//
//			if let error = failureError {
//				// Try to handle the error again now that the UI is ready.
//				didReceiveError(error: error)
//				failureError = nil
//			}
//		}

		switch notification.name {
		case UIResponder.keyboardWillShowNotification: keyboardVisible = true
		case UIResponder.keyboardDidHideNotification:  keyboardVisible = false
		default: break
		}

		// Hide toolbar popups if visible
//		keyInput.setMoreRowVisible(false, animated: true)

		// Determine the final keyboard height. We still get a height if hiding, so force it to 0 if
		// this isn’t a show notification.
		keyboardHeight = keyboardVisible && notification.name != UIResponder.keyboardWillHideNotification ? keyboardFrame.size.height : 0

		// We update the safe areas in an animation block to force it to be animated with the exact
		// parameters given to us in the notification.
		var options: UIView.AnimationOptions = .beginFromCurrentState
		options.insert(.init(rawValue: curve << 16))

		UIView.animate(withDuration: animationDuration,
									 delay: 0,
									 options: options) {
			let bottomInset = self.parent?.view.safeAreaInsets.bottom ?? 0
			self.additionalSafeAreaInsets.bottom = max(bottomInset, self.keyboardHeight - bottomInset)
		}
	}

}

extension TerminalSplitViewController: TerminalSplitViewControllerDelegate {

	func terminal(viewController: BaseTerminalSplitViewControllerChild, titleDidChange title: String) {
		guard let index = viewControllers.firstIndex(of: viewController),
					selectedIndex == index else {
			return
		}

		self.title = title

		if let parent = parent as? TerminalSplitViewControllerDelegate {
			parent.terminal(viewController: self, titleDidChange: title)
		} else if let parent = parent as? BaseTerminalSplitViewControllerChild {
			parent.delegate?.terminal(viewController: self, titleDidChange: title)
		}
	}

	func terminal(viewController: BaseTerminalSplitViewControllerChild, screenSizeDidChange screenSize: ScreenSize) {
		guard let index = viewControllers.firstIndex(of: viewController),
					selectedIndex == index else {
			return
		}

		self.screenSize = screenSize

		if let parent = parent as? TerminalSplitViewControllerDelegate {
			parent.terminal(viewController: self, screenSizeDidChange: screenSize)
		} else if let parent = parent as? BaseTerminalSplitViewControllerChild {
			parent.delegate?.terminal(viewController: self, screenSizeDidChange: screenSize)
		}
	}

	func terminalDidBecomeActive(viewController: BaseTerminalSplitViewControllerChild) {
		guard let index = viewControllers.firstIndex(of: viewController) else {
			return
		}

		selectedIndex = index

		if let parent = parent as? TerminalSplitViewControllerDelegate {
			parent.terminalDidBecomeActive(viewController: self)
		} else if let parent = parent as? BaseTerminalSplitViewControllerChild {
			parent.delegate?.terminalDidBecomeActive(viewController: self)
		}
	}

}

extension TerminalSplitViewController: SplitGrabberViewDelegate {

	func splitGrabberViewDidBeginDragging(_ splitGrabberView: SplitGrabberView) {
		oldSplitPercentages = splitPercentages

		for viewController in viewControllers {
			viewController.isSplitViewResizing = true
		}
	}

	func splitGrabberView(_ splitGrabberView: SplitGrabberView, splitDidChange delta: CGFloat) {
		let totalSpace: CGFloat
		switch axis {
		case .horizontal: totalSpace = stackView.frame.size.width
		case .vertical:   totalSpace = stackView.frame.size.height
		@unknown default: fatalError()
		}

		let percentage = Double(delta / totalSpace)
		let firstSplit = max(0.15, min(0.85, oldSplitPercentages[0] + percentage))
		let secondSplit = 1 - firstSplit

		var didSnap = false
		for point in Self.splitSnapPoints {
			if firstSplit > point - 0.02 && firstSplit < point + 0.02 {
				splitPercentages[0] = point
				splitPercentages[1] = 1 - point
				didSnap = true
				break
			}
		}

		if !didSnap {
			splitPercentages[0] = firstSplit
			splitPercentages[1] = secondSplit
		}

		UIView.animate(withDuration: 0.2) {
			self.updateConstraints()
		}
	}

	func splitGrabberViewDidCommit(_ splitGrabberView: SplitGrabberView) {
		oldSplitPercentages.removeAll()

		for viewController in viewControllers {
			viewController.isSplitViewResizing = false
		}
	}

	func splitGrabberViewDidCancel(_ splitGrabberView: SplitGrabberView) {
		splitPercentages = oldSplitPercentages
		updateConstraints()

		for viewController in viewControllers {
			viewController.isSplitViewResizing = false
		}
	}

}
