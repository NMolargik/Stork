
import StorkModel
import SwiftUI

struct FishBowlBackground: View {
    var body: some View {
        Rectangle()
            .stroke(Color.gray, lineWidth: 3)
            .background(
                Rectangle().fill(Color.white.opacity(0.15))
            )
    }
}

import SwiftUI
import StorkModel  // or wherever your Delivery / Baby / BabySex live

struct FishBowlView: View {
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel

    private let circleDiameter: CGFloat = 24
    
    // Flatten all babies from all deliveries
    var allBabies: [Baby] {
        deliveryViewModel.deliveries.flatMap { $0.babies }
    }
    
    // Adaptive columns: each column must at least fit one circle plus spacing
    var columns: [GridItem] {
        // You can tweak `minimum` or spacing as you like
        [
            GridItem(.adaptive(minimum: circleDiameter + 4), spacing: 8)
        ]
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fishbowl background (replace Rectangle if desired)
                FishBowlBackground()
                
                // Overlay a ScrollView of balls in a LazyVGrid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(allBabies) { baby in
                            Circle()
                                .fill(baby.sex.color)
                                .frame(width: circleDiameter, height: circleDiameter)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}
