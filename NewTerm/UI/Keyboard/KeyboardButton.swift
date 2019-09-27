//
//  KeyboardButton.swift
//  NewTerm
//
//  Created by Adam Demasi on 10/1/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit

class KeyboardButton: UIButton {

	enum Style: Int {
		case text = 0, icons = 1
	}

	private(set) var glyph: String?
	private(set) var image: UIImage?
	private(set) var highlightedImage: UIImage?

	convenience init(title: String, glyph: String? = nil, image: UIImage? = nil, highlightedImage: UIImage? = nil, target: AnyObject? = nil, action: Selector? = nil) {
		self.init(frame: .zero)

		accessibilityLabel = title
		self.glyph = glyph
		self.image = image
		self.highlightedImage = highlightedImage

		if target != nil && action != nil {
			addTarget(target!, action: action!, for: .touchUpInside)
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		clipsToBounds = true
		layer.cornerRadius = isBigDevice ? 6 : 4
		titleLabel!.font = .systemFont(ofSize: isBigDevice ? 18 : 15)
		tintColor = .white
		adjustsImageWhenHighlighted = false
		setTitleColor(tintColor, for: .normal)
		setTitleColor(.black, for: .selected)
		setBackgroundImage(image(of: UIColor(white: 0.3529411765, alpha: 1)), for: .normal)
		setBackgroundImage(image(of: UIColor(white: 0.2078431373, alpha: 1)), for: .highlighted)
		setBackgroundImage(image(of: UIColor(white: 0.6784313725, alpha: 1)), for: .selected)
		setBackgroundImage(image(of: UIColor(white: 0.6784313725, alpha: 1)), for: [ .highlighted, .selected ])

		addTarget(UIDevice.current, action: #selector(UIDevice.playInputClick), for: .touchUpInside)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var style: Style = .text {
		didSet {
			let actualNormalImage: UIImage?
			let actualHighlightedImage: UIImage?
			if image != nil && (glyph == nil || style == .icons) {
				actualNormalImage = image!.withRenderingMode(.alwaysTemplate)
				actualHighlightedImage = highlightedImage?.withRenderingMode(.alwaysTemplate)
				setTitle(nil, for: .normal)
			} else {
				actualNormalImage = nil
				actualHighlightedImage = nil
				setTitle(glyph ?? accessibilityLabel, for: .normal)
			}
			setImage(actualNormalImage, for: .normal)
			setImage(actualHighlightedImage, for: .highlighted)
			setImage(actualHighlightedImage, for: .selected)
		}
	}

	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.width += 16
		size.height = isBigDevice ? 40 : UIView.noIntrinsicMetric
		return size
	}

	private func image(of color: UIColor) -> UIImage {
		return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
			color.setFill()
			context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
		}
	}

}
