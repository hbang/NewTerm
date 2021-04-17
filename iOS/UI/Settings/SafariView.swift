//
//  SafariView.swift
//  NewTerm (iOS)
//
//  Created by Chris Harper on 4/17/21.
//

#if os(iOS)

import SwiftUI
import SafariServices

extension Bool: Identifiable {
    public var id: Bool { self }
}

extension URL: Identifiable {
    public var id: String { self.absoluteString }
}

public struct SafariView {
    
    public typealias Configuration = SFSafariViewController.Configuration
    public typealias DismissButtonStyle = SFSafariViewController.DismissButtonStyle
    
    // MARK: Representation Properties
    
    let url: URL
    let configuration: Configuration

    public init(url: URL, configuration: Configuration = .init()) {
        self.url = url
        self.configuration = configuration
    }
    
    // MARK: Modifiers
    
    var preferredBarTintColor: UIColor?
    var preferredControlTintColor: UIColor?
    var dismissButtonStyle: DismissButtonStyle = .done
    
    // There is a bug on Xcode 12.0 (Swift 5.3.0) where `UIColor.init(_ color: Color)` is missing for Mac Catalyst target.
    #if compiler(>=5.3.1) || (compiler(>=5.3) && !targetEnvironment(macCatalyst))

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
    
    #endif
    
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
    
    // MARK: Modification Applier
    
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
    
    // There is a bug on Xcode 12.0 (Swift 5.3.0) where `ignoresSafeArea(_:edges:)` is missing for Mac Catalyst target.
    #if compiler(>=5.3.1) || (compiler(>=5.3) && !targetEnvironment(macCatalyst))

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
    
    #else
    
    public var body: some View {
        Representable(parent: self)
            .edgesIgnoringSafeArea(.all)
    }
    
    #endif
}

extension SafariView {
    
    struct Representable: UIViewControllerRepresentable {
        
        // MARK: Parent Copying
        
        private var parent: SafariView
        
        init(parent: SafariView) {
            self.parent = parent
        }
        
        // MARK: UIViewControllerRepresentable
        
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
    
    func safariView(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        content representationBuilder: @escaping () -> SafariView
    ) -> some View {
        self.modifier(
            SafariViewPresentationModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                representationBuilder: representationBuilder
            )
        )
    }
    
    func safariView<Item: Identifiable>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        content representationBuilder: @escaping (Item) -> SafariView
    ) -> some View {
        self.modifier(
            ItemSafariViewPresentationModifier(
                item: item,
                onDismiss: onDismiss,
                representationBuilder: representationBuilder
            )
        )
    }
}

struct SafariViewPresenter<Item: Identifiable>: UIViewControllerRepresentable {
    
    // MARK: Representation
    
    @Binding var item: Item?
    var onDismiss: (() -> Void)? = nil
    var representationBuilder: (Item) -> SafariView
    
    // MARK: UIViewControllerRepresentable
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        return context.coordinator.uiViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
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
        
        // MARK: View Controller Holding
        
        let uiViewController = UIViewController()
        
        // MARK: Item Handling
        
        var item: Item? {
            didSet(oldItem) {
                handleItemChange(from: oldItem, to: item)
            }
        }
        
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
        
        // MARK: Presentation Handlers
        
        private func presentSafariViewController(with item: Item) {
            guard uiViewController.presentedViewController == nil else {
                return
            }
            
            let representation = parent.representationBuilder(item)
            let safariViewController = SFSafariViewController(url: representation.url, configuration: representation.configuration)
            safariViewController.delegate = self
            representation.applyModification(to: safariViewController)
            
            var presentingViewController = uiViewController.view.window?.rootViewController
            presentingViewController = presentingViewController?.presentedViewController ?? presentingViewController ?? uiViewController
            presentingViewController?.present(safariViewController, animated: true)
        }
        
        private func updateSafariViewController(with item: Item) {
            guard let safariViewController = uiViewController.presentedViewController as? SFSafariViewController else {
                return
            }
            let representation = parent.representationBuilder(item)
            representation.applyModification(to: safariViewController)
        }
        
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
        
        // MARK: Dismissal Handlers
        
        private func handleDismissalWithoutResettingItemBinding() {
            parent.onDismiss?()
        }
        
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

#endif
