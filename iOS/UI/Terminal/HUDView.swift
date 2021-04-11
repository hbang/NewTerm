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
	let backdropView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))

	init(image: UIImage) {
		super.init(frame: .zero)

		frame = CGRect(origin: .zero, size: intrinsicContentSize)
		alpha = 0
		clipsToBounds = true
		layer.cornerRadius = 16
		layer.cornerCurve = .continuous
		tintColor = .label
		isUserInteractionEnabled = false

		backdropView.frame = bounds
		backdropView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		addSubview(backdropView)

		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.image = image
		imageView.sizeToFit()
		addSubview(imageView)

		NSLayoutConstraint.activate([
			imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
			imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
		])
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
		UIView.animate(withDuration: 0.3,
									 delay: 0.75,
									 options: [],
									 animations: {
										self.alpha = 0
									 },
									 completion: nil)
	}

}
