//
//  ContentView.swift
//  Stork
//

import SwiftUI
import SwiftData

/// App-stage state machine: splash → onboarding → main.
/// Managers are constructed in `StorkApp` and arrive via the environment.
/// iCloud sync runs in the background; a toast keeps the user informed.
struct ContentView: View {
    @Environment(DeliveryManager.self) private var deliveryManager
    @Environment(ToastManager.self) private var toastManager

    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false

    @Binding var pendingDeepLink: DeepLink?

    @State private var viewModel = ViewModel()
    @State private var didShowSyncToast: Bool = false
    @State private var wasReturningUser: Bool = false

    var body: some View {
        ZStack {
            switch viewModel.appStage {
            case .splash:
                SplashView(
                    onContinue: {
                        viewModel.advance(to: .onboarding)
                    }
                )
                .id("splash")
                .transition(viewModel.leadingTransition)
                .zIndex(1)

            case .onboarding:
                OnboardingView(onFinished: {
                    isOnboardingComplete = true
                    viewModel.advance(to: .main)
                })
                .id("onboarding")
                .transition(viewModel.leadingTransition)
                .zIndex(1)

            case .main:
                MainView(pendingDeepLink: $pendingDeepLink)
                    .id("main")
                    .transition(viewModel.leadingTransition)
                    .zIndex(0)
                    .onAppear {
                        handleMainEntry()
                    }
            }
        }
        .task {
            wasReturningUser = isOnboardingComplete
            viewModel.prepareApp(isOnboardingComplete: isOnboardingComplete)
        }
    }

    /// On first entry to MainView for a returning user, surface a lightweight
    /// toast so they understand iCloud sync is running in the background, and
    /// nudge the local cache in case data arrived before managers were ready.
    private func handleMainEntry() {
        guard !didShowSyncToast, wasReturningUser else { return }
        didShowSyncToast = true

        toastManager.show(
            message: "Syncing with iCloud…",
            style: .info,
            icon: "icloud.fill"
        )

        Task {
            await deliveryManager.refresh()
        }
    }
}

#Preview {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: Delivery.self, Baby.self, DeliveryTag.self, configurations: config)
    }()

    ContentView(pendingDeepLink: .constant(nil))
        .modelContainer(container)
        .environment(DeliveryManager(container: container))
        .environment(CloudSyncManager())
        .environment(LocationManager())
        .environment(WeatherManager())
        .environment(ExportManager())
        .environment(ToastManager())
        #if !os(visionOS)
        .environment(HealthManager())
        #endif
}
