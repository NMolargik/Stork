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
    @State var groupedDeliveries: [(key: String, value: [Delivery])]
    @State private var distributionData: [BabySexDistributionData] = []
    @State private var sliceAngles: [Double] = [] // Store the end angles of slices for animation
    
    // MARK: - Body
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("6 Months")
                        .multilineTextAlignment(.leading)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                    
                    if distributionData.isEmpty {
                        Text("No data available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(distributionData) { data in
                            HStack {
                                Circle()
                                    .fill(data.color)
                                    .frame(width: 10, height: 10)
                                
                                Text("\(data.category): \(data.count)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding()
                
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
                .aspectRatio(1, contentMode: .fit)
                .scaleEffect(0.9)
                .padding()
                .frame(width: 200)
            }
            .onAppear {
                aggregateBabySexData()
            }
            .onChange(of: groupedDeliveries.count) { _ in
                aggregateBabySexData()
            }
            
            Spacer()
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
            BabySexDistributionData(category: "Male", count: maleCount, color: .blue),
            BabySexDistributionData(category: "Female", count: femaleCount, color: .pink),
            BabySexDistributionData(category: "Loss", count: lossCount, color: .purple)
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

// MARK: - Preview
struct BabySexDistributionView_Previews: PreviewProvider {
    static var previews: some View {
        BabySexDistributionView(groupedDeliveries: [
            // Sample grouped deliveries data
            (key: "July '24", value: [
                Delivery(id: "1", userId: "U1", userFirstName: "Alice", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M1", date: Date(), babies: [
                    Baby(deliveryId: "1", nurseCatch: true, sex: .male),
                    Baby(deliveryId: "1", nurseCatch: false, sex: .female)
                ], babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: true)
            ]),
            (key: "August '24", value: [
                Delivery(id: "2", userId: "U2", userFirstName: "Bob", hospitalId: "H2", hospitalName: "City Hospital", musterId: "M2", date: Date(), babies: [
                    Baby(deliveryId: "2", nurseCatch: false, sex: .male),
                    Baby(deliveryId: "2", nurseCatch: true, sex: .loss)
                ], babyCount: 2, deliveryMethod: .cSection, epiduralUsed: false)
            ])
        ])
    }
}
