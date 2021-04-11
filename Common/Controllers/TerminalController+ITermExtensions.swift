//
//  ITermExtensionsParser.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 11/4/21.
//

import Foundation
import SwiftTerm
import QuickLook

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

		case "File":
			// TODO: We could support displaying file download progress, but SwiftTerm just gives us the
			// entire escape at once as a ginormous string.
			_ = scanner.scanString("=name=")
			let encodedFileName = scanner.scanUpToString(";")
			_ = scanner.scanString(";size=")
			let fileSize = scanner.scanInt()
//			_ = scanner.scanString(";")
//			let isInline = scanner.scanString("inline=1") != nil
			_ = scanner.scanString(":")
			let encodedFile = scanner.scanUpToString(";")

			if let filename = String(data: Data(base64Encoded: encodedFileName ?? "") ?? Data(), encoding: .utf8),
				 let file = Data(base64Encoded: encodedFile ?? ""),
				 file.count == fileSize {
				// TODO: Support inline images!
				let basename = URL(fileURLWithPath: filename).lastPathComponent
				let tempURL = FileManager.default.temporaryDirectory
					.appendingPathComponent("downloads")
					.appendingPathComponent(UUID().uuidString)
				try? FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: [:])
				let url = tempURL.appendingPathComponent(basename)
				try? file.write(to: url, options: .completeFileProtection)

				DispatchQueue.main.async {
					self.delegate?.saveFile(url: url)
				}
			}

		case "RequestUpload":
			// The only supported format is currently tgz.
			if scanner.scanString("=format=tgz") != nil {
				DispatchQueue.main.async {
					self.delegate?.fileUploadRequested()
				}
				return
			}

		default:
			print("XXX Unrecognised iTerm2 command \(content)")
		}
	}

	// MARK: - File download/upload

	public func deleteDownloadCache() {
		let tempURL = FileManager.default.temporaryDirectory
			.appendingPathComponent("downloads")
		try? FileManager.default.removeItem(at: tempURL)
	}

	public func uploadFile(url: URL) {
		// TODO: Tar + gzip up the file(s)!
		terminalQueue.async {
			// First, respond with ok to confirm we’re about to send a payload.
			self.write("ok\r".data(using: .utf8)!)

			// Now, we need to base64 the contents of this file.
			guard let data = try? Data(contentsOf: url) else {
				return
			}
			let encodedData = data.base64EncodedData(options: [ .lineLength76Characters, .endLineWithCarriageReturn ])
			self.write(encodedData)

			// Finally, send two ending returns to indicate end of file.
			self.write("\r\r".data(using: .utf8)!)
		}
	}

	public func cancelUploadRequest() {
		terminalQueue.async {
			self.write("abort\r".data(using: .utf8)!)
		}
	}

}

