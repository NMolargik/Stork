//
//  ContentView.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false

    @Binding var pendingDeepLink: DeepLink?

    @State private var viewModel: ContentView.ViewModel = ViewModel()
    @State private var deliveryManager: DeliveryManager?
    @State private var insightManager: InsightManager?
    @State private var exportManager = ExportManager()
    #if !os(visionOS)
    @State private var healthManager = HealthManager()
    #endif
    @State private var weatherManager = WeatherManager()
    @State private var locationManager = LocationManager()
    @State private var cloudSyncManager = CloudSyncManager()

    var body: some View {
        ZStack {
            switch viewModel.appStage {
            case .splash:
                SplashView(
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.appStage = .onboarding
                        }
                    }
                )
                .id("splash")
                .transition(viewModel.leadingTransition)
                .zIndex(1)

            case .onboarding:
                OnboardingView(onFinished: {
                    isOnboardingComplete = true
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.appStage = .syncing
                    }
                })
                .id("onboarding")
                .environment(locationManager)
                #if !os(visionOS)
                .environment(healthManager)
                #endif
                .transition(viewModel.leadingTransition)
                .zIndex(1)

            case .syncing:
                SyncingView(
                    onSyncComplete: { foundData in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.appStage = .main
                        }
                    }
                )
                .environment(deliveryManager)
                .environment(cloudSyncManager)
                .id("syncing")
                .transition(viewModel.leadingTransition)
                .zIndex(1)

            case .main:
                MainView(
                    pendingDeepLink: $pendingDeepLink
                )
                .id("main")
                .transition(viewModel.leadingTransition)
                .zIndex(0)
                .environment(deliveryManager)
                #if !os(visionOS)
                .environment(healthManager)
                #endif
                .environment(insightManager)
                .environment(weatherManager)
                .environment(locationManager)
                .environment(exportManager)
                .environment(cloudSyncManager)
                .task {
                    weatherManager.setLocationProvider(LocationManager())
                }
            }
        }
        .task {
            // Ensure managers exist in the View
            await MainActor.run {
                if self.deliveryManager == nil {
                    self.deliveryManager = DeliveryManager(context: modelContext)
                }
                if self.weatherManager.locationManager == nil {
                    self.weatherManager.setLocationProvider(LocationManager())
                }
                if self.insightManager == nil, let deliveryManager {
                    self.insightManager = InsightManager(deliveryManager: deliveryManager)
                }
                // Configure cloud sync manager with model context
                self.cloudSyncManager.configure(with: modelContext)
            }
            await viewModel.prepareApp(isOnboardingComplete: isOnboardingComplete)
        }
        .onAppear {
            viewModel.configure(cloudSyncManager: cloudSyncManager)
        }
    }
}

#Preview {
    // Create an in-memory SwiftData container for previews
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for: Delivery.self, Baby.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Preview ModelContainer setup failed: \(error)")
    }

    return ContentView(
        pendingDeepLink: .constant(nil)
    )
    .modelContainer(container)
    .environment(DeliveryManager(context: container.mainContext))
    #if !os(visionOS)
    .environment(HealthManager())
    #endif
    .environment(WeatherManager())
    .environment(LocationManager())
    .environment(CloudSyncManager())
}
