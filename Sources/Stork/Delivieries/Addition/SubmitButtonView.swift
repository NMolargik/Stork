//
//  SubmitButtonView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct SubmitButtonView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel
    @ObservedObject var dailyResetUtility: DailyResetUtility
    
    var body: some View {
        if deliveryViewModel.isWorking {
            ProgressView()
                .frame(height: 50)
        } else {
            CustomButtonView(
                text: deliveryViewModel.selectedHospital?.facility_name == nil ? "No Hospital Selected" : "Submit Delivery",
                width: 250,
                height: 50,
                color: Color.green,
                isEnabled: deliveryViewModel.canSubmitDelivery,
                onTapAction: {
                    Task {
                        await submitDelivery()
                        deliveryViewModel.startNewDelivery()
                    }
                }
            )
        }
    }

    private func submitDelivery() async {
        deliveryViewModel.isWorking = true
        defer { deliveryViewModel.isWorking = false }
        
        guard let hospital = deliveryViewModel.selectedHospital else {
            handleDeliveryError("No hospital selected")
            return
        }
        deliveryViewModel.newDelivery.hospitalName = hospital.facility_name
        deliveryViewModel.newDelivery.hospitalId = hospital.id
        
        let babyCount = deliveryViewModel.newDelivery.babies.count
        
        do {
            try await deliveryViewModel.submitDelivery(profile: profileViewModel.profile, dailyResetUtility: dailyResetUtility)
        } catch {
            handleDeliveryError(error.localizedDescription)
            return
        }
        
        await hospitalViewModel.updateHospitalWithNewDelivery(hospital: hospital, babyCount: babyCount)
        
        appStateManager.showingDeliveryAddition = false
    }

    private func handleDeliveryError(_ message: String) {
        withAnimation {
            appStateManager.errorMessage = message
        }
        appStateManager.showingDeliveryAddition = false
    }
}

#Preview {
    SubmitButtonView(
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository()),
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()),
        dailyResetUtility: DailyResetUtility()
    )
}
