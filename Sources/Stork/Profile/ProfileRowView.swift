//
//  ProfileRowView.swift
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct ProfileRowView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""
    
    @Binding var existingInvitations: [MusterInvite]
    
    var profile: Profile
    var currentUser: Profile
    var onInvite: () -> Void
    var onCancelInvite: (_ invite: MusterInvite) -> Void
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
    
    var body: some View {
        HStack {
            // Profile Information
            VStack(alignment: .leading) {
                Text("\(profile.role.description) \(profile.firstName) \(profile.lastName)")
                    .foregroundStyle(.black)
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "birthday.cake.fill")
                    Text(ProfileRowView.dateFormatter.string(from: profile.birthday))
                        .foregroundColor(.gray)
                }
                .padding(.top, -5)
            }
            
            Spacer()
            
            // Action Buttons or Status Indicators
            Group {
                if profile.id == currentUser.id {
                    // Condition 1: Current User
                    CustomButtonView(
                        text: "You",
                        width: 120,
                        height: 50,
                        color: Color.gray,
                        icon: nil,
                        isEnabled: .constant(false),
                        onTapAction: {
                            withAnimation {
                                errorMessage = "This... is you..."
                            }
                        }
                    )
                } else if ((profile.musterId == currentUser.musterId) && !(profile.musterId == "")) {
                    // Condition 2: In the Same Muster
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title)
                } else if (!(profile.musterId == "")) {
                    // Condition 3: User is in a Different Muster
                    CustomButtonView(
                        text: "Unavailable",
                        width: 120,
                        height: 50,
                        color: Color.gray,
                        icon: nil,
                        isEnabled: .constant(false),
                        onTapAction: {
                            withAnimation {
                                errorMessage = "This user is already in a muster."
                            }
                        }
                    )
                } else if let invitation = existingInvitations.first(where: { $0.recipientId == profile.id }) {
                    // Condition 4: Existing Invitation
//                    VStack(alignment: .trailing, spacing: 5) {
//                        Text(invitation.status.stringValue)
//                            .foregroundColor(invitation.status == .declined ? .red : .blue)
//                            .fontWeight(.semibold)
//                        
//                        if invitation.status == .pending {
//                            HStack(spacing: 10) {
//                                CustomButtonView(
//                                    text: "Cancel",
//                                    width: 80,
//                                    height: 40,
//                                    color: Color.red,
//                                    icon: nil,
//                                    isEnabled: .constant(true),
//                                    onTapAction: {
//                                        withAnimation {
//                                            onCancelInvite()
//                                        }
//                                    }
//                                )
//                                
//                                CustomButtonView(
//                                    text: "Pending",
//                                    width: 80,
//                                    height: 40,
//                                    color: Color.gray,
//                                    icon: nil,
//                                    isEnabled: .constant(false),
//                                    onTapAction: {}
//                                )
//                            }
//                        } else if invitation.status == .declined {
//                            CustomButtonView(
//                                text: "Declined",
//                                width: 120,
//                                height: 50,
//                                color: Color.orange,
//                                icon: nil,
//                                isEnabled: .constant(true),
//                                onTapAction: {
//                                    withAnimation {
//                                        onInvite()
//                                    }
//                                }
//                            )
//                        } else {
//                            EmptyView()
//                        }
//                    }
                } else {
                    // Condition 5: No Existing Invitation
                    CustomButtonView(
                        text: "Invite",
                        width: 120,
                        height: 50,
                        color: Color.blue,
                        icon: nil,
                        isEnabled: .constant(true),
                        onTapAction: {
                            withAnimation {
                                onInvite()
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            Color.white
                .cornerRadius(15)
                .shadow(radius: 5)
        }
    }
}

#Preview {
    ProfileRowView(existingInvitations: .constant([]), profile: Profile(), currentUser: Profile(), onInvite: {}, onCancelInvite: {invite in })
}
