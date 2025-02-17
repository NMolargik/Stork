//
//  DeliveryAdditionSheet.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

// MARK: - Delivery Addition Sheet
struct DeliveryAdditionSheet: View {
    @Binding var showingDeliveryAddition: Bool

    var body: some View {
        NavigationStack {
            DeliveryAdditionView(showingDeliveryAddition: $showingDeliveryAddition)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("New Delivery")
                            .fontWeight(.bold)
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            triggerHaptic()
                            withAnimation { showingDeliveryAddition = false }
                        }) {
                            Text("Cancel")
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                        }
                    }
                }
        }
        .animation(.easeInOut, value: showingDeliveryAddition)
        .interactiveDismissDisabled()
    }
}

#Preview {
    DeliveryAdditionSheet(showingDeliveryAddition: .constant(true))
}
