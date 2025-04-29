//
//  BabySexDistributionView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 01/01/25.
//

import SwiftUI
import StorkModel

// MARK: - BabySexDistributionData Model
/// Represents a data point in the pie chart.
struct BabySexDistributionData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let color: Color
}

// MARK: - BabySexDistributionView
/// A SwiftUI view that displays the distribution of baby sexes in a pie chart.
struct BabySexDistributionView: View {
    // MARK: - Properties
    @Binding var groupedDeliveries: [(key: String, value: [Delivery])]
    @State private var distributionData: [BabySexDistributionData] = []
    @State private var sliceAngles: [Double] = [] // Store the end angles of slices for animation
    
    // MARK: - Body
    var body: some View {
        VStack {
            Text("6 Month Sex Distribution")
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .frame(height: 40)
                .padding(.bottom, 10)
            
            if distributionData.isEmpty {
                Text("No data available")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                GeometryReader { geometry in
                    ZStack {
                        if distributionData.isEmpty {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.9)
                        } else {
                            ForEach(0..<distributionData.count, id: \.self) { index in
                                let startAngle = index == 0 ? 0.0 : sliceAngles[index - 1]
                                let endAngle = sliceAngles[index]
                                
                                Path { path in
                                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                    let radius = min(geometry.size.width, geometry.size.height) / 2
                                    
                                    path.move(to: center)
                                    path.addArc(
                                        center: center,
                                        radius: radius,
                                        startAngle: Angle(degrees: startAngle),
                                        endAngle: Angle(degrees: endAngle),
                                        clockwise: false
                                    )
                                }
                                .fill(distributionData[index].color)
                                .shadow(color: distributionData[index].color, radius: 5)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.vertical, 5)
                
                HStack {
                    ForEach(["Male", "Female", "Loss"], id: \.self) { category in
                        // Look up existing data for this category; fall back to default color & 0 count
                        let data = distributionData.first { $0.category == category }
                        let count = data?.count ?? 0
                        let color: Color = {
                            switch category {
                            case "Male":   return Color("storkBlue")
                            case "Female": return Color("storkPink")
                            default:       return Color("storkPurple")
                            }
                        }()
                        
                        Circle()
                            .fill(data?.color ?? color)
                            .frame(width: 10, height: 10)
                        
                        Text("\(category): \(count)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            aggregateBabySexData()
        }
        .onChange(of: groupedDeliveries.count) { _ in
            aggregateBabySexData()
        }
    }
    
    // MARK: - Helper Methods
    private func aggregateBabySexData() {
        var maleCount = 0
        var femaleCount = 0
        var lossCount = 0
        
        for (_, deliveries) in groupedDeliveries {
            for delivery in deliveries {
                for baby in delivery.babies {
                    switch baby.sex {
                    case .male:
                        maleCount += 1
                    case .female:
                        femaleCount += 1
                    case .loss:
                        lossCount += 1
                    }
                }
            }
        }
        
        let newData = [
            BabySexDistributionData(category: "Male", count: maleCount, color: Color("storkBlue")),
            BabySexDistributionData(category: "Female", count: femaleCount, color: Color("storkPink")),
            BabySexDistributionData(category: "Loss", count: lossCount, color: Color("storkPurple"))
        ].filter { $0.count > 0 }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            distributionData = newData
            updateSliceAngles()
        }
    }
    
    private func updateSliceAngles() {
        let total = distributionData.map { $0.count }.reduce(0, +)
        var cumulativeAngle: Double = 0
        sliceAngles = distributionData.map { data in
            let angle = cumulativeAngle + (Double(data.count) / Double(total)) * 360.0
            defer { cumulativeAngle = angle }
            return angle
        }
    }
}

#Preview {
    BabySexDistributionView(groupedDeliveries: .constant([
        // Sample grouped deliveries data
        (key: "July '24", value: [
            Delivery(id: "1", userId: "U1", userFirstName: "Alice",
                     hospitalId: "H1", hospitalName: "General Hospital", musterId: "M1",
                     date: Date(),
                     babies: [
                        Baby(deliveryId: "1", nurseCatch: true,  nicuStay: false, sex: .male),
                        Baby(deliveryId: "1", nurseCatch: false, nicuStay: false, sex: .female)
                     ],
                     babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: true)
        ]),
        (key: "August '24", value: [
            Delivery(id: "2", userId: "U2", userFirstName: "Bob",
                     hospitalId: "H2", hospitalName: "City Hospital", musterId: "M2",
                     date: Date(),
                     babies: [
                        Baby(deliveryId: "2", nurseCatch: false, nicuStay: false, sex: .male),
                        Baby(deliveryId: "2", nurseCatch: true,  nicuStay: false, sex: .loss)
                     ],
                     babyCount: 2, deliveryMethod: .cSection, epiduralUsed: false)
        ])
    ]))
}
