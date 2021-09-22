//
//  SettingsAcknowledgementsView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 25/6/21.
//

import SwiftUI

struct SettingsAcknowledgementsView: View {
	var body: some View {
		SettingsAcknowledgementsTextViewRepresentable()
			.navigationBarTitle("License & Acknowledgements", displayMode: .inline)
	}
}

struct SettingsAcknowledgementsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsAcknowledgementsView()
	}
}

