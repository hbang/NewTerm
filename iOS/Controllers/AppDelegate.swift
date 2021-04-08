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
		UIScrollView.appearance().keyboardDismissMode = .interactive

		FontMetrics.loadFonts()
		_ = Preferences.shared

		return true
	}

	// MARK: - UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Terminal", sessionRole: connectingSceneSession.role)
	}

	// MARK: - Catalyst

	override func buildMenu(with builder: UIMenuBuilder) {
		super.buildMenu(with: builder)

		// Remove Edit menu text editing items
		builder.remove(menu: .spelling)
		builder.remove(menu: .substitutions)
		builder.remove(menu: .transformations)

		// Remove Format menu
		builder.remove(menu: .format)

		// Remove View menu toolbar items
		builder.remove(menu: .toolbar)

		// Add Preferences item
		let preferences = NSLocalizedString("MACMENUITEM_APP_PREFS", bundle: .uikit, comment: "")
		builder.insertSibling(UIMenu(options: .displayInline,
																 children: [
																	UIKeyCommand(title: preferences,
																							 action: #selector(RootViewController.openSettings),
																							 input: ",",
																							 modifierFlags: .command)
																 ]),
													afterMenu: .about)
	}

}

