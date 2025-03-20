//
//  ToggleSectionView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct ToggleSectionView: View {
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var profileViewModel: ProfileViewModel

    var body: some View {
        if (profileViewModel.profile.musterId != "") {
            Toggle("Add To Muster", isOn: $deliveryViewModel.addToMuster)
                .padding()
                .fontWeight(.bold)
                .backgroundCard(colorScheme: colorScheme)
                .tint(.green)
                .onAppear {
                    deliveryViewModel.addToMuster = true
                }
        }

        Toggle("Epidural Used", isOn: $deliveryViewModel.newDelivery.epiduralUsed)
            .padding()
            .fontWeight(.bold)
            .backgroundCard(colorScheme: colorScheme)
            .tint(.green)
    }
}

#Preview {
    ToggleSectionView(
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager())
    )
}
