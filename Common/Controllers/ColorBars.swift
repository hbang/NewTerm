//
//  ColorBars.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 23/9/21.
//

import Foundation

struct ColorBars {

	private struct RGB: CustomStringConvertible {
		var r: Int, g: Int, b: Int

		init(_ r: Int, _ g: Int, _ b: Int) {
			self.r = r
			self.g = g
			self.b = b
		}

		var description: String { "\(r);\(g);\(b)" }
	}

	private static let bars: [[RGB]] = [
		[RGB(192, 192, 192), RGB(192, 192,   0), RGB( 0, 192, 192), RGB(  0, 192,   0), RGB(192,   0, 192), RGB(192,   0,   0), RGB(  0,   0, 192)],
		[RGB(  0,   0, 192), RGB( 19,  19,  19), RGB(192,  0, 192), RGB( 19,  19,  19), RGB(  0, 192, 192), RGB( 19,  19,  19), RGB(192, 192, 192)],
		[RGB(  0,  33,  76), RGB(255, 255, 255), RGB( 50,  0, 106), RGB( 19,  19,  19), RGB(  9,   9,   9), RGB( 19,  19,  19), RGB( 29,  29,  29), RGB( 19,  19,  19)]
	]

	static func render(screenSize: ScreenSize, message: String) -> Data {
		// Don’t bother drawing if the screen is too small
		if screenSize.cols < 7 || screenSize.rows < 10 {
			return Data()
		}

		// Draw color bars
		let firstSectionSize = ScreenSize(cols: UInt(Double(screenSize.cols) / 7),
																			rows: UInt(Double(screenSize.rows) * 0.66))
		let thirdSectionSize = ScreenSize(cols: UInt(Double(screenSize.cols) / 6),
																			rows: UInt(Double(screenSize.rows) * 0.25))
		let secondSectionSize = ScreenSize(cols: UInt(Double(screenSize.cols) / 7),
																			 rows: screenSize.rows - firstSectionSize.rows - thirdSectionSize.rows - 1)
		var data = "\u{1b}c".data(using: .utf8)!
		let space = String(repeating: " ", count: Int(firstSectionSize.cols))
		for _ in 0..<firstSectionSize.rows {
			for color in bars[0] {
				data.append("\u{1b}[48;2;\(color)m\(space)".data(using: .utf8)!)
			}
			data.append("\u{1b}[0m\r\n".data(using: .utf8)!)
		}
		for _ in 0..<secondSectionSize.rows {
			for color in bars[1] {
				data.append("\u{1b}[48;2;\(color)m\(space)".data(using: .utf8)!)
			}
			data.append("\u{1b}[0m\r\n".data(using: .utf8)!)
		}
		let finalSpace = String(repeating: " ", count: Int(thirdSectionSize.cols))
		let finalInnerWidth = Int(Double(thirdSectionSize.cols) / 3)
		let finalInnerSpace = String(repeating: " ", count: finalInnerWidth)
		for _ in 0..<thirdSectionSize.rows {
			for i in 0..<bars[2].count {
				// Special case: There is a gradient of 3 colors in the second-last rectangle.
				let space = i >= 4 && i <= 6 ? finalInnerSpace : finalSpace
				data.append("\u{1b}[48;2;\(bars[2][i])m\(space)".data(using: .utf8)!)
			}
			data.append("\u{1b}[0m\r\n".data(using: .utf8)!)
		}

		// Draw error text
		let textPosition = ScreenSize(cols: UInt(max(0, Double((Int(firstSectionSize.cols * 7) - message.count + 2) / 2).rounded(.toNearestOrEven))),
																	rows: UInt(Double(screenSize.rows / 2).rounded(.down)))
		data.append("\u{1b}[\(textPosition.rows);\(textPosition.cols)H\u{1b}[1;7m \(message) \u{1b}[m\u{1b}[\(screenSize.cols);0H".data(using: .utf8)!)

		return data
	}

}
