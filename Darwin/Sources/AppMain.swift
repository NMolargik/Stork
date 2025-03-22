//
//  AppMain.swift
//
//
//  Created by Nick Molargik on 3/14/25.
//

import SwiftUI
import Stork

/// The entry point to the app simply loads the App implementation from SPM module.
@main struct AppMain: App, StorkApp {
    #if SKIP || !os(macOS)
    @UIApplicationDelegateAdaptor(StorkAppDelegate.self) var appDelegate
    #endif
}
