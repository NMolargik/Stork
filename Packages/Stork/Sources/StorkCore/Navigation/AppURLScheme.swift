//
//  AppURLScheme.swift
//  StorkCore
//
//  The app's custom URL scheme, shared by deep-link parsing and URL construction so
//  the literal `"stork"` lives in exactly one place.
//

import Foundation

nonisolated public enum AppURLScheme {
    public static let scheme = "stork"

    /// Builds a `stork://<host>` URL.
    public static func url(host: String) -> URL? {
        URL(string: "\(scheme)://\(host)")
    }
}
