//
//  AppStateControllerView.swift
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI
import SkipRevenueCat
import StorkModel

func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    #if !SKIP
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
    #endif
}

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
                    PaywallMainView(
                        onCompleted: {
                            print("Paywall dismissed")
                            checkAppState()
                        },
                        signOut: {
                            print("User signed out from paywall")
                            profileViewModel.signOut()
                            checkAppState()
                        }
                    )
                    
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
                    appState = await computeNextAppState()
                    
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
    private func computeNextAppState() async -> AppState {
        // If not logged in, either we are registering or showing splash
        guard loggedIn else {
            return showRegistration ? .register : .splash
        }

        // Logged in, so check onboarding and subscription
        if !isOnboardingComplete {
            return .onboard
        }

        #if !SKIP
        // Wait for RevenueCat to complete before proceeding
        await fetchCustomerInfo()
        #endif

        if !Store.shared.subscriptionActive {
            return .paywall
        }

        return .main
    }

    #if !SKIP
    // MARK: - Fetch Customer Info from RevenueCat
    /// Ensures RevenueCat's customer info is retrieved before proceeding.
    private func fetchCustomerInfo() async {
        await withCheckedContinuation { continuation in
            Purchases.sharedInstance.getCustomerInfo(
                fetchPolicy: ModelsCacheFetchPolicy.cachedOrFetched,
                onError: { _ in
                    continuation.resume()
                },
                onSuccess: { _ in
                    continuation.resume()
                }
            )
        }
    }
    #endif
    
    // MARK: - Fetch Data
    /// Retrieves Profile, Deliveries, and (optionally) the current Muster
    private func fetchDataIfNeeded() async throws {
        // Fetch profile if we don’t have it
        if profileViewModel.profile.email.isEmpty {
            try await profileViewModel.fetchCurrentProfile()
        }

        if hospitalViewModel.hospitals.isEmpty {
            await hospitalViewModel.fetchHospitalsNearby()
        }

        // Reset pagination before fetching deliveries
        deliveryViewModel.currentPage = 0
        deliveryViewModel.hasMorePages = true

        // Fetch deliveries if empty
        if deliveryViewModel.groupedDeliveries.isEmpty {
            try await deliveryViewModel.fetchNextDeliveries(profile: profileViewModel.profile)
        }

        // Fetch muster if needed
        if !profileViewModel.profile.musterId.isEmpty, musterViewModel.currentMuster == nil {
            try await musterViewModel.loadCurrentMuster(
                profileViewModel: profileViewModel,
                deliveryViewModel: deliveryViewModel
            )
            
            if let muster = musterViewModel.currentMuster {
                // Fetch only the last 6 months of muster deliveries
                try await deliveryViewModel.fetchMusterDeliveries(muster: muster)
            }
        }
    }
    
    // MARK: - Purchases / RevenueCat
    /// Logs into RevenueCat if we have a valid user ID
    private func handlePurchasesLogin() async throws {
        let userId = profileViewModel.profile.id
        
        print("UserID: \(userId)")
        
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
