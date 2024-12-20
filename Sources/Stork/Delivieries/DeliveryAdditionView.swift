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
        List {
            ScrollView {
                VStack {
                    ForEach($deliveryViewModel.newDelivery.babies) { $baby in
                        let babyNumber = deliveryViewModel.newDelivery.babies.firstIndex(where: { $0.id == baby.id }) ?? 0 + 1
                        
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
                    
                    CustomButtonView(
                        text: "Add A Baby",
                        width: 220,
                        height: 40,
                        color: Color.indigo,
                        icon: Image(systemName: "plus.circle.fill"),
                        isEnabled: .constant(true),
                        onTapAction: {
                            addBaby()
                        }
                    )
                    .padding()
                    .padding(.bottom, 50)
                }
                .padding(.top)
                
                // Section: Delivery Options
                VStack(alignment: .center, spacing: 8) {
                    Text("Delivery Options")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Toggle("Epidural Used", isOn: $deliveryViewModel.newDelivery.epiduralUsed)
                        .padding()
                        .fontWeight(.bold)
                        .background {
                            Color.indigo
                                .opacity(0.2)
                                .cornerRadius(10)
                        }
                    
                    if (profileViewModel.profile.musterId != "") {
                        Toggle("Add To Muster", isOn: $deliveryViewModel.addToMuster)
                            .padding()
                            .fontWeight(.bold)
                            .background {
                                Color.indigo
                                    .opacity(0.2)
                                    .cornerRadius(10)
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
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
                
                if deliveryViewModel.isWorking {
                    ProgressView()
                        .frame(width: 200, height: 40)
                } else {
                    CustomButtonView(
                        text: "Submit Delivery",
                        width: 200,
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
