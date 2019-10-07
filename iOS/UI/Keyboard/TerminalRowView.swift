//
//  TerminalRowView.swift
//  NewTerm
//
//  Created by Adam Demasi on 22/3/19.
//  Copyright © 2019 HASHBANG Productions. All rights reserved.
//

import UIKit

class TerminalRowView: UIView {

	private static let textTransform = CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: -1.0, tx: 0.0, ty: 0.0)

	var rowIndex: Int! {
		didSet { setNeedsDisplay() }
	}
	var terminalController: TerminalController!
	var fontMetrics: FontMetrics!

	private var textOffset: CGFloat {
		// The base line of the text from the top of the row plus some offset for the glyph descent.
		// This assumes that the frame size for this cell is based on the same font metrics
		return fontMetrics.boundingBox.height - fontMetrics.descent
	}

	private func characterRect(range: NSRange) -> CGRect {
		// Convert a range of characters in a string to the rect where they are drawn
		let characterBox = fontMetrics.boundingBox
		return CGRect(x: characterBox.width * CGFloat(range.location), y: 0, width: characterBox.width * CGFloat(range.length), height: characterBox.height)
	}

	private func drawBackground(context: CGContext, attributedString: NSAttributedString) {
		// Paints the background in as few steps as possible by finding common runs of text with the
		// same attributes.
		var remaining = NSRange(location: 0, length: (attributedString.string as NSString).length)
		while remaining.length > 0 {
			var range = NSRange()
			let backgroundColor = attributedString.attribute(.backgroundColor, at: remaining.location, effectiveRange: &range) as? UIColor ?? .black
			context.setFillColor(backgroundColor.cgColor)
			context.fill(characterRect(range: range))
			remaining.length -= range.length
			remaining.location += range.length
		}
	}

	override func draw(_ rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()!
		let attributedString = terminalController.attributedString(forLine: rowIndex)
		drawBackground(context: context, attributedString: attributedString)

		// By default, text is drawn upside down. Apply a transformation to orient the text correctly.
		context.textMatrix = TerminalRowView.textTransform
		context.textPosition = CGPoint(x: 0, y: textOffset)
		let line = CTLineCreateWithAttributedString(attributedString)
		CTLineDraw(line, context)
	}

}
