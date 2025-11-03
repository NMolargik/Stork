//
//  ContentView.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct ContentView: View {
    @Environment(UserManager.self) private var userManager: UserManager
    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false
    
    var resetApplication: () -> Void

    @State private var viewModel: ContentView.ViewModel = ViewModel()
    @State private var deliveryManager: DeliveryManager?
    @State private var insightManager: InsightManager?
    @State private var migrationManager = MigrationManager()
    @State private var healthManager = HealthManager()
    @State private var weatherManager = WeatherManager()
    @State private var locationManager = LocationManager()
    @State private var hospitalManager = HospitalManager()
    
    var body: some View {
        ZStack {
            switch (viewModel.appStage) {
            case .start:
                ProgressView()
                    .id("start")
                    .zIndex(0)
                    .task {
                        // Ensure managers exist in the View
                        await MainActor.run {
                            if self.deliveryManager == nil {
                                self.deliveryManager = DeliveryManager(context: userManager.context)
                            }
                            if self.weatherManager.locationManager == nil {
                                self.weatherManager.setLocationProvider(LocationManager())
                            }
                            if self.insightManager == nil, let deliveryManager {
                                self.insightManager = InsightManager(deliveryManager: deliveryManager)
                            }
                        }
                        await viewModel.prepareApp(migrationManager: migrationManager)
                    }
            case .splash:
                SplashView(
                    checkForExisting: {
                        Task { await viewModel.prepareApp(migrationManager: migrationManager) }
                    },
                    attemptLogIn: { emailAddress, password in
                        return await viewModel.attemptLogIn(emailAddress: emailAddress, password: password, migrationManager: migrationManager)
                    },
                    moveToOnboarding: {
                        viewModel.appStage = .onboarding
                    },
                    resetPassword: { emailAddress in
                        try await migrationManager.sendPasswordReset(emailAddress: emailAddress)
                    }
                )
                .id("splash")
                .transition(viewModel.leadingTransition)
                .zIndex(1)
            case .migration:
                MigrationView(
                    migrationComplete: {
                        withAnimation {
                            viewModel.appStage = .onboarding
                        }
                    }
                )
                .environment(deliveryManager)
                .environment(userManager)
                .environment(migrationManager)
                .id("migration")
                .transition(viewModel.leadingTransition)
                .zIndex(1)
            case .onboarding:
                OnboardingView(onFinished: {
                    isOnboardingComplete = true
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.appStage = .main
                    }
                })
                .id("onboarding")
                .environment(locationManager)
                .environment(healthManager)
                .transition(viewModel.leadingTransition)
                .zIndex(1)
                .environment(migrationManager)
            case .main:
                MainView(
                    resetApplication: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.resetApplicationStage()
                        }
                    }
                )
                .id("main")
                .transition(viewModel.leadingTransition)
                .zIndex(0)
                .environment(deliveryManager)
                .environment(userManager)
                .environment(hospitalManager)
                .environment(healthManager)
                .environment(insightManager)
                .environment(weatherManager)
                .environment(locationManager)
                .task { weatherManager.setLocationProvider(LocationManager()) }
            }
        }
        .onAppear {
            viewModel.configure(userManager: userManager) {
                self.resetApplication()
            }
        }
    }
}

#Preview {
    // Create an in-memory SwiftData container for previews
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for: User.self, Delivery.self, Baby.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Preview ModelContainer setup failed: \(error)")
    }

    // Set up a preview UserManager with the in-memory context
    let previewUserManager = UserManager(context: container.mainContext)

    return ContentView(
        resetApplication: {}
    )
    .modelContainer(container)
    .environment(previewUserManager)
    .environment(MigrationManager())
    .environment(DeliveryManager(context: previewUserManager.context))
    .environment(HealthManager())
    .environment(WeatherManager())
    .environment(LocationManager())
    .environment(HospitalManager())
}
