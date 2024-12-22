//
//  ProfileRowView.swift
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct ProfileRowView: View {
    @AppStorage("errorMessage") private var errorMessage: String = ""
    
    @Binding var existingInvitations: [MusterInvite]
    
    var profile: Profile
    var currentUser: Profile
    var onInvite: () -> Void
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
    
    var body: some View {
        HStack {
            // Profile Information
            VStack(alignment: .leading, spacing: 4) {
                Text("\(profile.role.description) \(profile.firstName) \(profile.lastName)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                HStack(spacing: 4) {
                    Image(systemName: "birthday.cake.fill")
                    Text(Self.dateFormatter.string(from: profile.birthday))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Action Buttons or Status Indicators
            actionButtonGroup
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.cornerRadius(15).shadow(radius: 5))
    }
    
    // MARK: - Action Button Group
    private var actionButtonGroup: some View {
        Group {
            if profile.id == currentUser.id {
                actionButton(text: "You", color: .gray, isEnabled: false) {
                    errorMessage = "This... is you..."
                }
            } else if profile.musterId == currentUser.musterId && !profile.musterId.isEmpty {
                actionButton(text: "Joined", color: .gray, isEnabled: false) {
                    errorMessage = "User already joined muster"
                }
            } else if !profile.musterId.isEmpty {
                actionButton(text: "Unavailable", color: .gray, isEnabled: false) {
                    errorMessage = "This user is already in a muster."
                }
            } else if existingInvitations.contains(where: { $0.recipientId == profile.id }) {
                actionButton(text: "Sent", color: .gray, isEnabled: false) {
                    errorMessage = "User already invited to muster"
                }
            } else {
                actionButton(text: "Invite", color: .blue, isEnabled: true) {
                    onInvite()
                }
            }
        }
    }
    
    // MARK: - Action Button Helper
    private func actionButton(text: String, color: Color, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        CustomButtonView(
            text: text,
            width: 120,
            height: 50,
            color: color,
            icon: nil,
            isEnabled: .constant(isEnabled),
            onTapAction: { withAnimation { action() } }
        )
    }
}

#Preview {
    ProfileRowView(
        existingInvitations: .constant([]),
        profile: Profile(),
        currentUser: Profile(),
        onInvite: {}
    )
}
