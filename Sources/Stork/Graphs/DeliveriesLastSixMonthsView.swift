//
//  DeliveriesLastSixMonthsView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 01/01/25.
//

import SwiftUI
import StorkModel

// MARK: - DeliveryGraphMonthData Model
/// Represents the aggregated delivery data for a specific month.
struct DeliveryGraphMonthData: Identifiable {
    let id = UUID()
    let month: String      // e.g., "December '24"
    let date: Date         // First day of the month for accurate plotting
    let count: Int         // Number of deliveries in the month
}

// MARK: - DeliveriesLastSixMonthsView View
/// A SwiftUI view that displays a line chart of deliveries per month for the last six months.
struct DeliveriesLastSixMonthsView: View {
    // MARK: - Properties
    
    @Binding var groupedDeliveries: [(key: String, value: [Delivery])]
    
    @State private var deliveriesLastSix: [DeliveryGraphMonthData] = []
    @State private var animatedDeliveries: [DeliveryGraphMonthData] = []
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM ''yy"
        formatter.locale = Locale.current
        return formatter
    }()
    
    // MARK: - Body
var body: some View {
    GeometryReader { parentGeo in
        let chartHeight = parentGeo.size.height * 2/3
        
        VStack {
            Text("Deliveries In The Last 6 Months")
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .padding(.bottom, 10)
            
            Spacer()
            
            // MARK: - Hand‑drawn line chart (no Charts framework)
            GeometryReader { geo in
                let w  = geo.size.width
                let h  = geo.size.height
                let maxVal = (animatedDeliveries.map(\.count).max() ?? 1)
                let stepX  = w / CGFloat(max(animatedDeliveries.count - 1, 1))
                
                // Vertical grid lines
                ForEach(0 ..< animatedDeliveries.count, id: \.self) { idx in
                    let x = stepX * CGFloat(idx)
                    Path { p in
                        p.move(to: .init(x: x, y: 0))
                        p.addLine(to: .init(x: x, y: h))
                    }
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4.0, 4.0]))
                }
                
                // Area under curve
                Path { p in
                    guard let first = animatedDeliveries.first else { return }
                    let firstY = h - (CGFloat(first.count) / CGFloat(maxVal)) * h
                    p.move(to: .init(x: 0, y: h))
                    p.addLine(to: .init(x: 0, y: firstY))
                    
                    for (idx, point) in animatedDeliveries.enumerated() {
                        let x = stepX * CGFloat(idx)
                        let y = h - (CGFloat(point.count) / CGFloat(maxVal)) * h
                        p.addLine(to: .init(x: x, y: y))
                    }
                    p.addLine(to: .init(x: w, y: h))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color("storkIndigo").opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Stroke line
                Path { p in
                    guard let first = animatedDeliveries.first else { return }
                    let firstY = h - (CGFloat(first.count) / CGFloat(maxVal)) * h
                    p.move(to: .init(x: 0, y: firstY))
                    
                    for (idx, point) in animatedDeliveries.enumerated() {
                        let x = stepX * CGFloat(idx)
                        let y = h - (CGFloat(point.count) / CGFloat(maxVal)) * h
                        p.addLine(to: .init(x: x, y: y))
                    }
                }
                .stroke(Color("storkIndigo"), lineWidth: 2)
                
                // Points + labels
                ForEach(Array(animatedDeliveries.enumerated()).filter { $0.element.count > 0 },
                        id: \.element.id) { idx, point in
                    let x = stepX * CGFloat(idx)
                    let y = h - (CGFloat(point.count) / CGFloat(maxVal)) * h
                    Circle()
                        .fill(Color("storkOrange"))
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                    
                    Text("\(point.count)")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                        .position(x: x, y: y - 14)
                }
            }
            .frame(height: chartHeight)   // 2⁄3 of parent’s height
            .padding(.horizontal)
            
            // X‑axis month labels (absolute positioning for Skip/Compose)
            GeometryReader { geo in
                let w  = geo.size.width
                let stepX = w / CGFloat(max(animatedDeliveries.count - 1, 1))
                ForEach(animatedDeliveries) { point in
                    let idx = animatedDeliveries.firstIndex(where: { $0.id == point.id }) ?? 0
                    let xPos = stepX * CGFloat(idx)
                    Text(String(point.month.prefix(3)))
                        .font(.caption)
                        .foregroundColor(.primary)
                        // place a bit lower to avoid the zero-value line
                        .position(x: xPos, y: 16)   // shifted 2 pt lower inside the taller area
                }
            }
            .frame(height: 24)          // a bit taller
            #if SKIP
            .padding(.top, 20)           // adds clear gap below the plot
            #else
            .padding(.bottom)
            #endif
        }
        .padding()
        .onAppear {
            aggregateMonthlyDeliveries()
        }
        .onChange(of: groupedDeliveries.count) { _ in
            aggregateMonthlyDeliveries()
        }
    }
}
    
    // MARK: - Data Aggregation
    private func aggregateMonthlyDeliveries() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var lastSixMonthsKeys: [String] = []
        var lastSixMonthsDates: [Date] = []
        
        for offset in 0..<6 {
            if let date = calendar.date(byAdding: .month, value: -offset, to: today) {
                let key = dateFormatter.string(from: date)
                lastSixMonthsKeys.append(key)
                
                let components = calendar.dateComponents([.year, .month], from: date)
                if let firstOfMonth = calendar.date(from: components) {
                    lastSixMonthsDates.append(firstOfMonth)
                }
            }
        }
        
        lastSixMonthsKeys.reverse()
        lastSixMonthsDates.reverse()
        
        var tempAggregatedData: [DeliveryGraphMonthData] = []
        
        for (index, key) in lastSixMonthsKeys.enumerated() {
            if let deliveriesInMonth = groupedDeliveries.first(where: { $0.key == key })?.value {
                let count = deliveriesInMonth.count
                let date = lastSixMonthsDates[index]
                let monthData = DeliveryGraphMonthData(month: key, date: date, count: count)
                tempAggregatedData.append(monthData)
            } else {
                let date = lastSixMonthsDates[index]
                let monthData = DeliveryGraphMonthData(month: key, date: date, count: 0)
                tempAggregatedData.append(monthData)
            }
        }
        
        // Assign to the state variable.
        self.deliveriesLastSix = tempAggregatedData
        
        // Animate the data
        #if !SKIP
        withAnimation(.easeInOut(duration: 1.5)) {
            self.animatedDeliveries = tempAggregatedData
        }
        #else
            self.animatedDeliveries = tempAggregatedData
        #endif
    }
}

