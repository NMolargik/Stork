//
//  DeliveriesThisWeekView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/31/24.
//

import SwiftUI
import StorkModel

// MARK: - DeliveryData Model
struct DeliveryGraphData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// MARK: - DeliveriesThisWeek View
struct DeliveriesThisWeekView: View {
    // MARK: - Properties
    @Binding var deliveries: [Delivery]
    
    /// Aggregated deliveries for the last seven days
    @State private var deliveriesLastSevenDays: [DeliveryGraphData] = []
    @State private var animatedDeliveries: [DeliveryGraphData] = []
    
    /// Date Formatter for X-Axis Labels
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    var body: some View {
        GeometryReader { parentGeo in
            let chartHeight = parentGeo.size.height * 2/3
            
            VStack {
                if deliveriesLastSevenDays.isEmpty {
                    Text("No delivery data available for the past seven days.")
                        .font(.headline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Text("Deliveries This Week")
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
                            .stroke(Color.gray.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 1, dash: [4.0, 4.0]))
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
                    .frame(height: chartHeight)
                    .padding(.horizontal)
                    
                    // X‑axis weekday labels (absolute positioning for Skip/Compose)
                    GeometryReader { geo in
                        let w  = geo.size.width
                        let stepX = w / CGFloat(max(animatedDeliveries.count - 1, 1))

                        // Enumerate indices directly so each weekday appears exactly once
                        ForEach(Array(animatedDeliveries.enumerated()), id: \.offset) { idx, point in
                            let xPos = stepX * CGFloat(idx)
                            Text(dateFormatter.string(from: point.date))
                                .font(.caption)
                                .foregroundColor(.primary)
                                .position(x: xPos, y: 16)   // center of a 24‑pt tall area
                        }
                    }
                    .frame(height: 24)
                    #if SKIP
                    .padding(.top, 20)          // extra gap below plot when transpiled
                    #endif
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                aggregateDeliveries()
            }
            .onChange(of: deliveries) { _ in
                aggregateDeliveries()
            }
        }
    }
    
    private func aggregateDeliveries() {
        let calendar = Calendar.current
        let now      = Date()
        let today    = calendar.startOfDay(for: now)
        let weekday  = calendar.component(.weekday, from: now)          // 1 = Sunday

        // Most‑recent Sunday
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)
        else { deliveriesLastSevenDays = []; return }

        // Build a fixed list of the 7 day starts (Sun → Sat)
        var weekDates: [Date] = []
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) {
                weekDates.append(date)
            }
        }

        // Count deliveries per start‑of‑day
        var counts: [Date: Int] = [:]
        for delivery in deliveries {
            let d = calendar.startOfDay(for: delivery.date)
            if let matched = weekDates.first(where: { calendar.isDate($0, inSameDayAs: d) }) {
                counts[matched, default: 0] += 1
            }
        }

        // Convert to graph data in guaranteed order Sunday‑through‑Saturday
        let updatedData = weekDates.map { dayStart in
            DeliveryGraphData(date: dayStart, count: counts[dayStart, default: 0])
        }

        #if !SKIP
        withAnimation(.easeInOut(duration: 1.0)) {
            deliveriesLastSevenDays = updatedData
            animatedDeliveries      = updatedData
        }
        #else
        deliveriesLastSevenDays = updatedData
        animatedDeliveries      = updatedData
        #endif
    }
}

#Preview {
    DeliveriesThisWeekView(deliveries: .constant([]))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
