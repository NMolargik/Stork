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
                if step == 1 {
                    Text("Are you sure you want to delete your account?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Text("This action will permanently delete all your personal information and your deliveries.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding([.leading, .trailing])
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            // Cancel deletion
                            triggerHaptic()
                            showing = false
                            step = 1
                        }) {
                            Text("Cancel")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            // Proceed to step 2
                            triggerHaptic()
                            step = 2
                        }) {
                            Text("Continue")
                                .foregroundColor(.blue)
                        }
                    }
                } else if step == 2 {
                    Text("Are you absolutely sure you want to delete your account?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Text("This will remove all your personal data and cannot be undone.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding([.leading, .trailing])
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            // Cancel deletion
                            triggerHaptic()
                            showing = false
                            step = 1
                        }) {
                            Text("Cancel")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            // Confirm deletion
                            triggerHaptic()
                            onDelete()
                            showing = false
                            step = 1
                        }) {
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Confirm Deletion")
        }
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}

#Preview {
    DeleteConfirmationView(step: .constant(1), showing: .constant(true), onDelete: {})
}
