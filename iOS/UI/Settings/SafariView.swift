//
//  SafariView.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 4/17/21.
//

import SwiftUI
import SafariServices

public struct SafariView {

	public typealias Configuration = SFSafariViewController.Configuration
	public typealias DismissButtonStyle = SFSafariViewController.DismissButtonStyle

	// MARK: - Representation Properties

	let url: URL
	let configuration: Configuration

	public init(url: URL, configuration: Configuration = .init()) {
		self.url = url
		self.configuration = configuration
	}

	// MARK: - Modifiers

	var preferredBarTintColor: UIColor?
	var preferredControlTintColor: UIColor?
	var dismissButtonStyle: DismissButtonStyle = .done

	@available(iOS 14, *)
	public func preferredBarAccentColor(_ color: Color?) -> Self {
		var modified = self
		if let color = color {
			modified.preferredBarTintColor = UIColor(color)
		} else {
			modified.preferredBarTintColor = nil
		}
		return modified
	}

	@available(iOS 14, *)
	public func preferredControlAccentColor(_ color: Color?) -> Self {
		var modified = self
		if let color = color {
			modified.preferredControlTintColor = UIColor(color)
		} else {
			modified.preferredControlTintColor = nil
		}
		return modified
	}

	@available(iOS, introduced: 13.0, deprecated: 14.0, renamed: "preferredBarAccentColor(_:)")
	public func preferredBarTintColor(_ color: UIColor?) -> Self {
		var modified = self
		modified.preferredBarTintColor = color
		return modified
	}

	@available(iOS, introduced: 13.0, deprecated: 14.0, renamed: "preferredControlAccentColor(_:)")
	public func preferredControlTintColor(_ color: UIColor?) -> Self {
		var modified = self
		modified.preferredControlTintColor = color
		return modified
	}

	public func dismissButtonStyle(_ style: DismissButtonStyle) -> Self {
		var modified = self
		modified.dismissButtonStyle = style
		return modified
	}

	// MARK: - Modification Applier

	func applyModification(to safariViewController: SFSafariViewController) {
		safariViewController.preferredBarTintColor = self.preferredBarTintColor
		safariViewController.preferredControlTintColor = self.preferredControlTintColor
		safariViewController.dismissButtonStyle = self.dismissButtonStyle
	}

}

public extension SafariView.Configuration {

	convenience init(entersReaderIfAvailable: Bool = false, barCollapsingEnabled: Bool = true) {
		self.init()
		self.entersReaderIfAvailable = entersReaderIfAvailable
		self.barCollapsingEnabled = barCollapsingEnabled
	}

}


extension SafariView: View {

	public var body: some View {
		Representable(parent: self)
			.edgesIgnoringSafeArea(.all)
	}

	@available(iOS 14.0, *)
	public func accentColor(_ accentColor: Color?) -> Self {
		return self.preferredControlAccentColor(accentColor)
	}

}

extension SafariView {
	struct Representable: UIViewControllerRepresentable {

		// MARK: - Parent Copying

		private var parent: SafariView

		init(parent: SafariView) {
			self.parent = parent
		}

		// MARK: - UIViewControllerRepresentable

		func makeUIViewController(context: Context) -> SFSafariViewController {
			let safariViewController = SFSafariViewController(
				url: parent.url,
				configuration: parent.configuration
			)
			// Disable interactive pop gesture recognizer
			safariViewController.modalPresentationStyle = .none
			parent.applyModification(to: safariViewController)
			return safariViewController
		}

		func updateUIViewController(_ safariViewController: SFSafariViewController, context: Context) {
			parent.applyModification(to: safariViewController)
		}

	}
}

struct SafariViewPresentationModifier: ViewModifier {

	@Binding var isPresented: Bool
	var onDismiss: (() -> Void)? = nil
	var representationBuilder: () -> SafariView

	private var item: Binding<Bool?> {
		.init(
			get: { self.isPresented ? true : nil },
			set: { self.isPresented = ($0 != nil) }
		)
	}

	private func itemRepresentationBuilder(bool: Bool) -> SafariView {
		return representationBuilder()
	}

	func body(content: Content) -> some View {
		content.background(
			SafariViewPresenter(
				onDismiss: onDismiss
			)
		)
	}

}

struct ItemSafariViewPresentationModifier: ViewModifier {

	var onDismiss: (() -> Void)? = nil
//	var representationBuilder: (Item) -> SafariView

	func body(content: Content) -> some View {
		content.background(
			SafariViewPresenter(
				onDismiss: onDismiss
//				representationBuilder: representationBuilder
			)
		)
	}

}

struct SafariViewPresenter: UIViewControllerRepresentable {

	// MARK: - Representation
	var onDismiss: (() -> Void)? = nil
//	var representationBuilder: (Item) -> SafariView

	// MARK: - UIViewControllerRepresentable

	func makeCoordinator() -> Coordinator {
		return Coordinator(parent: self)
	}

	func makeUIViewController(context: Context) -> UIViewController {
		return context.coordinator.uiViewController
	}

	func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
		context.coordinator.parent = self
	}

}

extension SafariViewPresenter {
	class Coordinator: NSObject, SFSafariViewControllerDelegate {

		// MARK: - Parent Copying

		var parent: SafariViewPresenter

		init(parent: SafariViewPresenter) {
			self.parent = parent
		}

		// MARK: - View Controller Holding

		let uiViewController = UIViewController()

		private func dismissSafariViewController(completion: (() -> Void)? = nil) {
			let dismissCompletion: () -> Void = {
				self.handleDismissalWithoutResettingItemBinding()
				completion?()
			}

			guard uiViewController.presentedViewController != nil else {
				dismissCompletion()
				return
			}

			guard let safariViewController = uiViewController.presentedViewController as? SFSafariViewController else {
				return
			}
			safariViewController.dismiss(animated: true, completion: dismissCompletion)
		}

		// MARK: - Dismissal Handlers

		private func handleDismissalWithoutResettingItemBinding() {
			parent.onDismiss?()
		}

		private func resetItemBindingAndHandleDismissal() {
			parent.onDismiss?()
		}

		// MARK: - SFSafariViewControllerDelegate

		func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
			resetItemBindingAndHandleDismissal()
		}

	}
}
