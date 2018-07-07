//
//  KeyboardButton.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class KeyboardButton: UIButton {
	
	convenience init(title: String) {
		self.init(frame: .zero)
		setTitle(title, for: .normal)
	}
	
	convenience init(title: String, target: AnyObject, action: Selector) {
		self.init(frame: .zero)
		setTitle(title, for: .normal)
		addTarget(target, action: action, for: .touchUpInside)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		clipsToBounds = true
		layer.cornerRadius = isBigDevice ? 6 : 4
		titleLabel!.font = .systemFont(ofSize: isBigDevice ? 18 : 15)
		setTitleColor(.white, for: .normal)
		setTitleColor(.black, for: .selected)
		setBackgroundImage(image(color: UIColor(white: 0.3529411765, alpha: 1)), for: .normal)
		setBackgroundImage(image(color: UIColor(white: 0.2078431373, alpha: 1)), for: .highlighted)
		setBackgroundImage(image(color: UIColor(white: 0.6784313725, alpha: 1)), for: .selected)
		
		addTarget(UIDevice.current, action: #selector(UIDevice.playInputClick), for: .touchUpInside)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.width += 16
		size.height = isBigDevice ? 40 : UIViewNoIntrinsicMetric
		return size
	}
	
	private func image(color: UIColor) -> UIImage {
		// https://stackoverflow.com/a/14525049/709376
		let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
		
		UIGraphicsBeginImageContextWithOptions(rect.size, true, 1)
		
		let context = UIGraphicsGetCurrentContext()!
		context.setFillColor(color.cgColor)
		context.fill(rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		
		return image
	}
	
}
