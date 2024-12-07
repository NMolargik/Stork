//
//  DeliveryRowView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryRowView: View {
    var delivery: Delivery

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Date formatted as title
                Text(delivery.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background {
                        Rectangle()
                            .foregroundStyle(.white)
                            .cornerRadius(5)
                            .opacity(0.8)
                    }
                
                // Baby summary
                Text(babySummary(for: delivery.babies))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.leading, 6)
            }
            .padding(8)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .padding(.trailing)
                .foregroundStyle(.white)
        }
        .background{
            Rectangle()
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors(for: delivery.babies)),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                .overlay {
                    Rectangle()
                        .foregroundStyle(.white)
                        .opacity(0.1)
                }
                .cornerRadius(8)
                .shadow(radius: 5)
        }
    }
    
    /// Generates a summary of babies born in the delivery.
    /// - Parameter babies: The list of babies in the delivery.
    /// - Returns: A string summarizing the baby counts by sex.
    private func babySummary(for babies: [Baby]) -> String {
        // Initialize counters for each sex
        var maleCount = 0
        var femaleCount = 0
        var lossCount = 0
        
        // Manually count the number of each sex
        for baby in babies {
            switch baby.sex {
            case .male:
                maleCount += 1
            case .female:
                femaleCount += 1
            case .loss:
                lossCount += 1
            }
        }
        
        // Build the summary string
        var summary = [String]()
        
        if maleCount > 0 {
            summary.append("\(maleCount) boy\(maleCount > 1 ? "s" : "")")
        }
        
        if femaleCount > 0 {
            summary.append("\(femaleCount) girl\(femaleCount > 1 ? "s" : "")")
        }
        
        if lossCount > 0 {
            summary.append("\(lossCount) loss\(lossCount > 1 ? "es" : "")")
        }
        
        return summary.isEmpty ? "No babies" : summary.joined(separator: " ")
    }
    
    /// Generates a gradient representing the distribution of sexes in the delivery.
    /// - Parameter babies: The list of babies in the delivery.
    /// - Returns: An array of `Color` objects representing the gradient stops.
    private func gradientColors(for babies: [Baby]) -> [Color] {
        // Group and sort colors by sex
        var colors: [Color] = []
        colors.append(contentsOf: Array(repeating: Color.blue, count: babies.filter { $0.sex == .male }.count))
        colors.append(contentsOf: Array(repeating: Color.pink, count: babies.filter { $0.sex == .female }.count))
        colors.append(contentsOf: Array(repeating: Color.purple, count: babies.filter { $0.sex == .loss }.count))
        return colors
    }
}

#Preview {
    DeliveryRowView(delivery: Delivery(
        id: "1",
        userId: "user1",
        hospitalId: "Hospital1",
        musterId: "Muster1",
        date: Date(),
        babies: [
            Baby(id: "1", deliveryId: "1", birthday: Date(), height: 20.0, weight: 7.5, nurseCatch: true, sex: .male),
            Baby(id: "2", deliveryId: "1", birthday: Date(), height: 19.5, weight: 7.0, nurseCatch: false, sex: .female),
            Baby(id: "3", deliveryId: "1", birthday: Date(), height: 19.0, weight: 6.5, nurseCatch: true, sex: .female)
        ],
        babyCount: 3,
        deliveryMethod: .vaginal,
        epiduralUsed: true
    ))
}
