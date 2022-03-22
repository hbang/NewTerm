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

	public static let backspace: [UInt8] = [0x7F] // \x7F
	public static let meta: [UInt8]      = [0x1B] // \e
	public static let tab: [UInt8]       = [0x09] // \t
	public static let `return`: [UInt8]  = [0x0D] // \r

	public static let up: [UInt8]        = [0x1B, 0x5B, 0x41] // \e[A
	public static let upApp: [UInt8]     = [0x1B, 0x4F, 0x41] // \eOA
	public static let down: [UInt8]      = [0x1B, 0x5B, 0x42] // \e[B
	public static let downApp: [UInt8]   = [0x1B, 0x4F, 0x42] // \eOB
	public static let left: [UInt8]      = [0x1B, 0x5B, 0x44] // \e[D
	public static let leftApp: [UInt8]   = [0x1B, 0x4F, 0x44] // \eOD
	public static let leftMeta: [UInt8]  = [0x62] // \eb (removed \e)
	public static let right: [UInt8]     = [0x1B, 0x5B, 0x43] // \e[C
	public static let rightApp: [UInt8]  = [0x1B, 0x4F, 0x43] // \eOC
	public static let rightMeta: [UInt8] = [0x66] // \ef (removed \e)

	public static let home: [UInt8]      = [0x1B, 0x5B, 0x48] // \e[H
	public static let homeApp: [UInt8]   = [0x1B, 0x4F, 0x48] // \eOH
	public static let end: [UInt8]       = [0x1B, 0x5B, 0x46] // \e[F
	public static let endApp: [UInt8]    = [0x1B, 0x4F, 0x46] // \eOF
	public static let pageUp: [UInt8]    = [0x1B, 0x5B, 0x35, 0x7E] // \e[5~
	public static let pageDown: [UInt8]  = [0x1B, 0x5B, 0x36, 0x7E] // \e[6~
	public static let delete: [UInt8]    = [0x1B, 0x5B, 0x33, 0x7E] // \e[3~

	public static let fn: [[UInt8]] = [
		[0x1B, 0x4F, 0x50], // \eOP
		[0x1B, 0x4F, 0x51], // \eOQ
		[0x1B, 0x4F, 0x52], // \eOR
		[0x1B, 0x4F, 0x53], // \eOS
		[0x1B, 0x5B, 0x31, 0x35, 0x7E], // \e[15~
		[0x1B, 0x5B, 0x31, 0x37, 0x7E], // \e[17~
		[0x1B, 0x5B, 0x31, 0x38, 0x7E], // \e[18~
		[0x1B, 0x5B, 0x31, 0x39, 0x7E], // \e[19~
		[0x1B, 0x5B, 0x32, 0x30, 0x7E], // \e[20~
		[0x1B, 0x5B, 0x32, 0x31, 0x7E], // \e[21~
		[0x1B, 0x5B, 0x32, 0x33, 0x7E], // \e[23~
		[0x1B, 0x5B, 0x32, 0x34, 0x7E], // \e[24~
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
