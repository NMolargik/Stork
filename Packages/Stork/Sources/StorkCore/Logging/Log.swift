//
//  Log.swift
//  StorkCore
//
//  Centralized `os.Logger`s, one per subsystem area. Prefer these over `print` so output
//  is filterable in Console and stripped appropriately in release. Files calling `Log`
//  need their own `import os` (member-import visibility).
//

import os

public enum Log {
    private static let subsystem = "com.molargiksoftware.Stork"

    public static let app = Logger(subsystem: subsystem, category: "app")
    public static let deliveries = Logger(subsystem: subsystem, category: "deliveries")
    public static let sync = Logger(subsystem: subsystem, category: "sync")
    public static let health = Logger(subsystem: subsystem, category: "health")
    public static let location = Logger(subsystem: subsystem, category: "location")
    public static let weather = Logger(subsystem: subsystem, category: "weather")
    public static let export = Logger(subsystem: subsystem, category: "export")
    public static let widgets = Logger(subsystem: subsystem, category: "widgets")
}
