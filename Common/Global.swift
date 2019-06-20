//
//  Global.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

#if os(macOS)
public let isBigDevice = true
public let isSmallDevice = false
#else
import UIKit

public let isBigDevice: Bool = {
	switch UIDevice.current.userInterfaceIdiom {
	case .phone, .carPlay, .unspecified:
		return false

	case .pad, .tv:
		return true

	@unknown default:
		return false
	}
}()

public let isSmallDevice = UIScreen.main.bounds.height < 700
#endif
