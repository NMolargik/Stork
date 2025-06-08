//
//  HospitalActionButtonsView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct HospitalActionButtonsView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var profileViewModel: ProfileViewModel

    let hospital: Hospital

    var body: some View {
        HStack {
            CustomButtonView(
                text: "Back",
                width: 100,
                height: 40,
                color: Color("storkOrange"),
                icon: Image("arrow.left", bundle: .module),
                isEnabled: true,
                onTapAction: { withAnimation { dismiss() } }
            )
            
            Spacer()
            
            CustomButtonView(
                text: profileViewModel.profile.primaryHospitalId == hospital.id ? "Remove From Default" : "Set As Default",
                width: 200,
                height: 40,
                color: Color("storkIndigo"),
                isEnabled: true,
                onTapAction: { withAnimation { togglePrimaryHospital() } }
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func togglePrimaryHospital() {
        withAnimation {
            profileViewModel.profile.primaryHospitalId = (profileViewModel.profile.primaryHospitalId == hospital.id) ? "" : hospital.id
        }
        
        profileViewModel.tempProfile = profileViewModel.profile
        
        Task {
            do {
                try await profileViewModel.updateProfile()
            } catch {
                print("Failed to update profile")
            }
        }
    }
}

#Preview {
    HospitalActionButtonsView(profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository()), hospital: Hospital.sampleHospital())
}
