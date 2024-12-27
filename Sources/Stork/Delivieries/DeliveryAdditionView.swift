//
//  DeliveryAdditionView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryAdditionView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""

    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    
    @Binding var showingDeliveryAddition: Bool
    
    @State private var selectedHospital: Hospital? = nil

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Baby Editor Views
                    ForEach($deliveryViewModel.newDelivery.babies) { $baby in
                        let babyIndex = deliveryViewModel.newDelivery.babies.firstIndex(where: { $0.id == baby.id }) ?? 0
                        let babyNumber = babyIndex + 1
                        
                        BabyEditorView(
                            baby: $baby,
                            babyNumber: babyNumber,
                            removeBaby: { babyId in
                                withAnimation {
                                    deliveryViewModel.newDelivery.babies.removeAll { $0.id == babyId }
                                    print("Removed baby with id \(babyId)")
                                }
                            }
                        )
                        .id(baby.id)
                    }
                    
                    // Delivery Options Section
                    VStack(alignment: .center, spacing: 8) {
                        HStack {
                            Spacer()
                            
                            CustomButtonView(
                                text: "Add A Baby",
                                width: 250,
                                height: 50,
                                color: Color.indigo,
                                icon: nil,
                                isEnabled: .constant(true),
                                onTapAction: {
                                    addBaby()
                                }
                            )
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .padding(.bottom, 10)
                    
                    VStack {
                        Toggle("Epidural Used", isOn: $deliveryViewModel.newDelivery.epiduralUsed)
                            .padding()
                            .fontWeight(.bold)
                            .background {
                                Color.indigo
                                    .opacity(0.2)
                                    .cornerRadius(10)
                            }
                            .tint(.green)
                    }
                    
                    if (profileViewModel.profile.musterId != "") {
                        VStack {
                            Toggle("Add To Muster", isOn: $deliveryViewModel.addToMuster)
                                .padding()
                                .fontWeight(.bold)
                                .background {
                                    Color.indigo
                                        .opacity(0.2)
                                        .cornerRadius(10)
                                }
                                .tint(.green)
                        }
                    }
                    
                    VStack {
                        Text("Delivery Method")
                            .font(.headline)
                        
                        Picker("Delivery Method", selection: $deliveryViewModel.newDelivery.deliveryMethod) {
                            ForEach(DeliveryMethod.allCases, id: \.self) { method in
                                Text(method.description).tag(method)
                            }
                        }
                        .padding(.bottom)
                        .pickerStyle(.segmented)
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background {
                        Color.indigo
                            .opacity(0.2)
                            .cornerRadius(10)
                    }
                    
                    VStack {
                        Text(selectedHospital?.facility_name ?? "No Hospital Selected")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        CustomButtonView(text: "Select A Hospital", width: 250, height: 40, color: Color.black, icon: Image(systemName: "building"), isEnabled: .constant(true), onTapAction: {
                            deliveryViewModel.isSelectingHospital = true
                        })
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background {
                        Color.indigo
                            .opacity(0.2)
                            .cornerRadius(10)
                    }
                    
                    
                    Spacer(minLength: 10)
                    
                    if deliveryViewModel.isWorking {
                        ProgressView()
                            .frame(height: 40)
                            .padding()
                    } else {
                        CustomButtonView(
                            text: "Submit Delivery",
                            width: 250,
                            height: 40,
                            color: Color.indigo,
                            isEnabled: $deliveryViewModel.submitEnabled,
                            onTapAction: {
                                Task {
                                    deliveryViewModel.isWorking = true
                                    guard let hospital = deliveryViewModel.selectedHospital else {
                                        errorMessage = "No hospital selected"
                                        deliveryViewModel.isWorking = false
                                        throw DeliveryError.creationFailed("No hospital selected")
                                    }
                                    
                                    do {
                                        try await deliveryViewModel.submitDelivery(profile: profileViewModel.profile)
                                    } catch {
                                        deliveryViewModel.isWorking = false
                                        errorMessage = error.localizedDescription
                                    }

                                    
                                    do {
                                        try await hospitalViewModel.updateHospitalWithNewDelivery(hospital: hospital, babyCount: deliveryViewModel.newDelivery.babies.count)
                                    } catch {
                                        deliveryViewModel.isWorking = false
                                        errorMessage = error.localizedDescription
                                    }

                                    deliveryViewModel.isWorking = false
                                    showingDeliveryAddition = false
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .onAppear {
            withAnimation {
                if (deliveryViewModel.newDelivery.babies.count == 0) {
                    addBaby()
                }
                
                Task {
                    if hospitalViewModel.primaryHospital == nil {
                        print(hospitalViewModel.primaryHospital)
                        try await hospitalViewModel.getUserPrimaryHospital(profile: profileViewModel.profile)
                    }
                    
                    print(hospitalViewModel.selectedHospital)
                    
                    selectedHospital = hospitalViewModel.primaryHospital
                }
            }
        }
        .onChange(of: deliveryViewModel.newDelivery.babies.count) { newCount in
            deliveryViewModel.submitEnabled = newCount > 0 && self.selectedHospital != nil
        }
        .onChange(of: selectedHospital) { _ in
            deliveryViewModel.submitEnabled = deliveryViewModel.newDelivery.babies.count > 0 && self.selectedHospital != nil
        }
        .sheet(isPresented: $deliveryViewModel.isSelectingHospital) {
            HospitalListView(
                selectionMode: true,
                onSelection: { selectedHospital in
                    print("selectedHospital: \(selectedHospital.facility_name)")
                    self.selectedHospital = selectedHospital
                    deliveryViewModel.selectedHospital = selectedHospital
                    deliveryViewModel.newDelivery.hospitalId = selectedHospital.id
                    deliveryViewModel.newDelivery.hospitalName = selectedHospital.facility_name
                    deliveryViewModel.isSelectingHospital = false
                }
            )
            .environmentObject(hospitalViewModel)
            .environmentObject(profileViewModel)
        }
    }

    private func addBaby() {
        let newBaby = Baby(deliveryId: UUID().uuidString, nurseCatch: false, sex: Sex.male)
        deliveryViewModel.newDelivery.babies.append(newBaby)
    }
}

#Preview {
    DeliveryAdditionView(showingDeliveryAddition: .constant(true))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
}
