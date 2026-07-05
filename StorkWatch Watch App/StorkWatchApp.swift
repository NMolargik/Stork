//
//  StorkWatchApp.swift
//  StorkWatch Watch App
//
//  Thin entry point: builds `WatchSession` (the watch composition root) and hosts the
//  content view. No direct SwiftData — the store lives behind the repository.
//

import SwiftUI

@main
struct StorkWatchApp: App {
    @State private var session = WatchSession()

    var body: some Scene {
        WindowGroup {
            WatchContentView(session: session)
        }
    }
}
