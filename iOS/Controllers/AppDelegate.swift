//
//  AppDelegate.swift
//  NewTerm
//
//  Created by Adam Demasi on 8/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

// wen rels kirb!!!
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		if #available(iOS 13, *) {
			// No need for any of this. Yay!
		} else {
			UINavigationBar.appearance().barStyle = .black
			UIToolbar.appearance().barStyle = .black

			UITableView.appearance().backgroundColor = .legacyBackground
			UITableViewCell.appearance().backgroundColor = .legacyBackground

			UINavigationBar.appearance().titleTextAttributes = [
				.foregroundColor: UIColor.legacyText
			]

			UITextField.appearance().textColor = .legacyText
			UITextField.appearance().keyboardAppearance = .dark
			UITableView.appearance().separatorColor = .legacySeparator
		}

		UIScrollView.appearance().keyboardDismissMode = .interactive

		if #available(iOS 13, *) {
			// Handled by UISceneSession lifecycle methods below
		} else {
			window = UIWindow(frame: UIScreen.main.bounds)
			window!.tintColor = .tint
			window!.rootViewController = UINavigationController(rootViewController: RootViewController())
			window!.makeKeyAndVisible()
		}

		_ = Preferences.shared

		return true
	}

	// MARK: - UISceneSession Lifecycle

	@available(iOS 13.0, *)
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Terminal", sessionRole: connectingSceneSession.role)
	}

}

