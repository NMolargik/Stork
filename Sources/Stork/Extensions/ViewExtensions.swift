//
//  ViewExtensions.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/24/25.
//

import SkipFoundation
import SwiftUI
import StorkModel

public extension View {
    func backgroundCard(colorScheme: ColorScheme) -> some View {
        self.padding(5)
            .background {
                Rectangle()
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .cornerRadius(20)
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                
            }
            .padding(.horizontal, 5)
    }
    
    @MainActor func withMockEnvironmentObjects() -> some View {
        self
            .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()))
            .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
            .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
            .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
    }
    
    func hospitalTitleStyle(colorScheme: ColorScheme) -> some View {
        self
            .font(.title2)
            .fontWeight(.bold)
            .padding(10)
            .backgroundCard(colorScheme: colorScheme)
    }
    
    func hospitalStarStyle(colorScheme: ColorScheme) -> some View {
        self
            .foregroundStyle(.yellow)
            .scaledToFit()
            .frame(width: 24, height: 24)
            .padding(10)
            .background {
                Circle()
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .cornerRadius(20)
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
            }
    }
}
