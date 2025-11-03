//
//  StorkApp.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import SwiftUI
import FirebaseCore
import SwiftData
import FirebaseAuth

@main
struct StorkApp: App {
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false

    @State private var userManager: UserManager
    
    private let sharedModelContainer: ModelContainer

    init() {
        FirebaseApp.configure()

        let cloudKitContainerID = "iCloud.com.molargiksoftware.Stork"
        
        do {
            let config = ModelConfiguration(
                cloudKitDatabase: .private(cloudKitContainerID)
            )
            
            sharedModelContainer = try ModelContainer(
                for: User.self, Delivery.self, Baby.self,
                configurations: config
            )
            
            userManager = UserManager(context: sharedModelContainer.mainContext)
        } catch {
            fatalError("[Stork] Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(resetApplication: self.resetApplication)
                .modelContainer(sharedModelContainer)
                .environment(userManager)
        }
    }
    
    private func resetApplication() {
        useMetricUnits = false
        useDayMonthYearDates = false
        isOnboardingComplete = false
        do {
            try Auth.auth().signOut()
        } catch {
            // Handle sign-out failure gracefully
            print("[Stork] Failed to sign out: \(error)")
        }
    }
}
