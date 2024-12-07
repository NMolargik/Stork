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
    
    @Binding var showingDeliveryAddition: Bool
    @State private var babies: [Baby] = []
    @State private var isSubmitting: Bool = false // Progress indicator state

    var body: some View {
        List {
            ScrollView {
                VStack {
                    ForEach(Array(babies.enumerated()), id: \.element.id) { index, baby in
                        BabyEditorView(
                            baby: Binding(
                                get: { self.babies[index] },
                                set: { self.babies[index] = $0 }
                            ),
                            babyIndex: index,
                            removeBaby: { removeAtIndex in
                                withAnimation {
                                    if babies.indices.contains(removeAtIndex) {
                                        self.babies.remove(at: removeAtIndex)
                                    }
                                }
                            }
                        )
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
                }
                
                // Section: Delivery Options
                VStack(alignment: .center, spacing: 8) {
                    Text("Delivery Options")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if (profileViewModel.profile.musterId != "") {
                        VStack {
                            Text("Muster Name")
                                .font(.headline)
                            
                            Toggle("Add To Muster", isOn: $deliveryViewModel.addToMuster)
                                .padding()
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                                .background {
                                    Color.black
                                        .cornerRadius(10)
                                }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background {
                            Color.indigo
                                .opacity(0.2)
                                .cornerRadius(10)
                        }
                    }
                    
                    Toggle("Epidural Used", isOn: $deliveryViewModel.epiduralUsed)
                        .padding()
                        .fontWeight(.bold)
                        .background {
                            Color.indigo
                                .opacity(0.2)
                                .cornerRadius(10)
                        }
                    
                    VStack {
                        Text("Delivery Method")
                            .font(.headline)
                        
                        Picker("Delivery Method", selection: $deliveryViewModel.deliveryMethod) {
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
                        Text(deliveryViewModel.selectedHospital?.facility_name ?? "No Hospital Selected")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        CustomButtonView(text: "Select A Hospital", width: 250, height: 40, color: Color.black, icon: Image(systemName: "building"), isEnabled: .constant(true), onTapAction: {
                            deliveryViewModel.isSelectingHospital = true // Trigger the sheet
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
                
                if isSubmitting {
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
                                isSubmitting = true
                                do {
                                    try await deliveryViewModel.submitDelivery(
                                        babies: babies,
                                        profileViewModel: profileViewModel,
                                        hospitalViewModel: hospitalViewModel
                                    )
                                    withAnimation {
                                        showingDeliveryAddition = false
                                    }
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                                isSubmitting = false
                            }
                        }
                    )
                }
            }
        }
        .onChange(of: babies.count) { newCount in
            deliveryViewModel.submitEnabled = newCount > 0 && deliveryViewModel.selectedHospital != nil
        }
        .onChange(of: deliveryViewModel.selectedHospital) { _ in
            deliveryViewModel.submitEnabled = babies.count > 0 && deliveryViewModel.selectedHospital != nil
        }
        .sheet(isPresented: $deliveryViewModel.isSelectingHospital) {
            HospitalListView(
                selectionMode: true,
                onSelection: { selectedHospital in
                    deliveryViewModel.selectedHospital = selectedHospital
                    deliveryViewModel.isSelectingHospital = false
                }
            )
            .environmentObject(hospitalViewModel)
            .environmentObject(profileViewModel)
        }
    }

    private func addBaby() {
        let newBaby = Baby(deliveryId: UUID().uuidString, nurseCatch: false, sex: .male)
        babies.append(newBaby)
    }
}
                    

#Preview {
    DeliveryAdditionView(showingDeliveryAddition: .constant(true))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
}




