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

	private lazy var app = UIApplication.shared

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		UIScrollView.appearance().keyboardDismissMode = .interactive

		FontMetrics.loadFonts()
		_ = Preferences.shared

		UpdateCheckManager.check(updateAvailableCompletion: { response in
			if let scene = application.connectedScenes.first(where: { scene in scene.delegate is TerminalSceneDelegate }) {
				let delegate = scene.delegate as! TerminalSceneDelegate
				delegate.handleUpdateAvailable(response)
			}
		})

		return true
	}

	@objc func openSettings() {
		if app.supportsMultipleScenes {
			app.activateScene(userActivity: .settingsScene)
		}
	}

	@objc func openAbout() {
		if app.supportsMultipleScenes {
			app.activateScene(userActivity: .aboutScene)
		}
	}

	@objc func addWindow() {
		// No windows exist. Make the first one.
		if app.supportsMultipleScenes {
			app.activateScene(userActivity: .terminalScene, asSingleton: false)
		}
	}

	@objc func newTab() {
		// No windows exist. Pass through to addWindow().
		addWindow()
	}

	// MARK: - UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		let userActivity = options.userActivities.first
		switch userActivity?.activityType {
		case SettingsSceneDelegate.activityType:
			return UISceneConfiguration(name: "Settings", sessionRole: .windowApplication)
		case AboutSceneDelegate.activityType:
			return UISceneConfiguration(name: "About", sessionRole: .windowApplication)
		default:
			return UISceneConfiguration(name: "Terminal", sessionRole: .windowApplication)
		}
	}

	// MARK: - Catalyst

	override func buildMenu(with builder: UIMenuBuilder) {
		super.buildMenu(with: builder)

		switch builder.system {
		case .main:
			// Remove Edit menu text editing items
			builder.remove(menu: .spelling)
			builder.remove(menu: .substitutions)
			builder.remove(menu: .transformations)
			builder.remove(menu: .speech)

			// Remove Format menu
			builder.remove(menu: .format)

			// Remove View menu toolbar items
			builder.remove(menu: .toolbar)

			// Application menu
			builder.insertSibling(UIMenu(options: .displayInline,
																	 children: [
																		UIKeyCommand(title: .localize("SETTINGS_MAC", comment: "Title of Settings page on macOS (where Settings is usually named Preferences)."),
																								 action: #selector(RootViewController.openSettings),
																								 input: ",",
																								 modifierFlags: .command)
																	 ]),
														afterMenu: .about)
			builder.replace(menu: .about,
											with: UIMenu(options: .displayInline,
																	 children: [
																		UICommand(title: .localize("ABOUT", comment: "Title of About page."),
																							action: #selector(self.openAbout))
																	 ]))

			// File menu
			builder.replace(menu: .newScene,
											with: UIMenu(options: .displayInline,
																	 children: [
																		UIKeyCommand(title: .localize("NEW_WINDOW", comment: "VoiceOver label for the new window button."),
																								 action: #selector(RootViewController.addWindow),
																								 input: "n",
																								 modifierFlags: .command),
																		UIKeyCommand(title: .localize("NEW_TAB", comment: "VoiceOver label for the new tab button."),
																								 action: #selector(RootViewController.newTab),
																								 input: "t",
																								 modifierFlags: .command)
																	 ]))

			builder.replace(menu: .close,
											with: UIMenu(options: .displayInline,
																	 children: [
																		// TODO: Disabling for now, needs research.
																		// Probably need to directly access the NSWindow to do this.
//																		UIKeyCommand(title: .localize("CLOSE_WINDOW", comment: "VoiceOver label for the close window button."),
//																								 action: #selector(RootViewController.closeCurrentWindow),
//																								 input: "w",
//																								 modifierFlags: [ .command, .shift ]),
																		UIKeyCommand(title: .localize("CLOSE_TAB", comment: "VoiceOver label for the close tab button."),
																								 action: #selector(RootViewController.removeCurrentTerminal),
																								 input: "w",
																								 modifierFlags: .command)
																	 ]))

			builder.insertChild(UIMenu(options: .displayInline,
																 children: [
																	UIKeyCommand(title: .localize("SPLIT_HORIZONTALLY"),
																							 action: #selector(RootViewController.splitHorizontally),
																							 input: "d",
																							 modifierFlags: [.command, .shift]),
																	UIKeyCommand(title: .localize("SPLIT_VERTICALLY"),
																							 action: #selector(RootViewController.splitVertically),
																							 input: "d",
																							 modifierFlags: .command)
																 ]),
													atEndOfMenu: .file)

			// Edit menu
			builder.insertSibling(UIMenu(options: .displayInline,
																	 children: [
																		UIKeyCommand(title: .localize("CLEAR_TERMINAL", comment: "VoiceOver label for a button that clears the terminal."),
																								 action: #selector(TerminalSessionViewController.clearTerminal),
																								 input: "k",
																								 modifierFlags: .command)
																	 ]),
														afterMenu: .standardEdit)

		case .context:
			// Remove Speech menu
			builder.remove(menu: .speech)

			// Add Clear Terminal
			builder.insertSibling(UIMenu(options: .displayInline,
																	 children: [
																		UIKeyCommand(title: .localize("CLEAR_TERMINAL", comment: "VoiceOver label for a button that clears the terminal."),
																								 action: #selector(TerminalSessionViewController.clearTerminal),
																								 input: "k",
																								 modifierFlags: .command)
																	 ]),
														afterMenu: .standardEdit)

		default: break
		}
	}

}

