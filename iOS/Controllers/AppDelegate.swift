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
		let tintColor = UIColor(red: 76 / 255, green: 161 / 255, blue: 1, alpha: 1)

		if #available(iOS 13, *) {
			// No need for any of this. Yay!
		} else {
			let textColor = UIColor.white
			let backgroundColor = UIColor(white: 26 / 255, alpha: 1)
			let lightTintColor = UIColor(white: 60 / 255, alpha: 1)

			UINavigationBar.appearance().barStyle = .black
			UIToolbar.appearance().barStyle = .black

			UITableView.appearance().backgroundColor = backgroundColor
			UITableViewCell.appearance().backgroundColor = backgroundColor

			UINavigationBar.appearance().titleTextAttributes = [
				.foregroundColor: textColor
			]

			UITextField.appearance().textColor = textColor
			UITextField.appearance().keyboardAppearance = .dark
			UITableView.appearance().separatorColor = lightTintColor
		}

		UIScrollView.appearance().keyboardDismissMode = .interactive

		if #available(iOS 13, *) {
			// Handled by UISceneSession lifecycle methods below
		} else {
			window = UIWindow(frame: UIScreen.main.bounds)
			window!.tintColor = tintColor
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

