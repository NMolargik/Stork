//
//  AppStateControllerView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI
import StorkModel

enum AppState : String, Hashable {
    case splash, register, onboard, main
}

public struct AppStateControllerView: View {
    @AppStorage("appState") private var appState: AppState = AppState.splash
    @AppStorage("errorMessage") private var errorMessage: String = ""
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false

    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var hospitalViewModel: HospitalViewModel
    @StateObject private var deliveryViewModel: DeliveryViewModel
    @StateObject private var musterViewModel: MusterViewModel
    
    @State var showRegistration: Bool = false
    
    /// The repositories passed down to child views.
    private let deliveryRepository: DeliveryRepositoryInterface
    private let hospitalRepository: HospitalRepositoryInterface
    private let profileRepository: ProfileRepositoryInterface
    private let musterRepository: MusterRepositoryInterface
    private let locationProvider: LocationProviderInterface
    
    /// Initializes the RootView with the required dependencies.
    ///
    /// - Parameter deliveryRepository: An instance of `DeliveryRepositoryInterface` to be used in the app.
    /// - Parameter hospitalRepository: An instance of `HospitalRepositoryInterface` to be used in the app.
    /// - Parameter profileRepository: An instance of `ProfileRepositoryInterface` to be used in the app.
    /// - Parameter musterRepository: An instance of `MusterRepositoryInterface` to be used in the app.
    /// - Parameter locationManager: An instance of `LocationManagerInterface` to be used in the app.
    public init(
        deliveryRepository: DeliveryRepositoryInterface,
        hospitalRepository: HospitalRepositoryInterface,
        profileRepository: ProfileRepositoryInterface,
        musterRepository: MusterRepositoryInterface,
        locationProvider: LocationProviderInterface
    ) {
        self.deliveryRepository = deliveryRepository
        self.hospitalRepository = hospitalRepository
        self.profileRepository = profileRepository
        self.musterRepository = musterRepository
        self.locationProvider = locationProvider
        
        // Initialize profileViewModel with profileRepository
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
                    RegisterView(showRegistration: $showRegistration, onAuthenticated: {
                        withAnimation {
                            self.appState = self.isOnboardingComplete ? .main : .onboard
                        }
                    })
                case .onboard:
                    Button(action: {
                        withAnimation {
                            appState = AppState.main
                        }
                    }, label: {
                        Text("Skip Onboarding")
                            .foregroundStyle(.blue)
                    })
                case .main:
                    MainView()

                }
            }
            .onAppear {
                print("Started")
                checkAppState()
            }
            
            if (errorMessage != "") {
                ErrorToastView()
            }
        }
        .environmentObject(profileViewModel)
        .environmentObject(hospitalViewModel)
        .environmentObject(deliveryViewModel)
        .environmentObject(musterViewModel)
    }
    
    func checkAppState() {
        if isUserLoggedIn() {
            if profileViewModel.profile.email == "" {
                Task {
                    do {
                        profileViewModel.profile = try await profileViewModel.profileRepository.getCurrentProfile()
                        withAnimation {
                            appState = .main
                        }
                    } catch {
                        
                        errorMessage = "Failed to load profile: \(error.localizedDescription)"
                        return
                    }
                }
            } else {
                appState = .main
            }
        } else {
            appState = isOnboardingComplete ? .main : .splash
        }
    }
    
    private func isUserLoggedIn() -> Bool {
        return profileRepository.isAuthenticated()
    }
}

#Preview {
    AppStateControllerView(
        deliveryRepository: MockDeliveryRepository(),
        hospitalRepository: MockHospitalRepository(),
        profileRepository: MockProfileRepository(),
        musterRepository: MockMusterRepository(),
        locationProvider: MockLocationProvider()
    )
    .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
    .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
    .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
