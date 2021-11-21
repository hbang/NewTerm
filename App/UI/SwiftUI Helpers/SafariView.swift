//
//  SafariView.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 11/20/21.
//

#if os(iOS)

import SwiftUI
import SafariServices

public struct SafariView {
	public typealias Configuration = SFSafariViewController.Configuration
	public typealias DismissButtonStyle = SFSafariViewController.DismissButtonStyle
	
	public enum PresentationMode {
		case navigationLink
		case sheet
	}
	
	let url: URL
	let configuration: Configuration
	
	public init(url: URL, configuration: Configuration = .init()) {
		self.url = url
		self.configuration = configuration
	}
	
	var preferredBarTintColor: UIColor?
	var preferredControlTintColor: UIColor?
	var dismissButtonStyle: DismissButtonStyle = .done
	
	@available(iOS 14.0, *)
	public func preferredBarAccentColor(_ color: Color?) -> Self {
		var modified = self
		if let color = color {
			modified.preferredBarTintColor = UIColor(color)
		} else {
			modified.preferredBarTintColor = nil
		}
		return modified
	}
	
	@available(iOS 14.0, *)
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
		if #available(iOS 14.0, *) {
			Representable(parent: self)
				.ignoresSafeArea(.container, edges: .all)
		} else {
			Representable(parent: self)
				.edgesIgnoringSafeArea(.all)
		}
	}
	@available(iOS 14.0, *)
	public func accentColor(_ accentColor: Color?) -> Self {
		return self.preferredControlAccentColor(accentColor)
	}
}

extension SafariView {
	
	struct Representable: UIViewControllerRepresentable {
		private var parent: SafariView
		
		init(parent: SafariView) {
			self.parent = parent
		}
		
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

struct SafariViewPresenter<Item: Identifiable>: UIViewRepresentable {
	@Binding var item: Item?
	var onDismiss: (() -> Void)? = nil
	var representationBuilder: (Item) -> SafariView
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(parent: self)
	}
	
	func makeUIView(context: Context) -> UIView {
		return context.coordinator.uiView
	}
	
	func updateUIView(_ uiView: UIView, context: Context) {
		context.coordinator.parent = self
		context.coordinator.item = item
	}
}

extension SafariViewPresenter {
	
	class Coordinator: NSObject, SFSafariViewControllerDelegate {
		
		// MARK: Parent Copying
		
		var parent: SafariViewPresenter
		
		init(parent: SafariViewPresenter) {
			self.parent = parent
		}
		
		let uiView = UIView()
		private weak var safariViewController: SFSafariViewController?
		
		var item: Item? {
			didSet(oldItem) {
				handleItemChange(from: oldItem, to: item)
			}
		}
		
		// Ensure the proper presentation handler is executed only once
		// during a one SwiftUI view update life cycle.
		private func handleItemChange(from oldItem: Item?, to newItem: Item?) {
			switch (oldItem, newItem) {
				case (.none, .none):
					()
				case let (.none, .some(newItem)):
					presentSafariViewController(with: newItem)
				case let (.some(oldItem), .some(newItem)) where oldItem.id != newItem.id:
					dismissSafariViewController() {
						self.presentSafariViewController(with: newItem)
					}
				case let (.some, .some(newItem)):
					updateSafariViewController(with: newItem)
				case (.some, .none):
					dismissSafariViewController()
			}
		}
		
		private func presentSafariViewController(with item: Item) {
			let representation = parent.representationBuilder(item)
			let safariViewController = SFSafariViewController(url: representation.url, configuration: representation.configuration)
			safariViewController.delegate = self
			representation.applyModification(to: safariViewController)
			
			// Present a Safari view controller from the `viewController` of `UIViewRepresentable`, instead of `UIViewControllerRepresentable`.
			// This fixes an issue where the Safari view controller is not presented properly
			// when the `UIViewControllerRepresentable` is detached from the root view controller (e.g. `UIViewController` contained in `UITableViewCell`)
			// while allowing it to be presented even on the modal sheets.
			// Thanks to: Bohdan Hernandez Navia (@boherna)
			guard let presentingViewController = uiView.viewController else {
				self.resetItemBinding()
				return
			}
			
			presentingViewController.present(safariViewController, animated: true)
			
			self.safariViewController = safariViewController
		}
		
