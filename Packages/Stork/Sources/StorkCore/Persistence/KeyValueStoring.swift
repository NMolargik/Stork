//
//  KeyValueStoring.swift
//  StorkCore
//
//  Abstraction over `UserDefaults` so logic that persists small flags, counters, and
//  encoded blobs can be tested without touching real defaults. `StorkData` provides the
//  `UserDefaults` conformance.
//

import Foundation

nonisolated public protocol KeyValueStoring: AnyObject {
    func bool(forKey defaultName: String) -> Bool
    func integer(forKey defaultName: String) -> Int
    func stringArray(forKey defaultName: String) -> [String]?
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    func set(_ value: Bool, forKey defaultName: String)
    func set(_ value: Int, forKey defaultName: String)
}
