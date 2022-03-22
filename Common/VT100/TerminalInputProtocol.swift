//
//  TerminalInputProtocol.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 20/6/19.
//

import Foundation

public protocol TerminalInputProtocol: AnyObject {

	func receiveKeyboardInput(data: [UInt8])

	var applicationCursor: Bool { get }

}
