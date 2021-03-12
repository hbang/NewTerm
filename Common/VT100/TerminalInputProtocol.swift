//
//  TerminalInputProtocol.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 20/6/19.
//

public protocol TerminalInputProtocol: AnyObject {

	func receiveKeyboardInput(data: Data)

	var applicationCursor: Bool { get }

}