		private func updateSafariViewController(with item: Item) {
			guard let safariViewController = safariViewController else {
				return
			}
			let representation = parent.representationBuilder(item)
			representation.applyModification(to: safariViewController)
		}
		
		private func dismissSafariViewController(completion: (() -> Void)? = nil) {
			guard let safariViewController = safariViewController else {
				return
			}
			
			safariViewController.dismiss(animated: true) {
				self.handleDismissal()
				completion?()
			}
		}
		
		// MARK: Dismissal Handlers
		
		// Used when the `viewController` of `uiView` does not exist during the preparation of presentation.
		private func resetItemBinding() {
			parent.item = nil
		}
		
		// Used when the Safari view controller is finished by an item change during view update.
		private func handleDismissal() {
			parent.onDismiss?()
		}
		
		// Used when the Safari view controller is finished by a user interaction.
		private func resetItemBindingAndHandleDismissal() {
			parent.item = nil
			parent.onDismiss?()
		}
		
		// MARK: SFSafariViewControllerDelegate
		
		func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
			resetItemBindingAndHandleDismissal()
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
	
	// Converts `() -> Void` closure to `(Bool) -> Void`
	private func itemRepresentationBuilder(bool: Bool) -> SafariView {
		return representationBuilder()
	}
	
	func body(content: Content) -> some View {
		content.background(
			SafariViewPresenter(
				item: item,
				onDismiss: onDismiss,
				representationBuilder: itemRepresentationBuilder
			)
		)
	}
}

struct ItemSafariViewPresentationModifier<Item: Identifiable>: ViewModifier {
	@Binding var item: Item?
	var onDismiss: (() -> Void)? = nil
	var representationBuilder: (Item) -> SafariView
	
	func body(content: Content) -> some View {
		content.background(
			SafariViewPresenter(
				item: $item,
				onDismiss: onDismiss,
				representationBuilder: representationBuilder
			)
		)
	}
}


public extension View {
	func safariView<Item: Identifiable>(item: Binding<Item?>, presentationMode: SafariView.PresentationMode = .navigationLink, url: URL, configuration: SafariView.Configuration, onDismiss: (() -> Void)? = nil) -> some View {
		switch presentationMode {
			case .sheet:
				return AnyView(self.sheet(item: item, onDismiss: onDismiss) {_ in
					SafariView(url: url, configuration: configuration)
				})
			case .navigationLink:
				return AnyView(self.modifier(ItemSafariViewPresentationModifier(item: item, onDismiss: onDismiss, representationBuilder: { _ in
					SafariView(url: url, configuration: configuration)
				})))
		}
	}
	
	func safariView(isPresented: Binding<Bool>, presentationMode: SafariView.PresentationMode = .navigationLink, url: URL, configuration: SafariView.Configuration, onDismiss: (() -> Void)? = nil) -> some View {
		switch presentationMode {
			case .sheet:
				return AnyView(self.sheet(isPresented: isPresented) {
					SafariView(url: url, configuration: configuration)
				})
			case .navigationLink:
				return AnyView(self.modifier(SafariViewPresentationModifier(isPresented: isPresented, onDismiss: onDismiss, representationBuilder: {
					SafariView(url: url, configuration: configuration)
				})))
		}
	}
}

extension UIView {
	var viewController: UIViewController? {
		if let nextResponder = self.next as? UIViewController {
			return nextResponder
		} else if let nextResponder = self.next as? UIView {
			return nextResponder.viewController
		} else {
			return nil
		}
	}
}

extension Bool: Identifiable {
	public var id: Bool { self }
}

extension URL: Identifiable {
	public var id: String { self.absoluteString }
}

#endif

