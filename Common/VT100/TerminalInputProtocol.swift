//
//  TerminalInputProtocol.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 20/6/19.
//

public protocol TerminalInputProtocol {

	func receiveKeyboardInput(data: Data)
	func openSettings()

}
