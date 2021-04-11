//
//  ITermExtensionsParser.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 11/4/21.
//

import Foundation
import SwiftTerm

extension TerminalController {

	public func iTermContent(source: Terminal, _ content: String) {
		let scanner = Scanner(string: content)

		let command = scanner.scanUpToString("=")
		switch command {
		case "ShellIntegrationVersion":
			_ = scanner.scanString("=")
			iTermIntegrationVersion = scanner.scanUpToString(";")
			_ = scanner.scanString(";")
			while !scanner.isAtEnd {
				let command = scanner.scanUpToString("=")
				_ = scanner.scanString("=")
				switch command {
				case "shell": shell = scanner.scanUpToString(";")
				default: break
				}
				_ = scanner.scanString(";")
			}

		case "RemoteHost":
			_ = scanner.scanString("=")
			userAndHostname = scanner.scanUpToString(";")
			if let atIndex = userAndHostname?.firstIndex(of: "@") {
				let afterAtIndex = userAndHostname!.index(after: atIndex)
				user = String(userAndHostname![userAndHostname!.startIndex..<atIndex])
				hostname = String(userAndHostname![afterAtIndex..<userAndHostname!.endIndex])
			} else {
				user = nil
				hostname = nil
			}

		case "CurrentDir":
			if isProcessTrusted(source: source) {
				_ = scanner.scanString("=")
				if let currentDir = scanner.scanUpToString(";"),
					 !currentDir.isEmpty {
					currentWorkingDirectory = URL(fileURLWithPath: currentDir)
					DispatchQueue.main.async {
						self.delegate?.currentFileDidChange(self.currentFile ?? self.currentWorkingDirectory,
																								inWorkingDirectory: self.currentWorkingDirectory)
					}
				}
			}

		default: break
		}
	}

}

