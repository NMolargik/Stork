//
//  AppStateControllerView.swift
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI
import StorkModel

enum AppState: String, Hashable {
    case splash, register, onboard, paywall, main
}

public struct AppStateControllerView: View {
    @AppStorage("appState") private var appState: AppState = .splash
    @AppStorage("errorMessage") private var errorMessage: String = ""
    @AppStorage("selectedTab") var selectedTab = Tab.hospitals
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @AppStorage("isPaywallComplete") private var isPaywallComplete: Bool = false
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var hospitalViewModel: HospitalViewModel
    @StateObject private var deliveryViewModel: DeliveryViewModel
    @StateObject private var musterViewModel: MusterViewModel
    
    @State private var showRegistration: Bool = false
    
    // Repositories
    private let deliveryRepository: DeliveryRepositoryInterface
    private let hospitalRepository: HospitalRepositoryInterface
    private let profileRepository: ProfileRepositoryInterface
    private let musterRepository: MusterRepositoryInterface
    private let locationProvider: LocationProviderInterface
    
    // Initializer
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
    
    public var body: some View {
        ZStack {
            Group {
                switch appState {
                case .splash:
                    SplashView(showRegistration: $showRegistration)
                case .register:
                    RegisterView(
                        showRegistration: $showRegistration,
                        onAuthenticated: {
                            withAnimation {
                                self.loggedIn = true
                                self.showRegistration = false
                                
                                if (self.isOnboardingComplete) {
                                    if (self.isPaywallComplete) {
                                        appState = AppState.main
                                    } else {
                                        appState = AppState.paywall
                                    }
                                } else {
                                    appState = AppState.onboard
                                }
                            }
                        }
                    )
                case .paywall:
                    PaywallView()
                case .onboard:
                    OnboardingView()
                case .main:
                    MainView()
                }
            }
            .onAppear {
                print("Started")
                checkAppState()
            }
            
            if !errorMessage.isEmpty {
                ErrorToastView()
            }
        }
        .onChange(of: appState) { _ in
            checkAppState()
        }
        .environmentObject(profileViewModel)
        .environmentObject(hospitalViewModel)
        .environmentObject(deliveryViewModel)
        .environmentObject(musterViewModel)
    }
    
    func checkAppState() {
        if loggedIn {
            if profileViewModel.profile.email.isEmpty {
                Task {
                    do {
                        try await profileViewModel.fetchCurrentProfile()
                        
                        try await deliveryViewModel.getUserDeliveries(profile: profileViewModel.profile)
                        withAnimation {
                            selectedTab = .home
                            appState = .main
                        }
                    } catch {
                        errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    }
                }
            } else {
                if (isOnboardingComplete) {
                    selectedTab = .home
                    appState = .main
                } else {
                    appState = .onboard
                }
            }
        } else {
            appState = showRegistration ? .register : .splash
        }
    }
}

// Preview with mock repositories
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
