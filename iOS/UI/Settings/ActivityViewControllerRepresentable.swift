//
//  ActivityViewControllerRepresentable.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 16/9/21.
//

import SwiftUI

class ActivityWrapperViewController: UIViewController {

	var activityViewController: UIActivityViewController
	private var hasPresented = false

	init(activityItems: [Any]) {
		activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func didMove(toParent parent: UIViewController?) {
		super.didMove(toParent: parent)
		parent?.view.backgroundColor = .clear

		if !hasPresented {
			present(activityViewController, animated: true, completion: nil)
			hasPresented = true
		}
	}

}

struct ActivityViewControllerRepresentable: UIViewControllerRepresentable {

	var activityItems: [Any]

	@Environment(\.presentationMode)
	private var presentationMode

	func makeUIViewController(context: Context) -> ActivityWrapperViewController {
		// TODO: Make sure we handle popover style somehow
		let viewController = ActivityWrapperViewController(activityItems: activityItems)
		viewController.activityViewController.completionWithItemsHandler = { _, _, _, _ in
			self.presentationMode.wrappedValue.dismiss()
		}
		return viewController
	}

	func updateUIViewController(_ uiViewController: ActivityWrapperViewController, context: Context) {
		// Unused
	}

}
