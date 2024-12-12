//
//  MusterCreationView.swift
//
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterCreationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    
    var onCreate: (Muster) -> Void

    var body: some View {
        if (musterViewModel.showHospitalSelection) {
            HospitalListView(selectionMode: true, onSelection: { hospital in
                musterViewModel.newMusterSelectedHospital = hospital
                musterViewModel.showHospitalSelection = false
            })
        } else {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Muster Name Input
                        CustomTextfieldView(
                            text: $musterViewModel.newMusterName,
                            hintText: "Enter Muster name",
                            icon: Image(systemName: "tag.fill"),
                            isSecure: false,
                            iconColor: Color.blue
                        )
                        
                        // Color Selection Buttons
                        VStack(alignment: .center, spacing: 10) {
                            Text("Select An Accent Color")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            // Color Buttons
                            HStack(spacing: 10) {
                                ForEach(musterViewModel.colors, id: \.self) { color in
                                    Button(action: {
                                        withAnimation {
                                            musterViewModel.newMusterSelectedColor = color
                                        }
                                    }, label: {
                                        Circle()
                                            .foregroundStyle(color)
                                            .frame(width: color == musterViewModel.newMusterSelectedColor ? 50.0 : 40.0)
                                            .shadow(radius: 1.0)
                                    })
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            Color.white
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        
                        // Hospital Selection
                        VStack {
                            Text(musterViewModel.newMusterSelectedHospital?.facility_name ?? "Select A Primary Hospital")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.black)
                            
                            CustomButtonView(
                                text: "Select A Hospital",
                                width: 250,
                                height: 40,
                                color: Color.indigo,
                                icon: Image(systemName: "building"),
                                isEnabled: .constant(true),
                                onTapAction: {
                                    musterViewModel.showHospitalSelection = true
                                }
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            Color.white
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        
                        Spacer()
                        
                        Text("It's that easy!\n\nYou'll be able to add members to your muster after creation.")
                            .foregroundStyle(.black)
                            .padding()
                            .multilineTextAlignment(.center)
                            .fontWeight(.semibold)
                            .background {
                                Color.white
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                        
                        Spacer()
                        
                        if (musterViewModel.isWorking) {
                            ProgressView()
                                .tint(.indigo)
                        } else {
                            CustomButtonView(text: "Muster Up!", width: 200, height: 70, color: Color.indigo, icon: nil, isEnabled: $musterViewModel.creationFormValid, onTapAction: {
                                withAnimation {
                                    createMuster()
                                }
                            })
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                }
                .navigationTitle("Create A Muster")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(.red)
                            .disabled(musterViewModel.isWorking)
                    }
                }
            }
            .onChange(of: musterViewModel.newMusterName) { _ in
                musterViewModel.validateCreationForm()
            }
            .onChange(of: musterViewModel.newMusterSelectedColor) { _ in
                musterViewModel.validateCreationForm()
            }
            .onChange(of: musterViewModel.newMusterSelectedHospital) { _ in
                musterViewModel.validateCreationForm()
            }
        }
    }
    
    private func createMuster() {
        Task {
            do {
                try await musterViewModel.createMuster(profileId: profileViewModel.profile.id)
                
                if let muster = musterViewModel.currentMuster {
                    // Update profile
                    profileViewModel.profile.musterId = muster.id
                    profileViewModel.updateProfile()
                    
                    onCreate(muster)
                } else {
                    musterViewModel.validateCreationForm()
                }
            } catch {
                musterViewModel.validateCreationForm()
                musterViewModel.isWorking = false
            }
        }
    }
}

#Preview {
    MusterCreationView(onCreate: { _ in })
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
}
