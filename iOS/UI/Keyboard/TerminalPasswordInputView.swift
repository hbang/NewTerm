//
//  TerminalPasswordInputView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 11/3/21.
//

import UIKit

protocol TerminalPasswordInputViewDelegate: AnyObject {
	func passwordInputViewDidComplete(password: String?)
}

class TerminalPasswordInputView: UITextField {

	weak var passwordDelegate: TerminalPasswordInputViewDelegate?

	override init(frame: CGRect) {
		super.init(frame: .zero)

		isSecureTextEntry = true
		if #available(iOS 11, *) {
			textContentType = .password
		}

		NotificationCenter.default.addObserver(self, selector: #selector(self.textDidChange(_:)), name: UITextField.textDidChangeNotification, object: nil)
	}

	required init?(coder: NSCoder) {
		fatalError()
	}

	@objc private func textDidChange(_ notification: Notification) {
		if let text = text {
			passwordDelegate?.passwordInputViewDidComplete(password: text)
			self.text = nil
		}
	}

}
