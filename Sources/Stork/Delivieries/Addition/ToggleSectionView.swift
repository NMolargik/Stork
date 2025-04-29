//
//  ToggleSectionView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct ToggleSectionView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var profileViewModel: ProfileViewModel

    var body: some View {
        if (profileViewModel.profile.musterId != "") {
            Toggle("Add To Muster", isOn: $deliveryViewModel.addToMuster)
                .foregroundStyle(useDarkMode ? Color.white : Color.black)
                .padding()
                .fontWeight(.bold)
                .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
                .tint(.green)
                .onAppear {
                    deliveryViewModel.addToMuster = true
                }
        }

        Toggle("Epidural Used", isOn: $deliveryViewModel.newDelivery.epiduralUsed)
            .foregroundStyle(useDarkMode ? Color.white : Color.black)
            .padding()
            .fontWeight(.bold)
            .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
            .tint(.green)
    }
}

#Preview {
    ToggleSectionView(
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository())
    )
}
