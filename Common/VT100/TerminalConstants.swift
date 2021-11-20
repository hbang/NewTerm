//
//  TerminalConstants.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 2/4/21.
//

import Foundation

public struct ScreenSize: Equatable {
	public var cols: UInt
	public var rows: UInt

	public init(cols: UInt, rows: UInt) {
		self.cols = cols
		self.rows = rows
	}

	public static let `default` = ScreenSize(cols: 80, rows: 25)
}

public struct EscapeSequences {

	// https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-PC-Style-Function-Keys

	public static let backspace = Data([ 0x7F ]) // \x7F
	public static let meta      = Data([ 0x1B ]) // \e
	public static let tab       = Data([ 0x09 ]) // \t
	public static let `return`  = Data([ 0x0D ]) // \r

	public static let up        = Data([ 0x1B, 0x5B, 0x41 ]) // \e[A
	public static let upApp     = Data([ 0x1B, 0x4F, 0x41 ]) // \eOA
	public static let down      = Data([ 0x1B, 0x5B, 0x42 ]) // \e[B
	public static let downApp   = Data([ 0x1B, 0x4F, 0x42 ]) // \eOB
	public static let left      = Data([ 0x1B, 0x5B, 0x44 ]) // \e[D
	public static let leftApp   = Data([ 0x1B, 0x4F, 0x44 ]) // \eOD
	public static let leftMeta  = Data([ 0x62 ]) // \eb (removed \e)
	public static let right     = Data([ 0x1B, 0x5B, 0x43 ]) // \e[C
	public static let rightApp  = Data([ 0x1B, 0x4F, 0x43 ]) // \eOC
	public static let rightMeta = Data([ 0x66 ]) // \ef (removed \e)

	public static let home      = Data([ 0x1B, 0x5B, 0x48 ]) // \e[H
	public static let homeApp   = Data([ 0x1B, 0x4F, 0x48 ]) // \eOH
	public static let end       = Data([ 0x1B, 0x5B, 0x46 ]) // \e[F
	public static let endApp    = Data([ 0x1B, 0x4F, 0x46 ]) // \eOF
	public static let pageUp    = Data([ 0x1B, 0x5B, 0x35, 0x7E ]) // \e[5~
	public static let pageDown  = Data([ 0x1B, 0x5B, 0x36, 0x7E ]) // \e[6~
	public static let delete    = Data([ 0x1B, 0x5B, 0x33, 0x7E ]) // \e[3~

	public static let fn        = [
		Data([ 0x1B, 0x4F, 0x50 ]), // \eOP
		Data([ 0x1B, 0x4F, 0x51 ]), // \eOQ
		Data([ 0x1B, 0x4F, 0x52 ]), // \eOR
		Data([ 0x1B, 0x4F, 0x53 ]), // \eOS
		Data([ 0x1B, 0x5B, 0x31, 0x35, 0x7E ]), // \e[15~
		Data([ 0x1B, 0x5B, 0x31, 0x37, 0x7E ]), // \e[17~
		Data([ 0x1B, 0x5B, 0x31, 0x38, 0x7E ]), // \e[18~
		Data([ 0x1B, 0x5B, 0x31, 0x39, 0x7E ]), // \e[19~
		Data([ 0x1B, 0x5B, 0x32, 0x30, 0x7E ]), // \e[20~
		Data([ 0x1B, 0x5B, 0x32, 0x31, 0x7E ]), // \e[21~
		Data([ 0x1B, 0x5B, 0x32, 0x33, 0x7E ]), // \e[23~
		Data([ 0x1B, 0x5B, 0x32, 0x34, 0x7E ]), // \e[24~
	]

	public static func asciiToControl(_ character: UInt8) -> UInt8 {
		var newCharacter = character

		// Translate capital to lowercase
		if character >= 0x41 && character <= 0x5A { // >= 'A' <= 'Z'
			newCharacter += 0x61 - 0x41 // 'a' - 'A'
		}

		// Convert to the matching control character
		if character >= 0x61 && character <= 0x7A { // >= 'a' <= 'z'
			newCharacter -= 0x61 - 1 // 'a' - 1
		}

		return newCharacter
	}

}
