//
//  RootView.swift
//
//  Created by Nick Molargik on 11/4/24.
//

import SkipFoundation
import SwiftUI
import SkipRevenueCat
import StorkModel
import OSLog

#if !SKIP
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
#else
import SkipFirebaseCore
import SkipFirebaseFirestore
import SkipFirebaseAuth
#endif

let logger = Logger(subsystem: "com.nickmolargik.stork", category: "Stork")
let androidSDK = ProcessInfo.processInfo.environment["android.os.Build.VERSION.SDK_INT"].flatMap { Int($0) }

public struct RootView: View {
    @AppStorage(StorageKeys.isOnboardingComplete) var isOnboardingComplete: Bool = false
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    @StateObject private var appStateManager: AppStateManager = AppStateManager.shared

    @StateObject private var profileViewModel: ProfileViewModel
    
    @StateObject private var hospitalViewModel = HospitalViewModel(hospitalRepository: DefaultHospitalRepository(remoteDataSource: FirebaseHospitalDatasource()), locationProvider: LocationProvider())
    @StateObject private var deliveryViewModel = DeliveryViewModel(deliveryRepository: DefaultDeliveryRepository(remoteDataSource: FirebaseDeliveryDataSource()))
    @StateObject private var musterViewModel = MusterViewModel(musterRepository: DefaultMusterRepository(remoteDataSource: FirebaseMusterDataSource()))
    
    @State private var showRegistration: Bool = false
    
    public init() {
        _profileViewModel = StateObject(
            wrappedValue: ProfileViewModel(
                profileRepository: DefaultProfileRepository(remoteDataSource: FirebaseProfileDataSource())
            )
        )
    }

    // MARK: - Body
    public var body: some View {
        ZStack {
            Group {
                switch appStateManager.currentAppScreen {
                case .splash:
                    SplashView(
                        profileViewModel: profileViewModel,
                        showRegistration: $showRegistration,
                        onAuthenticated: { checkAppState() }
                    )
                    .environmentObject(appStateManager)
                    .onChange(of: appStateManager.currentAppScreen) { screen in
                        print(screen.rawValue)
                    }
                    .transition(.opacity)

                case .register:
                    RegisterView(
                        profileViewModel: profileViewModel,
                        showRegistration: $showRegistration,
                        onAuthenticated: { checkAppState() }
                    )
                    .environmentObject(appStateManager)
                    .transition(.move(edge: .bottom))

                case .paywall:
                    PaywallMainView(
                        onCompleted: { checkAppState() },
                        signOut: {
                            profileViewModel.signOut()
                            checkAppState()
                        }
                    )
                        .environmentObject(appStateManager)
                        .transition(.opacity)

                case .onboard:
                    OnboardingView {
                        checkAppState()
                    }
                        .environmentObject(appStateManager)
                        .transition(.slide)

                case .main:
                    TabControllerView(
                        profileViewModel: profileViewModel,
                        hospitalViewModel: hospitalViewModel,
                        deliveryViewModel: deliveryViewModel,
                        musterViewModel: musterViewModel
                    )
                    .environmentObject(appStateManager)
                    .transition(.opacity)
                }
            }
            .preferredColorScheme(useDarkMode ? .dark : .light)
            .onAppear {
                logger.log("Welcome to Stork on \(androidSDK != nil ? "Android" : "Darwin")!")
                
                configurePurchasesIfNeeded()

                if !hospitalViewModel.locationProvider.isAuthorized() {
                    Task {
                        try await hospitalViewModel.locationProvider.fetchCurrentLocation()
                    }
                }

                checkAppState()
            }

            if !appStateManager.errorMessage.isEmpty {
                ErrorToastView()
                    .environmentObject(appStateManager)
                    .padding(.top, 50)
                    .transition(.move(edge: .top))
                    .animation(.default, value: appStateManager.errorMessage)
            }
        }
    }

