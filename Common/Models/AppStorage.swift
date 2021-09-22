//
//  AppStorage.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 5/4/21.
//

import Foundation
import SwiftUI
import Combine

// Replica of SwiftUI AppStorage so we can use it on iOS 13.

public protocol PropertyListValue {}
extension Array: PropertyListValue where Element: PropertyListValue {}
extension Dictionary: PropertyListValue where Key == String, Value: PropertyListValue {}
extension String: PropertyListValue {}
extension Data: PropertyListValue {}
extension Date: PropertyListValue {}
extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Double: PropertyListValue {}
extension Optional: PropertyListValue where Wrapped: PropertyListValue {}

@propertyWrapper
public struct AppStorage<Value: PropertyListValue>: DynamicProperty {

	let key: String
	let defaultValue: Value
	let store: UserDefaults

	public init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) {
		self.defaultValue = wrappedValue
		self.key = key
		self.store = store
	}

	public var wrappedValue: Value {
		get { return store.object(forKey: key) as? Value ?? defaultValue }
		nonmutating set {
			store.set(newValue, forKey: key)
			NotificationCenter.default.post(name: Preferences.didChangeNotification, object: nil)
		}
	}

	public var projectedValue: Binding<Value> {
		Binding(
			get: { wrappedValue },
			set: { value in wrappedValue = value }
		)
	}

}

//extension AppStorage where Value: EnumPropertyListValue {
//	public var wrappedValue: Value {
//		get {
//			if let rawValue = store.object(forKey: key) as? Int {
//				return Value(rawValue: rawValue) ?? defaultValue
//			}
//			return defaultValue
//		}
//		nonmutating set {
//			store.set(newValue.rawValue, forKey: key)
//			NotificationCenter.default.post(name: Preferences.didChangeNotification, object: nil)
//		}
//	}
//}
