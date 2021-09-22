//
//  TerminalSceneDelegate.swift
//  NewTerm
//
//  Created by Adam Demasi on 16/6/19.
//  Copyright © 2019 HASHBANG Productions. All rights reserved.
//

import UIKit
import NewTermCommon

class TerminalSceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	override init() {
		super.init()

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
	}

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}

		window = UIWindow(windowScene: windowScene)
		window!.tintColor = .tint
		window!.rootViewController = UINavigationController(rootViewController: RootViewController())
		window!.makeKeyAndVisible()

		scene.title = .localize("TERMINAL", comment: "Generic title displayed before the terminal sets a proper title.")

		#if targetEnvironment(macCatalyst)
		windowScene.titlebar?.separatorStyle = .none
		#endif

		preferencesUpdated()
	}

	// MARK: - Window management

	func createWindow(asTab: Bool) {
		let options = UIScene.ActivationRequestOptions()
		#if targetEnvironment(macCatalyst)
		if asTab {
			options.requestingScene = window!.windowScene
		}
		options.collectionJoinBehavior = asTab ? .preferred : .disallowed
		#else
		options.requestingScene = window!.windowScene
		#endif
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: options, errorHandler: nil)
	}

	@objc func removeWindow() {
		UIApplication.shared.requestSceneSessionDestruction(window!.windowScene!.session, options: nil, errorHandler: nil)
	}

	// MARK: - Preferences

	@objc private func preferencesUpdated() {
		let preferences = Preferences.shared
		window?.overrideUserInterfaceStyle = preferences.userInterfaceStyle
	}

	// MARK: - Updates

	func handleUpdateAvailable(_ response: UpdateCheckResponse) {
		guard let viewController = window?.rootViewController else {
			return
		}

		let infoPlist = Bundle.main.infoDictionary!
		let appVersion = infoPlist["CFBundleShortVersionString"] as! String

		let alertController = UIAlertController(title: "Update Available",
																						message: "Version \(response.versionString) is available to install. You’re currently using version \(appVersion).",
																						preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
		alertController.addAction(UIAlertAction(title: "Download", style: .default, handler: { _ in
			UIApplication.shared.open(URL(string: response.url)!, options: [:], completionHandler: nil)
		}))
		viewController.present(alertController, animated: true, completion: nil)
	}

}
