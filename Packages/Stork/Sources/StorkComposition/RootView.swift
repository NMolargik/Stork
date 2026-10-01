//
//  RootView.swift
//  StorkComposition
//
//  The app-stage state machine: splash → onboarding → main. The thin `@main` app hosts
//  this with `SessionController`, `AppRouter`, and `ToastManager` injected.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem
import StorkServices
import StorkFeatureOnboarding

public struct RootView: View {
    @Environment(SessionController.self) private var session
    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete = false

    @State private var toast = ToastManager()
    @State private var stage: AppStage = .splash
    @State private var didShowSyncToast = false
    @State private var wasReturningUser = false

    public init() {}

    public var body: some View {
        ZStack {
            switch stage {
            case .splash:
                SplashView { withAnimation { stage = .onboarding } }
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .onboarding:
                OnboardingView {
                    isOnboardingComplete = true
                    withAnimation { stage = .main }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .main:
                MainView(session: session)
                    .onAppear(perform: handleMainEntry)
            }
        }
        .toastContainer()
        .environment(toast)
        .task {
            wasReturningUser = isOnboardingComplete
            stage = isOnboardingComplete ? .main : .splash
        }
        .environment(session.locationManager)
        #if canImport(HealthKit) && !os(visionOS)
        .environment(session.healthManager)
        #endif
    }

    /// Returning users get a lightweight "syncing" toast and a cache nudge on first entry.
    private func handleMainEntry() {
        guard !didShowSyncToast, wasReturningUser else { return }
        didShowSyncToast = true
        toast.show(message: String(localized: "Syncing with iCloud…", bundle: .module), style: .info, icon: "icloud.fill")
    }
}
#endif
