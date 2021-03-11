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
		if #available(iOS 13, *) {
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
		if #available(iOS 13, *) {
			layer.cornerCurve = .continuous
			tintColor = .label
		} else {
			tintColor = .white
		}

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
		// If our alpha is non-zero, we’re already visible. Just ignore. We don’t extend the display
		// timer here to avoid the HUD from being too annoying.
		if alpha != 0 {
			return
		}

		alpha = 1

		// Display for 1.5 secs, fade out in 0.3 secs.
		UIView.animate(withDuration: 0.3, delay: 0.75, options: .init(), animations: {
			self.alpha = 0
		}, completion: nil)
	}

}
