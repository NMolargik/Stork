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
    case splash, auth, onboard, main
}


public struct AppStateControllerView: View {
    @AppStorage("appState") private var appState: AppState = AppState.splash

//    @StateObject private var bottomBarViewModel = BottomBarViewModel()
//    @StateObject private var profileViewModel: ProfileViewModel
//    @State var viewState: ViewState = .splash
    
    /// The repositories passed down to child views.
    private let deliveryRepository: DeliveryRepositoryInterface
    private let hospitalRepository: HospitalRepositoryInterface
    private let profileRepository: ProfileRepositoryInterface
    private let musterRepository: MusterRepositoryInterface
    
    /// Initializes the RootView with the required dependencies.
    ///
    /// - Parameter deliveryRepository: An instance of `DeliveryRepository` to be used in the app.
    /// - Parameter hospitalRepository: An instance of `HospitalRepository` to be used in the app.
    /// - Parameter profileRepository: An instance of `ProfileRepository` to be used in the app.
    /// - Parameter musterRepository: An instance of `MusterRepository` to be used in the app.
    public init(
        deliveryRepository: DeliveryRepositoryInterface,
        hospitalRepository: HospitalRepositoryInterface,
        profileRepository: ProfileRepositoryInterface,
        musterRepository: MusterRepositoryInterface
    ) {
        self.deliveryRepository = deliveryRepository
        self.hospitalRepository = hospitalRepository
        self.profileRepository = profileRepository
        self.musterRepository = musterRepository
//        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(profileRepository: profileRepository))
    }
    
    public var body: some View {
        ZStack {
            Group {
                Text("Yo")
                switch appState {
                case .splash:
                    SplashView()
                    //                case .onboarding:
                    //                    OnboardingView(viewState: $viewState)
                    //                case .auth:
                    //                    AuthFlowView(viewState: $viewState)
                    //                        .environmentObject(profileViewModel)
                    //                case .mainApp:
                    //                    MainView(
                    //                        viewState: $viewState,
                    //                        deliveryRepository: deliveryRepository,
                    //                        hospitalRepository: hospitalRepository,
                    //                        locationManager: locationManager,
                    //                        onSignOut: {
                    //                            profileViewModel.reset()
                    //                            viewState = ViewState.splash
                    //                        }
                    //                    )
                    //                }
                case .auth:
                    Text("Auth")
                case .onboard:
                    Text("Onboard")

                case .main:
                    Text("Main")

                }
            }
//            .background {
//                LinearGradient(
//                    gradient: Gradient(colors: [Color("primaryColor"), Color.indigo.opacity(0.8)]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .ignoresSafeArea()
//                
//            }
//            .environmentObject(bottomBarViewModel)
//            .environmentObject(profileViewModel)
//            .onAppear {
//                checkAppState()
//            }
        }
    }
    
    func checkAppState() {
        if isUserLoggedIn() {
//            if (profileViewModel.profile == nil) {
//                Task {
//                    let getCurrentProfileUseCase = GetCurrentProfileUseCase(profileRepository: profileRepository)
//                    profileViewModel.profile = try await getCurrentProfileUseCase.execute()
//
//                    withAnimation {
//                        viewState = .mainApp
//                    }
//                }
//            } else {
//                viewState = .mainApp
//            }
//        } else {
//            viewState = hasCompletedOnboarding() ? .auth : .splash
        }
    }
        
    
    private func isUserLoggedIn() -> Bool {
        return profileRepository.isAuthenticated()
    }
    
    private func hasCompletedOnboarding() -> Bool {
        // Check UserDefaults or similar for onboarding completion
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

#Preview {
    AppStateControllerView(
        deliveryRepository: MockDeliveryRepository(),
        hospitalRepository: MockHospitalRepository(),
        profileRepository: MockProfileRepository(),
        musterRepository: MockMusterRepository()
    )
}
