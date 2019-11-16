//
//  HUDView.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class HUDView: UIView {

	let imageView = UIImageView()

	let backdropView: UIVisualEffectView = {
		if #available(iOS 13.0, *) {
			return UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
		} else {
			return UIVisualEffectView(effect: UIBlurEffect(style: .dark))
		}
	}()

	init(image: UIImage) {
		super.init(frame: .zero)

		frame = CGRect(origin: .zero, size: intrinsicContentSize)
		alpha = 0
		clipsToBounds = true
		layer.cornerRadius = 16
		tintColor = .white

		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		addSubview(backdropView)

		imageView.image = image
		imageView.sizeToFit()
		imageView.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
		imageView.autoresizingMask = [ .flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleLeftMargin ]
		addSubview(imageView)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var intrinsicContentSize: CGSize {
		return CGSize(width: 54, height: 54)
	}

	func animate() {
		// if our alpha is non-zero, we’re already visible. maybe we should extend the visible duration
		// but eh. just do nothing
		if alpha != 0 {
			return
		}

		alpha = 1

		// display for 1.5 secs, fade out in 0.3 secs, then remove from superview
		UIView.animate(withDuration: 0.3, delay: 0.75, options: .init(), animations: {
			self.alpha = 0
		}, completion: nil)
	}

}
