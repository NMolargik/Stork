//
//  DeliveryMethodPicker.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct DeliveryMethodPicker: View {
    @EnvironmentObject var appStorageManager: AppStorageManager

    @Binding var deliveryMethod: DeliveryMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delivery Method")
                .font(.headline)
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)

            Picker("Delivery Method", selection: $deliveryMethod) {
                ForEach(DeliveryMethod.allCases, id: \.self) { method in
                    Text(method.description).tag(method)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: deliveryMethod) { _ in
                HapticFeedback.trigger(style: .medium)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .backgroundCard(colorScheme: appStorageManager.useDarkMode ? .dark : .light)
    }
}

#Preview {
    DeliveryMethodPicker(deliveryMethod: .constant(DeliveryMethod.cSection)
    )
    .environmentObject(AppStorageManager())
}
