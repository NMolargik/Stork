//
//  RootView.swift
//  StorkComposition
//
//  The app-stage state machine: splash → onboarding → main. The thin `@main` app hosts
//  this with `SessionController`, `AppRouter`, and `StatusCenter` injected.
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

    @State private var status = StatusCenter()
    @State private var stage: AppStage = .splash
    @Environment(\.scenePhase) private var scenePhase

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
            }
        }
        .environment(status)
        .environment(session.appLock)
        // Covers everything while locked, and while the app switcher snapshot is taken.
        .overlay {
            if session.appLock.isLocked || (session.appLock.isEnabled && scenePhase != .active) {
                AppLockView(lock: session.appLock)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: session.appLock.isLocked)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: session.appLock.sceneDidEnterBackground()
            case .active: session.appLock.sceneDidBecomeActive()
            default: break
            }
        }
        .task {
            stage = isOnboardingComplete ? .main : .splash
        }
        #if canImport(HealthKit) && !os(visionOS)
        .environment(session.healthManager)
        #endif
    }
}
#endif
