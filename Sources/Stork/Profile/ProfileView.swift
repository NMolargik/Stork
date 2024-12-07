//
//  ProfileView.swift
//
//
//  Created by Nick Molargik on 12/3/24.
//

import SwiftUI
import StorkModel

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    
    var body: some View {
        Text(profileViewModel.profile.firstName)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
