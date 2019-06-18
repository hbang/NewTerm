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
		let textColor = UIColor.white
		let backgroundColor = UIColor(white: 26 / 255, alpha: 1)
		let lightTintColor = UIColor(white: 60 / 255, alpha: 1)

		UINavigationBar.appearance().barStyle = .black
		UIToolbar.appearance().barStyle = .black

		UITableView.appearance().backgroundColor = backgroundColor
		UITableViewCell.appearance().backgroundColor = backgroundColor
		// this is deprecated but apple doesn’t exactly provide an easy, supported way to do this
		// TODO: ew, swift doesn’t allow setting pre-ios 7 deprecated methods at all
		// UITableViewCell.appearance().textColor = textColor

		UINavigationBar.appearance().titleTextAttributes = [
			.foregroundColor: textColor
		]

		UITextField.appearance().textColor = textColor
		UITextField.appearance().keyboardAppearance = .dark
		UITableView.appearance().separatorColor = lightTintColor

		UIScrollView.appearance().keyboardDismissMode = .interactive

		_ = Preferences.shared

		return true
	}

	// MARK: - UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Terminal", sessionRole: connectingSceneSession.role)
	}

}

