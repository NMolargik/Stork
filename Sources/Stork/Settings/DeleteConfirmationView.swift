//
//  DeleteConfirmationView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SwiftUI

struct DeleteConfirmationView: View {
    @Binding var step: Int
    @Binding var showing: Bool
    var onDelete: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(confirmationTitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text(confirmationMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                DeleteConfirmationButtons(
                    step: $step,
                    showing: $showing,
                    onDelete: onDelete
                )

                Spacer()
            }
            .padding()
            .navigationTitle("Profile Deletion")
        }
    }
    
    var confirmationTitle: String {
        switch step {
        case 1:
            return "Are you sure you want to delete your account?"
        case 2:
            return "Are you absolutely sure you want to delete your account?"
        default:
            return ""
        }
    }
    
    var confirmationMessage: String {
        switch step {
        case 1:
            return "This action will permanently delete all your personal information and your deliveries."
        case 2:
            return "This will remove all your personal data and cannot be undone."
        default:
            return ""
        }
    }
}

#Preview {
    DeleteConfirmationView(step: .constant(2), showing: .constant(true), onDelete: {})
}
