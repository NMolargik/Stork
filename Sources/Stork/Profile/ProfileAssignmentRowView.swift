//
//  ProfileAssignmentRowView.swift
//
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct ProfileAssignmentRowView: View {
    @AppStorage("errorMessage") private var errorMessage: String = ""
    
    /// The `Profile` displayed in this row.
    var profile: Profile
    
    /// A list (or set) of user IDs who are admins in the muster.
    /// We check whether `profile.id` is in this list to see if they're already an admin.
    var adminProfileIds: Set<String>
    
    /// Called when we want to assign admin privileges to this user.
    var onAssign: () -> Void
    
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
                        .foregroundColor(.gray)

                    Text(Self.dateFormatter.string(from: profile.birthday))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Single Button for Assignment or Admin Status
            actionButton
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            Color.white
                .cornerRadius(20)
                .shadow(radius: 2)
        )
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        let isAdmin = adminProfileIds.contains(profile.id)
        
        return actionButton(
            text: isAdmin ? "Admin" : "Assign",
            color: isAdmin ? .gray : .blue,
            isEnabled: !isAdmin
        ) {
            if !isAdmin {
                onAssign()
            } else {
                errorMessage = "User is already an admin."
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
            isEnabled: isEnabled,
            onTapAction: { withAnimation { action() } }
        )
    }
}

#Preview {
    ProfileAssignmentRowView(
        profile: Profile(),
        adminProfileIds: ["123", "abc"],
        onAssign: {}
    )
}
