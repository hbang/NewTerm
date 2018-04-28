//
//  Global.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

let isBigDevice: Bool = {
	switch UIDevice.current.userInterfaceIdiom {
	case .phone, .carPlay, .unspecified:
		return false
	
	case .pad, .tv:
		return true
	}
}()

let isSmallDevice = UIScreen.main.bounds.height < 700
