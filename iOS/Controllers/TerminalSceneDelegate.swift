//
//  TerminalSceneDelegate.swift
//  NewTerm
//
//  Created by Adam Demasi on 16/6/19.
//  Copyright © 2019 HASHBANG Productions. All rights reserved.
//

import UIKit

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

		#if targetEnvironment(macCatalyst)
		windowScene.titlebar?.titleVisibility = .hidden
		windowScene.titlebar?.toolbar = nil
		#endif

		preferencesUpdated()
	}

	// MARK: - Window management

	@IBAction func addWindow() {
		let options = UIWindowScene.ActivationRequestOptions()
		options.requestingScene = window!.windowScene
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: options, errorHandler: nil)
	}

	@IBAction func removeWindow() {
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
