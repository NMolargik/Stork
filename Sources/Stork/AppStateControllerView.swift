//
//  AppStateControllerView.swift
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI
import SkipRevenueCat
import StorkModel

enum AppState: String, Hashable {
    case splash, register, onboard, paywall, main
}

public struct AppStateControllerView: View {
    @AppStorage("appState") private var appState: AppState = .splash
    @AppStorage("errorMessage") private var errorMessage: String = ""
    @AppStorage("selectedTab") var selectedTab = Tab.home
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var hospitalViewModel: HospitalViewModel
    @StateObject private var deliveryViewModel: DeliveryViewModel
    @StateObject private var musterViewModel: MusterViewModel
    
    @State private var showRegistration: Bool = false
    @State private var paywallPresented: Bool = false
    
    // Repositories
    private let deliveryRepository: DeliveryRepositoryInterface
    private let hospitalRepository: HospitalRepositoryInterface
    private let profileRepository: ProfileRepositoryInterface
    private let musterRepository: MusterRepositoryInterface
    private let locationProvider: LocationProviderInterface
    
    // MARK: - Initializer
    public init(
        deliveryRepository: DeliveryRepositoryInterface = DefaultDeliveryRepository(remoteDataSource: FirebaseDeliveryDataSource()),
        hospitalRepository: HospitalRepositoryInterface = DefaultHospitalRepository(remoteDataSource: FirebaseHospitalDatasource()),
        profileRepository: ProfileRepositoryInterface = DefaultProfileRepository(remoteDataSource: FirebaseProfileDataSource()),
        musterRepository: MusterRepositoryInterface = DefaultMusterRepository(remoteDataSource: FirebaseMusterDataSource()),
        locationProvider: LocationProviderInterface = LocationProvider()
    ) {
        self.deliveryRepository = deliveryRepository
        self.hospitalRepository = hospitalRepository
        self.profileRepository = profileRepository
        self.musterRepository = musterRepository
        self.locationProvider = locationProvider
        
        // Initialize ViewModels with repositories
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(profileRepository: profileRepository))
        _hospitalViewModel = StateObject(wrappedValue: HospitalViewModel(hospitalRepository: hospitalRepository, locationProvider: locationProvider))
        _deliveryViewModel = StateObject(wrappedValue: DeliveryViewModel(deliveryRepository: deliveryRepository))
        _musterViewModel = StateObject(wrappedValue: MusterViewModel(musterRepository: musterRepository))
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            Group {
                switch appState {
                case .splash:
                    SplashView(
                        showRegistration: $showRegistration,
                        onAuthenticated: {
                            // User is now logged in
                            print("SplashView -> onAuthenticated: logged in")
                            self.loggedIn = true
                            // Let checkAppState() handle subscription + onboarding
                            checkAppState()
                        }
                    )
                    
                case .register:
                    RegisterView(
                        showRegistration: $showRegistration,
                        onAuthenticated: {
                            print("SplashView -> onAuthenticated: registered")
                            self.loggedIn = true
                            self.showRegistration = false
                            checkAppState()
                        }
                    )
                    
                case .paywall:
                    PaywallView(isPresented: $paywallPresented)
                        .onChange(of: paywallPresented) { newValue in
                            print("Paywall showing?: \(newValue)")
                            // If user closes or completes paywall, re-check state
                            checkAppState()
                        }
                    
                case .onboard:
                    OnboardingView {
                        // Onboarding done, re-check where to go next
                        print("Onboarding complete")
                        checkAppState()
                    }
                    
                case .main:
                    MainView()
                }
            }
            .onAppear {
                // Always check state when view appears
                checkAppState()
            }
            
            if !errorMessage.isEmpty {
                ErrorToastView()
            }
        }
        .onChange(of: appState) { _ in
            // If something sets appState externally, re-check
            checkAppState()
        }
        .environmentObject(profileViewModel)
        .environmentObject(hospitalViewModel)
        .environmentObject(deliveryViewModel)
        .environmentObject(musterViewModel)
    }
    
    // MARK: - Main Decision Logic
    func checkAppState() {
        print("Checking app state...")
        if loggedIn {
            Task {
                do {
                    // Fetch any needed data
                    try await fetchDataIfNeeded()
                    
                    // Attempt RevenueCat login using profile ID (if not empty)
                    try await handlePurchasesLogin()
                    
                    // Decide the next state
                    appState = computeNextAppState()
                    
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            // If not logged in, decide between splash or register
            appState = showRegistration ? .register : .splash
        }
    }
    
    // MARK: - Compute Next AppState
    /// Centralized logic for deciding which screen to show next.
    private func computeNextAppState() -> AppState {
        // If not logged in, either we are registering or showing splash
        guard loggedIn else {
            return showRegistration ? .register : .splash
        }
        
        // Logged in, so check onboarding and subscription
        if !isOnboardingComplete {
            return .onboard
        }
        
        if !Store.shared.subscriptionActive {
            return .paywall
        }
        
        return .main
    }
    
    // MARK: - Fetch Data
    /// Retrieves Profile, Deliveries, and (optionally) the current Muster
    private func fetchDataIfNeeded() async throws {
        // Fetch profile if we don’t have it
        if profileViewModel.profile.email.isEmpty {
            try await profileViewModel.fetchCurrentProfile()
        }
        
        // Fetch deliveries if empty
        if deliveryViewModel.deliveries.isEmpty {
            try await deliveryViewModel.getUserDeliveries(profile: profileViewModel.profile)
        }
        
        // Fetch muster if needed
        if !profileViewModel.profile.musterId.isEmpty, musterViewModel.currentMuster == nil {
            try await musterViewModel.loadCurrentMuster(
                profileViewModel: profileViewModel,
                deliveryViewModel: deliveryViewModel
            )
            if let muster = musterViewModel.currentMuster {
                try await deliveryViewModel.getMusterDeliveries(muster: muster)
            }
        }
    }
    
    // MARK: - Purchases / RevenueCat
    /// Logs into RevenueCat if we have a valid user ID
    private func handlePurchasesLogin() async throws {
        let userId = profileViewModel.profile.id
        guard !userId.isEmpty else { return }
        
        try await withCheckedThrowingContinuation { continuation in
            Purchases.sharedInstance.logIn(
                newAppUserID: userId,
                onError: { error in
                    continuation.resume(throwing: PurchaseError.purchaseLogInError(error.message))
                },
                onSuccess: { _, _ in
                    continuation.resume(returning: ())
                }
            )
        }
    }
}

// MARK: - Preview with mock repositories
#Preview {
    AppStateControllerView(
        deliveryRepository: MockDeliveryRepository(),
        hospitalRepository: MockHospitalRepository(),
        profileRepository: MockProfileRepository(),
        musterRepository: MockMusterRepository(),
        locationProvider: MockLocationProvider()
    )
    .padding()
}
