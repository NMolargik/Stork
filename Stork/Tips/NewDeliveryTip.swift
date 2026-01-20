//
//  NewDeliveryTip.swift
//  Stork
//
//  Created by Nick Molargik on 1/20/26.
//

import TipKit
import SwiftUI

/// Tip shown to first-time users to guide them to record their first delivery
struct NewDeliveryTip: Tip {
    var title: Text {
        Text("Record a Delivery")
    }

    var message: Text? {
        Text("Tap here to start tracking your first delivery.")
    }

    var image: Image? {
        Image(systemName: "plus.circle.fill")
    }
}

/// Custom tip view style that applies storkBlue to the icon
struct StorkTipViewStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            configuration.image?
                .foregroundStyle(.storkBlue)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                configuration.title
                    .font(.headline)
                configuration.message?
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
