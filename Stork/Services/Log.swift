//
//  Log.swift
//  Stork
//

import os

/// Centralized loggers, one per subsystem area. Prefer these over `print`
/// so output is filterable in Console and stripped appropriately in release.
enum Log {
    private static let subsystem = "com.molargiksoftware.Stork"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let deliveries = Logger(subsystem: subsystem, category: "deliveries")
    static let sync = Logger(subsystem: subsystem, category: "sync")
    static let health = Logger(subsystem: subsystem, category: "health")
    static let location = Logger(subsystem: subsystem, category: "location")
    static let weather = Logger(subsystem: subsystem, category: "weather")
    static let export = Logger(subsystem: subsystem, category: "export")
    static let widgets = Logger(subsystem: subsystem, category: "widgets")
}
