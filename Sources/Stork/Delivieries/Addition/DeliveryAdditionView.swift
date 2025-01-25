//
//  DeliveryAdditionView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryAdditionView: View {
    // MARK: - AppStorage
    @AppStorage("errorMessage") var errorMessage: String = ""

    // MARK: - Environment Objects
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var dailyResetManager: DailyResetManager

    // MARK: - Binding
    @Binding var showingDeliveryAddition: Bool

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Baby Editor Views with Enhanced Transitions
                    ForEach($deliveryViewModel.newDelivery.babies) { $baby in
                        let babyIndex = deliveryViewModel.newDelivery.babies.firstIndex(where: { $0.id == baby.id }) ?? 0
                        let babyNumber = babyIndex + 1
                        
                        BabyEditorView(
                            baby: $baby,
                            babyNumber: babyNumber,
                            removeBaby: { babyId in
                                withAnimation(.spring()) {
                                    deliveryViewModel.newDelivery.babies.removeAll { $0.id == babyId }
                                }
                            }
                        )
                        .id(baby.id)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // MARK: - Add A Baby Button Positioned Below ScrollView
                    CustomButtonView(
                        text: "Add A Baby",
                        width: 250,
                        height: 50,
                        color: Color.indigo,
                        icon: nil,
                        isEnabled: true,
                        onTapAction: {
                            withAnimation(.spring()) {
                                deliveryViewModel.addBaby()
                            }
                        }
                    )
                    .padding(.bottom)
                    
                    Divider()
                    
                    // MARK: - Epidural Used Toggle
                    Toggle("Epidural Used", isOn: $deliveryViewModel.newDelivery.epiduralUsed)
                        .padding()
                        .fontWeight(.bold)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.orange.opacity(0.2))
                        )
                        .tint(.green)
                    
                    // MARK: - Add To Muster Toggle (Conditional)
                    if !profileViewModel.profile.musterId.isEmpty {
                        Toggle("Add To Muster", isOn: $deliveryViewModel.addToMuster)
                            .padding()
                            .fontWeight(.bold)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.orange.opacity(0.2))
                            )
                            .tint(.green)
                    }
                    
                    // MARK: - Delivery Method Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Delivery Method")
                            .font(.headline)
                        
                        Picker("Delivery Method", selection: $deliveryViewModel.newDelivery.deliveryMethod) {
                            ForEach(DeliveryMethod.allCases, id: \.self) { method in
                                Text(method.description).tag(method)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: deliveryViewModel.newDelivery.deliveryMethod) { _ in
                            triggerHaptic()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.2))
                    )
                    
                    // MARK: - Select Hospital Section
                    VStack(alignment: .center, spacing: 10) {
                        Text(deliveryViewModel.selectedHospital?.facility_name ?? "No Hospital Selected")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        CustomButtonView(
                            text: "Change Hospital",
                            width: 250,
                            height: 50,
                            color: Color.red,
                            icon: Image(systemName: "building"),
                            isEnabled: true,
                            onTapAction: {
                                deliveryViewModel.isSelectingHospital = true
                            }
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.2))
                    )
                    
                    Spacer(minLength: 10)
                    
                    // MARK: - Submit Delivery Button or ProgressView
                    if deliveryViewModel.isWorking {
                        ProgressView()
                            .frame(height: 50)
                    } else {
                        CustomButtonView(
                            text: "Submit Delivery",
                            width: 250,
                            height: 50,
                            color: Color.green,
                            isEnabled: deliveryViewModel.canSubmitDelivery,
                            onTapAction: {
                                Task {
                                    await submitDelivery()
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .onAppear {
            withAnimation(.spring()) {
                if deliveryViewModel.newDelivery.babies.isEmpty {
                    deliveryViewModel.addBaby()
                }
                
                if !profileViewModel.profile.musterId.isEmpty {
                    deliveryViewModel.addToMuster = true
                }
                
                initializeHospital()
            }
        }
        .sheet(isPresented: $deliveryViewModel.isSelectingHospital) {
            HospitalListView(
                selectionMode: true,
                onSelection: { selectedHospital in
                    print("selectedHospital: \(selectedHospital.facility_name)")
                    deliveryViewModel.selectedHospital = selectedHospital
                    deliveryViewModel.newDelivery.hospitalId = selectedHospital.id
                    deliveryViewModel.newDelivery.hospitalName = selectedHospital.facility_name
                    deliveryViewModel.isSelectingHospital = false
                }
            )
            .interactiveDismissDisabled()
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
    
    /// Initializes the selected hospital when the view appears.
    private func initializeHospital() {
        Task {
            if hospitalViewModel.primaryHospital == nil {
                await hospitalViewModel.getUserPrimaryHospital(profile: profileViewModel.profile)
            }
            
            deliveryViewModel.selectedHospital = hospitalViewModel.primaryHospital
        }
    }
    
    // MARK: - Submit Delivery Function
    
    @MainActor
    private func submitDelivery() async {
        deliveryViewModel.isWorking = true
        defer { deliveryViewModel.isWorking = false }
        
        guard let hospital = deliveryViewModel.selectedHospital else {
            errorMessage = "No hospital selected"
            return
        }
        deliveryViewModel.newDelivery.hospitalName = hospital.facility_name
        deliveryViewModel.newDelivery.hospitalId = hospital.id
        
        let babyCount = deliveryViewModel.newDelivery.babies.count
        
        do {
            try await deliveryViewModel.submitDelivery(profile: profileViewModel.profile, dailyResetManager: dailyResetManager)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        
        await hospitalViewModel.updateHospitalWithNewDelivery(hospital: hospital, babyCount: babyCount)
        
        showingDeliveryAddition = false
    }
}

#Preview {
    DeliveryAdditionView(showingDeliveryAddition: .constant(true))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(DailyResetManager())
}
