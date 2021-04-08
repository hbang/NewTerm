//
//  UpdateCheckManager.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 8/4/21.
//

import Foundation
import os.log

struct UpdateCheckResponse: Codable {
	let versionString: String
	let versionCode: String
	let minimumOSVersion: String
	let url: String
}

class UpdateCheckManager {

	static let updateAvailableNotification = Notification.Name(rawValue: "UpdateCheckManagerUpdateAvailableNotification")

	static func check(updateAvailableCompletion: @escaping (_ repsonse: UpdateCheckResponse) -> ()) {
		#if targetEnvironment(macCatalyst) && !DEBUG
		URLSession.shared.dataTask(with: URL(string: "https://cdn.hbang.ws/updates/newterm-mac-beta.json")!) { data, _, error in
			if let error = error {
				os_log("Update checker error: %@", String(describing: error))
				return
			}

			do {
				let response = try JSONDecoder().decode(UpdateCheckResponse.self, from: data ?? Data())

				let infoPlist = Bundle.main.infoDictionary!
				let appVersionCode = infoPlist["CFBundleVersion"] as! String
				let osVersion = UIDevice.current.systemVersion

				if response.versionCode.compare(appVersionCode, options: .numeric) == .orderedDescending &&
						response.minimumOSVersion.compare(osVersion, options: .numeric) != .orderedDescending {
					DispatchQueue.main.async {
						updateAvailableCompletion(response)
					}
				}
			} catch {
				os_log("Update checker error: %@", String(describing: error))
			}
		}.resume()
		#endif
	}

}
