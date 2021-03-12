//
//  TerminalSessionViewController.swift
//  NewTerm
//
//  Created by Adam Demasi on 7/7/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

@objc(TerminalSampleView)
class TerminalSampleView: UIView {

	private let textView = TerminalTextView(frame: .zero)
	private let buffer = VT100()!
	private let stringSupplier = VT100StringSupplier()

	override init(frame: CGRect) {
		super.init(frame: frame)

		stringSupplier.colorMap = VT100ColorMap()
		stringSupplier.screenBuffer = buffer

		textView.frame = bounds
		textView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		textView.isEditable = false
		textView.isSelectable = false
		addSubview(textView)

		if let colorTest = try? Data(contentsOf: Bundle.main.url(forResource: "colortest", withExtension: "txt")!) {
			buffer.readInputStream(colorTest)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(self.preferencesUpdated), name: Preferences.didChangeNotification, object: nil)
		preferencesUpdated()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc func preferencesUpdated() {
		let preferences = Preferences.shared
		stringSupplier.colorMap = preferences.colorMap
		stringSupplier.fontMetrics = preferences.fontMetrics
		textView.backgroundColor = stringSupplier.colorMap.background
		textView.attributedText = stringSupplier.attributedString()
	}

}
