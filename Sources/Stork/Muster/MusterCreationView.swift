//
//  MusterCreationView.swift
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterCreationView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel

    @Binding var showCreateMusterSheet: Bool

    @State private var selectedHospital: Hospital? = nil

    var body: some View {
        if (musterViewModel.showHospitalSelection) {
            HospitalListView(selectionMode: true, onSelection: { hospital in
                self.selectedHospital = hospital
                musterViewModel.newMuster.primaryHospitalId = hospital.id
                musterViewModel.showHospitalSelection = false
                musterViewModel.validateCreationForm()

            })
        } else {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Muster Name Input
                        Group {
                            CustomTextfieldView(
                                text: $musterViewModel.newMuster.name,
                                hintText: "Enter Muster name",
                                icon: Image(systemName: "tag.fill"),
                                isSecure: false,
                                iconColor: Color.indigo,
                                characterLimit: 20
                            )

                            if let error = musterViewModel.nameError {
                                Text(error)
                                    .foregroundStyle(.gray)
                                    .font(.footnote)
                            }
                        }

                        // Hospital Selection
                        VStack {
                            Text(self.selectedHospital?.facility_name ?? "Select A Primary Hospital")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.black)

                            CustomButtonView(
                                text: "Select A Hospital",
                                width: 250,
                                height: 40,
                                color: Color.red,
                                icon: Image(systemName: "building"),
                                isEnabled: true,
                                onTapAction: {
                                    musterViewModel.showHospitalSelection = true
                                }
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            Color.white
                                .cornerRadius(20)
                                .shadow(radius: 2)
                        }

                        Spacer()

                        Text("It's that easy!\n\nYou'll be able to add members to your muster after creation.")
                            .foregroundStyle(.black)
                            .padding()
                            .multilineTextAlignment(.center)
                            .fontWeight(.semibold)
                            .background {
                                Color.white
                                    .cornerRadius(20)
                                    .shadow(radius: 2)
                            }

                        Spacer()

                        if (musterViewModel.isWorking) {
                            ProgressView()
                                .tint(.indigo)
                                .frame(height: 70)
                                .padding()
                        } else {
                            CustomButtonView(text: "Muster Up!", width: 200, height: 70, color: Color.indigo, icon: nil, isEnabled: musterViewModel.creationFormValid, onTapAction: {
                                withAnimation {
                                    createMuster()
                                }
                            })
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)

                }
                .navigationTitle("Create A Muster")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            triggerHaptic()
                            showCreateMusterSheet = false
                            dismiss()
                        }, label: {
                            Text("Cancel")
                                .foregroundStyle(.orange)
                        })
                        .disabled(musterViewModel.isWorking)
                    }
                }
            }
            .onChange(of: musterViewModel.newMuster.name) { _ in
                musterViewModel.validateCreationForm()
            }
        }
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    @MainActor
    private func createMuster() {
        Task {
            do {
                try await musterViewModel.createMuster(profileId: profileViewModel.profile.id)

                if let muster = musterViewModel.currentMuster {
                    do {
                        profileViewModel.tempProfile = profileViewModel.profile
                        profileViewModel.tempProfile.musterId = muster.id

                        try await profileViewModel.updateProfile()

                        musterViewModel.musterMembers.append(profileViewModel.profile)

                    } catch {
                        errorMessage = error.localizedDescription
                        musterViewModel.isWorking = false
                        throw error
                    }
                } else {
                    musterViewModel.validateCreationForm()
                }
            } catch {
                musterViewModel.validateCreationForm()
                musterViewModel.isWorking = false
            }

            musterViewModel.isWorking = false
            dismiss()
        }
    }
}

// MARK: - Preview

struct MusterCreationView_Previews: PreviewProvider {
    static var previews: some View {
        MusterCreationView(showCreateMusterSheet: .constant(true))
            .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
            .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
            .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
    }
}
