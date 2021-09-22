//
//  SettingsAcknowledgementsTextView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 25/6/21.
//

import SwiftUI
import WebKit

struct SettingsAcknowledgementsTextViewRepresentable: UIViewRepresentable {

	func makeUIView(context: Context) -> UITextView {
		let textView = UITextView()
		textView.isEditable = false

		// None of these should ever fail. If they do, we may as well just crash.
		let url = Bundle.main.url(forResource: "acknowledgements", withExtension: "html")!
		let data = try! Data(contentsOf: url)

		let preamble = """
		<!DOCTYPE html>
		<html>
		<head>
			<meta charset="utf-8">
			<style>
			html { font: -apple-system-body; -webkit-text-size-adjust: none; }
			body { font-size: 0.9em; }
			.preamble { font-size: 0.92em; text-align: center; }
			</style>
		</head>
		<body>
			<p class="preamble">
				<a href="https://newterm.app/">newterm.app</a>
				<br>
				<a href="https://github.com/hbang/NewTerm">github.com/hbang/NewTerm</a>
			</p>
			<p class="preamble"></p>
		"""
			.data(using: .utf8)!
		let postamble = "</body></html>".data(using: .utf8)!
		let html = preamble + data + postamble

		let attachment = NSTextAttachment(image: UIImage(named: "app-icon-basic")!)
		let attachmentAttributedString = NSMutableAttributedString(attachment: attachment)
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .center
		paragraphStyle.paragraphSpacing = 15
		attachmentAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attachmentAttributedString.length))

		let attributedString = NSMutableAttributedString()
		attributedString.append(attachmentAttributedString)
		attributedString.mutableString.append("\n")

		let completion = { (htmlAttributedString: NSAttributedString) in
			attributedString.append(htmlAttributedString)
			attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: NSMakeRange(0, attributedString.length))

			// Sigh, fix paragraph spacing due to silly WebKit bug
			attributedString.beginEditing()
			attributedString.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, attributedString.length), options: []) { value, range, _ in
				guard let value = value as? NSParagraphStyle else {
					return
				}
				let paragraphStyle = value.mutableCopy() as! NSMutableParagraphStyle
				paragraphStyle.paragraphSpacing = max(paragraphStyle.paragraphSpacing, 6)
				attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
			}
			attributedString.endEditing()

			textView.attributedText = attributedString
		}

		if #available(iOS 14, *) {
			NSMutableAttributedString.loadFromHTML(data: html, options: [:]) { htmlAttributedString, _, _ in
				completion(htmlAttributedString!)
			}
		} else {
			completion(try! NSMutableAttributedString(data: html,
																								options: [
																									.documentType: NSAttributedString.DocumentType.html
																								],
																								documentAttributes: nil))
		}

		return textView
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {}

}

struct SettingsAcknowledgementsTextViewRepresentable_Previews: PreviewProvider {
	static var previews: some View {
		SettingsAcknowledgementsTextViewRepresentable()
			.preferredColorScheme(.dark)
			.previewDevice("iPhone 12 Pro")
	}
}
