//
//  AboutSceneDelegate.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 16/9/21.
//

import UIKit
import SwiftUI

extension NSUserActivity {
	static let aboutScene = NSUserActivity(activityType: AboutSceneDelegate.activityType)
}

class AboutSceneDelegate: UIResponder, UIWindowSceneDelegate, IdentifiableSceneDelegate {

	static let activityType = "ws.hbang.Terminal.AboutSceneActivity"

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}

		window = UIWindow(windowScene: windowScene)
		window!.tintColor = .tint
		window!.rootViewController = UIHostingController(rootView: SettingsAboutView(windowScene: windowScene))

		windowScene.title = NSLocalizedString("ABOUT", comment: "Title of About page.")
		windowScene.sizeRestrictions?.minimumSize = CGSize(width: 450, height: 600)
		windowScene.sizeRestrictions?.maximumSize = CGSize(width: 450, height: 600)

#if targetEnvironment(macCatalyst)
		windowScene.titlebar?.titleVisibility = .hidden
		windowScene.titlebar?.toolbar = nil
#endif

		window!.makeKeyAndVisible()
	}

}
