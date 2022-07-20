//
//  TerminalSceneDelegate.swift
//  NewTerm
//
//  Created by Adam Demasi on 16/6/19.
//  Copyright © 2019 HASHBANG Productions. All rights reserved.
//

import UIKit
import NewTermCommon

extension NSUserActivity {
	static let terminalScene = NSUserActivity(activityType: TerminalSceneDelegate.activityType)
}

class TerminalSceneDelegate: UIResponder, UIWindowSceneDelegate, IdentifiableSceneDelegate {

	static let activityType = "ws.hbang.Terminal.TerminalSceneActivity"

	var window: UIWindow?

	private var rootViewController: RootViewController! {
		(window?.rootViewController as? UINavigationController)?.viewControllers.first as? RootViewController
	}

	override init() {
		super.init()

		NotificationCenter.default.addObserver(self, selector: #selector(preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
	}

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let scene = scene as? UIWindowScene else {
			return
		}

		window = UIWindow(windowScene: scene)
		window!.tintColor = .tint
		window!.rootViewController = UINavigationController(rootViewController: RootViewController())
		window!.makeKeyAndVisible()

		scene.title = .localize("TERMINAL", comment: "Generic title displayed before the terminal sets a proper title.")

		#if targetEnvironment(macCatalyst)
		scene.titlebar?.separatorStyle = .none
		scene.titlebar?.toolbarStyle = .unifiedCompact
		#endif

		preferencesUpdated()
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		for context in URLContexts {
			let url = context.url
			switch url.scheme {
			case "ssh":
				createWindow(asTab: true, openingURL: url)

			default: break
			}
		}
	}

	// MARK: - Window management

	func createWindow(asTab: Bool, openingURL url: URL? = nil) {
		// Handle SSH URL
		var sshPayload: String?
		if let url = url,
			 let host = url.host,
			 url.scheme == "ssh" {
			sshPayload = host
			if let user = url.user {
				sshPayload = "\(user)@\(host)"
			}
			let port = url.port ?? 22
			if port != 22 {
				sshPayload = "\(sshPayload!) -p \(port)"
			}
		}

		if UIApplication.shared.supportsMultipleScenes {
			let options = UIScene.ActivationRequestOptions()
			#if targetEnvironment(macCatalyst)
			if asTab {
				options.requestingScene = window!.windowScene
			}
			options.collectionJoinBehavior = asTab ? .preferred : .disallowed
			#else
			options.requestingScene = window!.windowScene
			#endif

			let activity = NSUserActivity(activityType: Self.activityType)
			activity.userInfo = [:]
			activity.userInfo!["sshPayload"] = sshPayload

			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: options, errorHandler: nil)
		} else {
			if let sshPayload = sshPayload {
				rootViewController.initialCommand = "ssh \(sshPayload)"
			}
			rootViewController.addTerminal()
		}
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
