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
    
    //TODO: this and an edit view
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                VStack (alignment: .leading) {
                    Text("\(profileViewModel.profile.role.description) \(profileViewModel.profile.firstName)")
                        .font(.largeTitle)
                    
                    Text(profileViewModel.profile.lastName)
                        .font(.title)

                }
                .fontWeight(.bold)
                
                Spacer()
                
                //TODO: replace with initials
                Image(systemName: "person")
                    .foregroundStyle(.orange)
                    .font(.largeTitle)
            }
            .padding()
            
            
            
            
        }
        .toolbar(.hidden)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
