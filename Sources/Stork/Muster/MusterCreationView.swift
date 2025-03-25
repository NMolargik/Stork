//
//  MusterCreationView.swift
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterCreationView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var appStorageManager: AppStorageManager

    @ObservedObject var musterViewModel: MusterViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel

    @Binding var showCreateMusterSheet: Bool

    @State private var selectedHospital: Hospital? = nil

    var body: some View {
        if (musterViewModel.showHospitalSelection) {
            HospitalListView(
                hospitalViewModel: hospitalViewModel,
                profileViewModel: profileViewModel,
                selectionMode: true,
                onSelection: { hospital in
                    self.selectedHospital = hospital
                    musterViewModel.newMuster.primaryHospitalId = hospital.id
                    musterViewModel.showHospitalSelection = false
                    musterViewModel.validateCreationForm()
                }
            )
        } else {
            NavigationStack {
                ScrollView {
                    VStack() {
                        // Muster Name Input
                        CustomTextfieldView(
                            text: $musterViewModel.newMuster.name,
                            hintText: "Enter Muster name",
                            icon: Image("tag.fill", bundle: .module),
                            isSecure: false,
                            iconColor: Color("storkIndigo"),
                            characterLimit: 30
                        )

                        if let error = musterViewModel.nameError {
                            Text(error)
                                .foregroundStyle(.gray)
                                .font(.footnote)
                        }

                        // Hospital Selection
                        VStack {
                            Text(self.selectedHospital?.facility_name ?? "Select A Primary Hospital")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)

                            CustomButtonView(
                                text: "Select A Hospital",
                                width: 250,
                                height: 40,
                                color: Color.red,
                                icon: Image("building.fill", bundle: .module),
                                isEnabled: true,
                                onTapAction: {
                                    musterViewModel.showHospitalSelection = true
                                }
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .backgroundCard(colorScheme: appStorageManager.useDarkMode ? .dark : .light)


                        Spacer()

                        Text("It's that easy!\n\nYou'll be able to add members to your muster after creation.")
                            .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                            .padding()
                            .multilineTextAlignment(.center)
                            .fontWeight(.semibold)
                            .backgroundCard(colorScheme: appStorageManager.useDarkMode ? .dark : .light)


                        Spacer()

                        if (musterViewModel.isWorking) {
                            ProgressView()
                                .tint(Color("storkIndigo"))
                                .frame(height: 50)
                        } else {
                            CustomButtonView(text: "Muster Up!", width: 200, height: 50, color: Color("storkIndigo"), icon: nil, isEnabled: musterViewModel.creationFormValid, onTapAction: {
                                withAnimation {
                                    createMuster()
                                }
                            })
                            .padding(.top)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)

                }
                .navigationTitle("Create A Muster")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            HapticFeedback.trigger(style: .medium)
                            showCreateMusterSheet = false
                            dismiss()
                        }, label: {
                            Text("Cancel")
                                .foregroundStyle(Color("storkOrange"))
                                .bold()
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
                        withAnimation {
                            appStateManager.errorMessage = error.localizedDescription
                            musterViewModel.isWorking = false
                        }
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

#Preview {
    MusterCreationView(
        musterViewModel: MusterViewModel(musterRepository: MockMusterRepository()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()),
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()),
        showCreateMusterSheet: .constant(false)
    )
    .environmentObject(AppStateManager.shared)
    .environmentObject(AppStorageManager())
}
