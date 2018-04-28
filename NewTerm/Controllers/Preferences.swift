//
//  Preferences.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class Preferences {
	
	static let shared = Preferences()
	
	let preferences = UserDefaults.standard
	
	let fontsPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Fonts", withExtension: "plist")!)!
	let themesPlist = NSDictionary(contentsOf: Bundle.main.url(forResource: "Themes", withExtension: "plist")!)!
	
	var fontMetrics: FontMetrics!
	var colorMap: VT100ColorMap!
	
	init() {
		preferences.register(defaults: [
			"fontName": "Fira Code",
			"fontSize": 12,
			"theme": "kirb"
		])
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: UserDefaults.didChangeNotification, object: preferences)
		preferencesUpdated()
	}
	
	var fontName: String {
		get { return preferences.object(forKey: "fontName") as! String }
	}
	
	var fontSize: CGFloat {
		get { return preferences.object(forKey: "fontSize") as! CGFloat }
	}
	
	var themeName: String {
		get { return preferences.object(forKey: "theme") as! String }
	}
	
	// MARK: - Callbacks
	
	@objc private func preferencesUpdated() {
		fontMetricsChanged()
		colorMapChanged()
	}
	
	private func fontMetricsChanged() {
		var regularFont: UIFont?
		var boldFont: UIFont?
		
		if let family = fontsPlist[fontName] as? [String: String] {
			if family["Regular"] != nil && family["Bold"] != nil {
				regularFont = UIFont(name: family["Regular"]!, size: fontSize)
				boldFont = UIFont(name: family["Bold"]!, size: fontSize)
			}
		}
		
		if regularFont == nil || boldFont == nil {
			NSLog("font %@ size %f could not be initialised", fontName, fontSize)
			preferences.set("Courier", forKey: "fontName")
			return
		}
		
		fontMetrics = FontMetrics(font: regularFont, boldFont: boldFont)
	}
	
	func colorMapChanged() {
		// if the theme doesn’t exist… how did we get here? force it to the default, which will call
		// this method again
		guard let theme = themesPlist[themeName] as? [String: Any] else {
			NSLog("theme %@ doesn’t exist", themeName)
			preferences.set("kirb", forKey: "theme")
			return
		}
	
		colorMap = VT100ColorMap(dictionary: theme)
	}
	
}

