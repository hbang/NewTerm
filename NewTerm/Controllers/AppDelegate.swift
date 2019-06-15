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
		let tintColor = UIColor(red: 76 / 255, green: 161 / 255, blue: 1, alpha: 1)
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
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}

}

