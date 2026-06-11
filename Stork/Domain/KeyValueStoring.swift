//
//  KeyValueStoring.swift
//  Stork
//

import Foundation

/// Abstraction over `UserDefaults` so logic that persists small flags and
/// counters can be tested without touching real defaults.
protocol KeyValueStoring: AnyObject {
    func bool(forKey defaultName: String) -> Bool
    func integer(forKey defaultName: String) -> Int
    func stringArray(forKey defaultName: String) -> [String]?
    func set(_ value: Any?, forKey defaultName: String)
    func set(_ value: Bool, forKey defaultName: String)
    func set(_ value: Int, forKey defaultName: String)
}

extension UserDefaults: KeyValueStoring {}
