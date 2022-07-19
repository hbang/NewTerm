//
//  TerminalSessionViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 7/7/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

import UIKit
import SwiftUI
import SwiftTerm
import NewTermCommon

class TerminalSampleView: UIView {

	private let textView = TerminalTextView(frame: .zero)
	private var terminal: Terminal!
	private let stringSupplier = StringSupplier()

	override init(frame: CGRect) {
		super.init(frame: frame)

		let options = TerminalOptions(cols: 80,
																	rows: 25,
																	termName: "xterm-256color",
																	scrollback: 100)
		terminal = Terminal(delegate: self,
												options: options)
		stringSupplier.terminal = terminal

		textView.frame = bounds
		textView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		textView.isEditable = false
		textView.isSelectable = false
		addSubview(textView)

		if let colorTest = try? Data(contentsOf: Bundle.main.url(forResource: "colortest", withExtension: "txt")!) {
			terminal?.feed(byteArray: [UTF8Char](colorTest))
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func update(fontMetrics: FontMetrics, colorMap: ColorMap) {
		stringSupplier.colorMap = colorMap
		stringSupplier.fontMetrics = fontMetrics
		textView.backgroundColor = stringSupplier.colorMap?.background
		textView.attributedText = stringSupplier.attributedString()
		setNeedsLayout()
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		// Determine the screen size based on the font size
		// TODO: Calculate the exact number of lines we need from the buffer
		let glyphSize = stringSupplier.fontMetrics?.boundingBox ?? .zero
		terminal.resize(cols: Int(textView.frame.size.width / glyphSize.width),
										rows: 32)
		textView.attributedText = stringSupplier.attributedString()
	}

}

extension TerminalSampleView: TerminalDelegate {
	func send(source: Terminal, data: ArraySlice<UInt8>) {}
}

struct TerminalSampleViewRepresentable: UIViewRepresentable {

	var fontMetrics: FontMetrics
	var colorMap: ColorMap

	func makeUIView(context: Context) -> TerminalSampleView {
		TerminalSampleView(frame: .zero)
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {
		uiView.update(fontMetrics: fontMetrics, colorMap: colorMap)
	}

}

struct TerminalSampleViewRepresentable_Previews: PreviewProvider {
	static var previews: some View {
		TerminalSampleViewRepresentable(
			fontMetrics: FontMetrics(font: AppFont(), fontSize: 13),
			colorMap: ColorMap(theme: AppTheme())
		)
	}
}
