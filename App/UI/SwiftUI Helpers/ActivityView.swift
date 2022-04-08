//
//  ActivityView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 16/9/21.
//

import SwiftUI

class ActivityWrapperViewController: UIViewController {

	var isPresented = false
	var activityItems: [Any] = []
	let completion: () -> ()

	private var activityViewController: UIActivityViewController?

	init(completion: @escaping () -> ()) {
		self.completion = completion
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func didMove(toParent parent: UIViewController?) {
		super.didMove(toParent: parent)
		parent?.view.backgroundColor = .clear
	}

	func update() {
		if isPresented && activityViewController == nil {
			// We have to create a new instance every time, otherwise the completion never gets called for
			// subsequent presentations on macOS…
			activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
			activityViewController!.popoverPresentationController?.sourceView = view
			activityViewController!.popoverPresentationController?.sourceRect = CGRect(x: view.center.x,
																																								 y: 0,
																																								 width: 0,
																																								 height: view.frame.size.height)
			activityViewController!.completionWithItemsHandler = { _, _, _, _ in
				self.completion()
			}
			present(activityViewController!, animated: true, completion: nil)
		} else if !isPresented && activityViewController != nil {
			activityViewController?.dismiss(animated: true, completion: nil)
			activityViewController = nil
		}
	}

}

struct ActivityViewControllerRepresentable: UIViewControllerRepresentable {

	@Binding
	var isPresented: Bool

	var activityItems: [Any]

	@Environment(\.presentationMode)
	private var presentationMode

	func makeUIViewController(context: Context) -> ActivityWrapperViewController {
		return ActivityWrapperViewController {
			self.isPresented = false
		}
	}

	func updateUIViewController(_ uiViewController: ActivityWrapperViewController, context: Context) {
		uiViewController.isPresented = isPresented
		uiViewController.activityItems = activityItems
		uiViewController.update()
	}

}

extension View {

	func activityView(isPresented: Binding<Bool>, activityItems: [Any]) -> some View {
		self.background(ActivityViewControllerRepresentable(isPresented: isPresented,
																												activityItems: activityItems))
	}

}