#Preview {
    DeliveriesLastSixMonthsView(groupedDeliveries: .constant([
        // Sample data for preview purposes
        (key: "July '24", value: [
            Delivery(id: "1", userId: "U1", userFirstName: "Alice", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M1", date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, babies: [], babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: true),
            Delivery(id: "2", userId: "U2", userFirstName: "Bob", hospitalId: "H2", hospitalName: "City Hospital", musterId: "M2", date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, babies: [], babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false)
        ]),
        (key: "August '24", value: [
            Delivery(id: "3", userId: "U3", userFirstName: "Charlie", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M3", date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, babies: [], babyCount: 3, deliveryMethod: .cSection, epiduralUsed: true)
        ]),
        (key: "September '24", value: [
            Delivery(id: "4", userId: "U4", userFirstName: "Diana", hospitalId: "H3", hospitalName: "County Hospital", musterId: "M4", date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, babies: [], babyCount: 1, deliveryMethod: .vBac, epiduralUsed: false)
        ]),
        (key: "October '24", value: [
            Delivery(id: "5", userId: "U5", userFirstName: "Ethan", hospitalId: "H2", hospitalName: "City Hospital", musterId: "M5", date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, babies: [], babyCount: 2, deliveryMethod: .cSection, epiduralUsed: true)
        ]),
        (key: "November '24", value: []),
        (key: "December '24", value: [
            Delivery(id: "6", userId: "U6", userFirstName: "Fiona", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M6", date: Date(), babies: [], babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false)
        ])
    ]))
}
