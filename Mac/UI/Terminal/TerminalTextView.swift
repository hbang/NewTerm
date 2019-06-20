//
//  TerminalTextView.swift
//  NewTerm (macOS)
//
//  Created by Adam Demasi on 20/6/19.
//

import AppKit

class TerminalTextView: NSTextView {

	var terminalInputDelegate: TerminalInputProtocol?

	override func keyDown(with event: NSEvent) {
		super.keyDown(with: event)

		terminalInputDelegate!.receiveKeyboardInput(data: Data(event.characters!.utf8))
	}

}
