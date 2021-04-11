//
//  TerminalSplitViewController.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 10/4/21.
//

import UIKit

class TerminalSplitViewController: UIViewController {

	var viewControllers: [UIViewController]! {
		didSet { updateViewControllers() }
	}
	var axis: NSLayoutConstraint.Axis = .horizontal {
		didSet { stackView.axis = axis }
	}

	private let stackView = UIStackView()
	private var splitPercentages = [Double]()
	private var constraints = [NSLayoutConstraint]()

	private var keyboardVisible = false
	private var keyboardHeight: CGFloat = 0

	private var titleObservers = [NSKeyValueObservation]()

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

		for (i, viewController) in viewControllers.enumerated() {
			let containerView = UIView()
			containerView.translatesAutoresizingMaskIntoConstraints = false

			addChild(viewController)
			viewController.view.frame = containerView.bounds
			viewController.view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
			containerView.addSubview(viewController.view)
			stackView.addArrangedSubview(containerView)
			viewController.didMove(toParent: self)

			if i != viewControllers.count - 1 {
				let splitGrabberView = SplitGrabberView(axis: axis)
				splitGrabberView.translatesAutoresizingMaskIntoConstraints = false
				stackView.addArrangedSubview(splitGrabberView)
			}
		}

		if splitPercentages.count != viewControllers.count {
			let split = Double(1) / Double(viewControllers.count)
			splitPercentages = Array(repeating: split, count: viewControllers.count)
		}

		if titleObservers.count != viewControllers.count {
			titleObservers = viewControllers.map { viewController in
				viewController.observe(\.title, changeHandler: { viewController, _ in
					// TODO
					self.title = viewController.title
				})
			}
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

//		UIView.animate(withDuration: 0.5) {
//			self.view.layoutIfNeeded()
//		}
	}

	func remove(viewController: UIViewController) {
		guard let index = viewControllers.firstIndex(of: viewController) else {
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

	// MARK: - Keyboard

	@objc func keyboardVisibilityChanged(_ notification: Notification) {
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

		if notification.name == UIResponder.keyboardWillShowNotification {
			keyboardVisible = true
		} else if notification.name == UIResponder.keyboardDidHideNotification {
			keyboardVisible = false
		}

		// Hide toolbar popups if visible
//		keyInput.setMoreRowVisible(false, animated: true)

		// Determine the final keyboard height. We still get a height if hiding, so force it to 0 if
		// this isn’t a show notification.
		let keyboardFrame = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
		if keyboardVisible && notification.name != UIResponder.keyboardWillHideNotification && notification.name != UIResponder.keyboardDidHideNotification {
			keyboardHeight = keyboardFrame.size.height
		} else {
			keyboardHeight = 0
		}

		// We update the safe areas in an animation block to force it to be animated with the exact
		// parameters given to us in the notification.
		let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
		UIView.animate(withDuration: animationDuration) {
			let bottomInset = self.parent?.view.safeAreaInsets.bottom ?? 0
			self.additionalSafeAreaInsets.bottom = max(bottomInset, self.keyboardHeight - bottomInset)
		}
	}

}
