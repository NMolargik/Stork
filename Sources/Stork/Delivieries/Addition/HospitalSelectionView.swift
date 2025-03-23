//
//  HospitalSelectionView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct HospitalSelectionView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel
    @ObservedObject var profileViewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(deliveryViewModel.selectedHospital?.facility_name ?? "Please select a delivery location!")
                .font(.headline)
                .multilineTextAlignment(.center)

            CustomButtonView(
                text: "Change Hospital",
                width: 250,
                height: 50,
                color: Color.red,
                icon: Image("building.fill", bundle: .module),
                isEnabled: true,
                onTapAction: {
                    withAnimation {
                        deliveryViewModel.isSelectingHospital = !deliveryViewModel.isSelectingHospital
                    }
                }
            )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .backgroundCard(colorScheme: colorScheme)
    }
}

#Preview {
    HospitalSelectionView(
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager())
    )
}