    // MARK: - Main Decision Logic
    func checkAppState() {
        if Auth.auth().currentUser != nil  {
            Task {
                do {
                    try await fetchProfileIfNeeded()
                    try await handlePurchasesLogin()

                    let nextState = await computeNextAppScreen()
                    withAnimation {
                        appStateManager.currentAppScreen = nextState
                    }
                    
                    try await fetchDataIfNeeded()
                } catch {
                    withAnimation {
                        appStateManager.errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            withAnimation {
                appStateManager.currentAppScreen = .splash
            }
        }
    }

    private func computeNextAppScreen() async -> AppScreen {
        guard Auth.auth().currentUser != nil else {
            return showRegistration ? .register : .splash
        }

        if !isOnboardingComplete {
            return .onboard
        }

        
        // !!! These are what ensure subscriptions
        await fetchCustomerInfo()
        // TODO: remove when Android paywall is ready
        #if !SKIP
        if !Store.shared.subscriptionActive {
            return .paywall
        }
        #endif
        //


        return .main
    }

    private func fetchCustomerInfo() async {
//        await withCheckedContinuation { continuation in
//            Purchases.sharedInstance.getCustomerInfo(
//                fetchPolicy: ModelsCacheFetchPolicy.cachedOrFetched,
//                onError: { _ in continuation.resume() },   // Explicitly ignore the argument
//                onSuccess: { _ in continuation.resume() }  // Explicitly ignore the argument
//            )
//        }
    }
    
    // MARK: - Fetch Data
    private func fetchDataIfNeeded() async throws {
        hospitalViewModel.isWorking = true
        deliveryViewModel.isWorking = true
        musterViewModel.isWorking = true
        
        defer {
            hospitalViewModel.isWorking = false
            deliveryViewModel.isWorking = false
            musterViewModel.isWorking = false
        }

        do {
            try await fetchDeliveriesIfNeeded()
            try await fetchHospitalsIfNeeded()
            try await fetchMusterIfNeeded()
        } catch {
            throw error
        }
    }

    private func fetchProfileIfNeeded() async throws {
        if profileViewModel.profile.email.isEmpty {
            try await profileViewModel.fetchCurrentProfile()
        }
    }

    private func fetchDeliveriesIfNeeded() async throws {
        if deliveryViewModel.groupedDeliveries.isEmpty && appStateManager.currentAppScreen == .main {
            print(deliveryViewModel.deliveries.count)
            deliveryViewModel.currentPage = 0
            deliveryViewModel.hasMorePages = true
            try await deliveryViewModel.fetchNextDeliveries(profile: profileViewModel.profile)
        }
    }

    private func fetchHospitalsIfNeeded() async throws {
        if hospitalViewModel.hospitals.isEmpty && appStateManager.currentAppScreen == .main {
            await hospitalViewModel.fetchHospitalsNearby()
        }
    }

    private func fetchMusterIfNeeded() async throws {
        if !profileViewModel.profile.musterId.isEmpty && musterViewModel.currentMuster == nil && appStateManager.currentAppScreen == .main {
            try await musterViewModel.loadCurrentMuster(
                profileViewModel: profileViewModel,
                deliveryViewModel: deliveryViewModel
            )
            if let muster = musterViewModel.currentMuster {
                try await deliveryViewModel.fetchMusterDeliveries(muster: muster)
            }
        }
    }

    private func handlePurchasesLogin() async throws {
        let userId = profileViewModel.profile.id
        
        guard !userId.isEmpty else { return }
        
        #if !SKIP
        
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
        
        #endif
    }

    private func configurePurchasesIfNeeded() {
        #if os(iOS) || SKIP
        guard !Purchases.isConfigured else { return }
        Purchases.logLevel = LogLevel.DEBUG
        Purchases.configure(apiKey: StoreConstants.apiKey)
        Purchases.sharedInstance.delegate = PurchasesDelegateHandler.shared
        #endif
    }
}

#Preview {
    RootView()
}
