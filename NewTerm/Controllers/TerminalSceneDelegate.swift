//
//  TerminalSceneDelegate.swift
//  NewTerm
//
//  Created by Adam Demasi on 16/6/19.
//  Copyright © 2019 HASHBANG Productions. All rights reserved.
//

import UIKit

#if targetEnvironment(UIKitForMac)
import AppKit
#endif

@available(iOS 13.0, *)
class TerminalSceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		window!.tintColor = UIColor(red: 76 / 255, green: 161 / 255, blue: 1, alpha: 1)

		if let navigationController = window!.rootViewController as? UINavigationController {
			let storyboard = navigationController.storyboard!
			#if targetEnvironment(UIKitForMac)
			let viewController = storyboard.instantiateViewController(identifier: "terminalSessionViewController")
			#else
			let viewController = storyboard.instantiateViewController(identifier: "terminalViewController")
			#endif
			navigationController.viewControllers = [ viewController ]
		}
	}

}

