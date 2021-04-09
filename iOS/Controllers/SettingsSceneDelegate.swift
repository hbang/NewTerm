//
//  SettingsSceneDelegate.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 9/4/21.
//

import UIKit
import SwiftUI

class SettingsSceneDelegate: UIResponder, UIWindowSceneDelegate {

	static let activityType = "ws.hbang.Terminal.SettingsSceneActivity"

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}

		window = UIWindow(windowScene: windowScene)
		window!.tintColor = .tint
		window!.rootViewController = UIHostingController(rootView: SettingsView(windowScene: windowScene))
		window!.makeKeyAndVisible()

		#if targetEnvironment(macCatalyst)
		windowScene.title = NSLocalizedString("SETTINGS_MAC", comment: "Title of Settings page on macOS (where Settings is usually named Preferences).")
		#else
		windowScene.title = NSLocalizedString("SETTINGS", comment: "Title of Settings page.")
		#endif

		windowScene.sizeRestrictions?.minimumSize = CGSize(width: 600, height: 500)
		windowScene.sizeRestrictions?.maximumSize = CGSize(width: 600, height: 500)

		#if targetEnvironment(macCatalyst)
		windowScene.titlebar?.titleVisibility = .hidden
		#endif
	}

}
