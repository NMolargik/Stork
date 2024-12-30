//
//  OnboardingView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SwiftUI
import StorkModel

struct OnboardingView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Welcome!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()
            }
            
            

            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
