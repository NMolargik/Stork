//
//  DeliveryAdditionView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryAdditionView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel
    @ObservedObject var musterViewModel: MusterViewModel
    @ObservedObject var dailyResetUtility: DailyResetUtility
    
    @State private var showingDatePicker = false

    private let calendar = Calendar.current

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    DateSelectionView(
                        deliveryViewModel: deliveryViewModel,
                        selectedDate: $deliveryViewModel.newDelivery.date,
                        selectedTime: Binding(
                            get: { deliveryViewModel.newDelivery.date },
                            set: { newTime in
                                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: deliveryViewModel.newDelivery.date)
                                let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                dateComponents.hour = timeComponents.hour
                                dateComponents.minute = timeComponents.minute
                                dateComponents.second = 0
                                
                                if let combinedDate = Calendar.current.date(from: dateComponents) {
                                    deliveryViewModel.newDelivery.date = combinedDate
                                }
                            }
                        ),
                        showingDatePicker: $showingDatePicker
                    )
                    
                    BabyListView(babies: $deliveryViewModel.newDelivery.babies)

                    CustomButtonView(
                        text: "Add A Baby",
                        width: 250,
                        height: 50,
                        color: Color("storkIndigo"),
                        isEnabled: true,
                        onTapAction: {
                            withAnimation(.spring()) {
                                deliveryViewModel.addBaby()
                            }
                        }
                    )
                    .padding(.bottom)

                    Divider()
                    
                    ToggleSectionView(deliveryViewModel: deliveryViewModel, profileViewModel: profileViewModel)

                    DeliveryMethodPicker(deliveryMethod: $deliveryViewModel.newDelivery.deliveryMethod)

                    HospitalSelectionView(deliveryViewModel: deliveryViewModel, hospitalViewModel: hospitalViewModel, profileViewModel: profileViewModel)

                    Spacer(minLength: 10)

                    SubmitButtonView(
                        profileViewModel: profileViewModel,
                        deliveryViewModel: deliveryViewModel,
                        hospitalViewModel: hospitalViewModel,
                        dailyResetUtility: dailyResetUtility
                    )
                }
                .padding()
            }
        }
        .onAppear {
            initializeHospital()
            deliveryViewModel.addBaby()
        }
        .sheet(isPresented: $deliveryViewModel.isSelectingHospital) {
            HospitalListView(
                hospitalViewModel: hospitalViewModel,
                profileViewModel: profileViewModel,
                selectionMode: true,
                onSelection: { selectedHospital in
                    deliveryViewModel.selectedHospital = selectedHospital
                    deliveryViewModel.newDelivery.hospitalId = selectedHospital.id
                    deliveryViewModel.newDelivery.hospitalName = selectedHospital.facility_name
                    deliveryViewModel.isSelectingHospital = false
                }
            )
            .environmentObject(hospitalViewModel)
            .environmentObject(profileViewModel)
        }
        .onChange(of: deliveryViewModel.newDelivery.babies) { _ in
            deliveryViewModel.additionPropertiesChanged()
        }
        .onChange(of: deliveryViewModel.selectedHospital) { _ in
            deliveryViewModel.additionPropertiesChanged()
        }
    }

    // MARK: - Helper Functions
    
    @MainActor
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

    private func initializeHospital() {
        Task {
            if hospitalViewModel.primaryHospital == nil {
                await hospitalViewModel.getUserPrimaryHospital(profile: profileViewModel.profile)
            }
            deliveryViewModel.selectedHospital = hospitalViewModel.primaryHospital
        }
    }
}

#Preview {
    DeliveryAdditionView(
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository()),
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()),
        musterViewModel: MusterViewModel(musterRepository: MockMusterRepository()),
        dailyResetUtility: DailyResetUtility()
    )
    .environmentObject(AppStateManager.shared)
}
