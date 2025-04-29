//
//  MusterAdminRenameView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/24/25.
//

import SwiftUI
import StorkModel

struct MusterAdminRenameView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var musterViewModel: MusterViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @State private var newName: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                CustomTextfieldView(
                    text: $newName,
                    hintText: "Enter Muster name",
                    icon: Image("tag.fill", bundle: .module),
                    isSecure: false,
                    iconColor: Color("storkIndigo"),
                    characterLimit: 30
                )
                .padding(.horizontal)
                .navigationTitle("Rename Muster")
                
                if let error = musterViewModel.nameError {
                    Text(error)
                        .foregroundStyle(.gray)
                        .font(.footnote)
                }
                
                CustomButtonView(text: "Submit", width: 150, height: 50, color: Color("storkOrange"), isEnabled: musterViewModel.nameError == nil, onTapAction: {
                    
                    musterViewModel.currentMuster?.name = newName
                    
                    Task {
                        do {
                            try await musterViewModel.updateMuster()
                        } catch {
                            throw MusterError.updateFailed("Failed to update muster name")
                        }
                        
                        dismiss()
                    }
                })
                
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("storkOrange"))
                        .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            guard let name = musterViewModel.currentMuster?.name else {
                print("Current muster has no name!")
                return
            }
            newName = name
        }
    }
}
#Preview {
    MusterAdminRenameView(
        musterViewModel: MusterViewModel(musterRepository: MockMusterRepository()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository())
    )
}
