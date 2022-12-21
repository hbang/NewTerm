//
//  SponsorsView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 21/12/2022.
//

import SwiftUI

fileprivate struct SponsorsObject: Codable {
	let sponsors: [Sponsor]
}

fileprivate struct Sponsor: Codable, Identifiable {
	let name: String
	var id: String { name }
}

struct SponsorsView: View {

	@State private var sponsors: String?
	@State private var isError = false

	var body: some View {
		if let sponsors = sponsors {
			VStack(alignment: .leading, spacing: 10) {
				Text("NewTerm is made available for free thanks to generous support from these fans:")
					.font(.system(size: 14, weight: .semibold))

				Text(sponsors)
					.font(.system(size: 14))
			}
				.fixedSize(horizontal: false, vertical: true)
		} else if isError {
			EmptyView()
		} else {
			HStack {
				Spacer()
				ProgressView()
				Spacer()
			}
				.onAppear {
					Task.detached { await self.fetchSponsors() }
				}
		}
	}

	private func fetchSponsors() async {
		if isError || sponsors != nil {
			return
		}

		do {
			let (data, _) = try await URLSession.shared.data(from: URL(string: "https://hashbang.productions/api/sponsors")!)
			let json = try JSONDecoder().decode(SponsorsObject.self, from: data)
			let formatter = ListFormatter()
			sponsors = formatter.string(from: json.sponsors.map(\.name)) ?? ""
		} catch {
			isError = true
		}
	}
}

struct SponsorsView_Previews: PreviewProvider {
	static var previews: some View {
		SponsorsView()
	}
}

