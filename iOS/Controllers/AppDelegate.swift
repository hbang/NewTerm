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

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		UIScrollView.appearance().keyboardDismissMode = .interactive

		FontMetrics.loadFonts()
		_ = Preferences.shared

		UpdateCheckManager.check(updateAvailableCompletion: { response in
			if let scene = application.connectedScenes.first {
				let delegate = scene.delegate as! TerminalSceneDelegate
				delegate.handleUpdateAvailable(response)
			}
		})

		return true
	}

	// MARK: - UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		if let userActivity = options.userActivities.first {
			if userActivity.activityType == SettingsSceneDelegate.activityType {
				return UISceneConfiguration(name: "Settings", sessionRole: connectingSceneSession.role)
			}
		}
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
		builder.insertSibling(UIMenu(options: .displayInline,
																 children: [
																	UIKeyCommand(title: NSLocalizedString("SETTINGS_MAC", comment: "Title of Settings page on macOS (where Settings is usually named Preferences)."),
																							 action: #selector(RootViewController.openSettings),
																							 input: ",",
																							 modifierFlags: .command)
																 ]),
													afterMenu: .about)

		builder.replace(menu: .newScene,
										with: UIMenu(options: .displayInline,
																 children: [
																	UIKeyCommand(title: NSLocalizedString("NEW_WINDOW", comment: "VoiceOver label for the new window button."),
																							 action: #selector(RootViewController.addWindow),
																							 input: "n",
																							 modifierFlags: .command),
																	UIKeyCommand(title: NSLocalizedString("NEW_TAB", comment: "VoiceOver label for the new tab button."),
																							 action: #selector(RootViewController.newTab),
																							 input: "t",
																							 modifierFlags: .command)
																 ]))

		builder.replace(menu: .close,
										with: UIMenu(options: .displayInline,
																 children: [
																	// TODO: Disabling for now, needs research.
																	// Probably need to directly access the NSWindow to do this.
//																	UIKeyCommand(title: NSLocalizedString("CLOSE_WINDOW", comment: "VoiceOver label for the close window button."),
//																							 action: #selector(RootViewController.closeCurrentWindow),
//																							 input: "w",
//																							 modifierFlags: [ .command, .shift ]),
																	UIKeyCommand(title: NSLocalizedString("CLOSE_TAB", comment: "VoiceOver label for the close tab button."),
																							 action: #selector(RootViewController.removeCurrentTerminal),
																							 input: "w",
																							 modifierFlags: .command)
																 ]))
	}

}

