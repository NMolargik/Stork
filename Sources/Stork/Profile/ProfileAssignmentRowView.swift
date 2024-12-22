//
//  ProfileAssignmentRowView.swift
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct ProfileAssignmentRowView: View {
    @AppStorage("errorMessage") private var errorMessage: String = ""
    
    var profile: Profile
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
        .background(Color.white.cornerRadius(15).shadow(radius: 5))
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        actionButton(text: profile.isAdmin ? "Admin" : "Assign", color: profile.isAdmin ? .gray : .blue, isEnabled: !profile.isAdmin) {
            if !profile.isAdmin {
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
            isEnabled: .constant(isEnabled),
            onTapAction: { withAnimation { action() } }
        )
    }
}

#Preview {
    ProfileAssignmentRowView(
        profile: Profile(),
        onAssign: {}
    )
}
