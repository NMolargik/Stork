//
//  DeliveryRowView.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryRowView: View {
    @EnvironmentObject var appStorageManager: AppStorageManager

    var delivery: Delivery

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(delivery.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                    .backgroundCard(colorScheme: appStorageManager.useDarkMode ? .dark : .light)
                
                // Baby summary
                Text(babySummary(for: delivery.babies))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.leading)
            }
            .padding(8)
            
            Spacer()
        }
        .background {
            Rectangle()
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors(for: delivery.babies)),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Rectangle()
                        .foregroundStyle(.white)
                        .opacity(0.1)
                }
                .cornerRadius(20)
                .shadow(radius: 2)
        }
    }
    
    /// Returns a summary string of baby counts by sex.
    private func babySummary(for babies: [Baby]) -> String {
        let maleCount = babies.filter { $0.sex == .male }.count
        let femaleCount = babies.filter { $0.sex == .female }.count
        let lossCount = babies.filter { $0.sex == .loss }.count
        
        var summaryComponents = [String]()
        if maleCount > 0 {
            summaryComponents.append("\(maleCount) boy\(maleCount > 1 ? "s" : "")")
        }
        if femaleCount > 0 {
            summaryComponents.append("\(femaleCount) girl\(femaleCount > 1 ? "s" : "")")
        }
        if lossCount > 0 {
            summaryComponents.append("\(lossCount) loss\(lossCount > 1 ? "es" : "")")
        }
        
        return summaryComponents.isEmpty ? "No babies... somehow" : summaryComponents.joined(separator: "    ")
    }
    
    /// Returns an array of colors corresponding to the baby counts by sex.
    private func gradientColors(for babies: [Baby]) -> [Color] {
        let maleCount = babies.filter { $0.sex == .male }.count
        let femaleCount = babies.filter { $0.sex == .female }.count
        let lossCount = babies.filter { $0.sex == .loss }.count
        
        return Array(repeating: Color("storkBlue"), count: maleCount) +
               Array(repeating: Color("storkPink"), count: femaleCount) +
               Array(repeating: Color("storkPurple"), count: lossCount)
    }
}

#Preview {
    DeliveryRowView(delivery: Delivery(
        id: "1",
        userId: "user1",
        userFirstName: "FirstName",
        hospitalId: "Hospital1",
        hospitalName: "Hospital Name",
        musterId: "Muster1",
        date: Date(),
        babies: [
            Baby(id: "1", deliveryId: "1", birthday: Date(), height: 20.0, weight: 7.5, nurseCatch: true, nicuStay: false, sex: .male),
            Baby(id: "2", deliveryId: "1", birthday: Date(), height: 19.5, weight: 7.0, nurseCatch: false, nicuStay: true, sex: .female),
            Baby(id: "3", deliveryId: "1", birthday: Date(), height: 19.0, weight: 6.5, nurseCatch: true, nicuStay: false, sex: .female)
        ],
        babyCount: 3,
        deliveryMethod: .vaginal,
        epiduralUsed: true
    ))
    .environmentObject(AppStorageManager())
}
