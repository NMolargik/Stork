//
//  DeliveryAdditionView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryAdditionView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    
    @State private var babies: [Baby] = []
    @State private var epiduralUsed: Bool = false
    @State private var deliveryMethod: DeliveryMethod = .vaginal
    @State private var addToMuster: Bool = false
    @State private var selectedHospital: Hospital? = nil
    @State private var submitEnabled: Bool = false
    @State private var isSelectingHospital: Bool = false // State for the sheet
    
    var body: some View {
        List {
            ScrollView {
                VStack(alignment: .center, spacing: 15) {
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
                    
                    CustomButtonView(text: "Add A Baby", width: 220, height: 40, color: Color.orange, icon: Image(systemName: "plus.circle.fill"), isEnabled: .constant(true), onTapAction: {
                        addBaby()
                    })
                    
                }
                .padding()
                .cornerRadius(10)
                
                Rectangle()
                    .frame(height: 4)
                    .foregroundStyle(.indigo)
                
                // Section: Delivery Options
                VStack(alignment: .center, spacing: 8) {
                    Text("Delivery Options")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if (profileViewModel.profile.musterId != "") {
                        VStack {
                            Text("Muster Name")
                                .font(.headline)
                            
                            Toggle("Add To Muster", isOn: $addToMuster)
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
                    
                    Toggle("Epidural Used", isOn: $epiduralUsed)
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
                        
                        Picker("Delivery Method", selection: $deliveryMethod) {
                            ForEach(DeliveryMethod.allCases, id: \.self) { method in
                                Text(method.description).tag(method)
                            }
                        }
                        .padding(.bottom)
                        
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
                        
                        CustomButtonView(text: "Select A Hospital", width: 250, height: 40, color: Color.black, icon: Image(systemName: "building"), isEnabled: .constant(true), onTapAction: {
                            isSelectingHospital = true // Trigger the sheet
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
                
                CustomButtonView(text: "Submit Delivery", width: 200, height: 40, color: Color.indigo, isEnabled: $submitEnabled, onTapAction: {
                    
                })
                
                
            }
        }
        .onChange(of: babies.count) { newCount in
            submitEnabled = newCount > 0
        }
        .sheet(isPresented: $isSelectingHospital) {
            HospitalListView(
                selectionMode: true,
                onSelection: { selectedHospital in
                    self.selectedHospital = selectedHospital
                    isSelectingHospital = false
                }
            )
            .environmentObject(hospitalViewModel)
            .environmentObject(profileViewModel)
        }
    }

    // MARK: - Actions
    private func addBaby() {
        let newBaby = Baby(deliveryId: UUID().uuidString, nurseCatch: false, sex: .male)
        babies.append(newBaby)
    }
    
    
    private func selectHospital() {
        // Action for selecting a hospital
    }
}
                    

#Preview {
    DeliveryAdditionView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
}




