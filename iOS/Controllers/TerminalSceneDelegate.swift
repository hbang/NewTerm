//
//  TerminalSceneDelegate.swift
//  NewTerm
//
//  Created by Adam Demasi on 16/6/19.
//  Copyright © 2019 HASHBANG Productions. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class TerminalSceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		let tintColor = UIColor(red: 76 / 255, green: 161 / 255, blue: 1, alpha: 1)
		
		if let windowScene = scene as? UIWindowScene {
			window = UIWindow(frame: UIScreen.main.bounds)
			window!.windowScene = windowScene
			window!.tintColor = tintColor
			window!.rootViewController = UINavigationController(rootViewController: RootViewController())
			window!.makeKeyAndVisible()
		}
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

}

