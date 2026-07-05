//
//  JarHistoryView.swift
//  StorkFeatureDashboard
//
//  A paged history of monthly marble jars for the last 12 months.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

public struct JarHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    private let deliveries: [Delivery]
    @State private var selectedPage = 0

    public init(deliveries: [Delivery]) {
        self.deliveries = deliveries
    }

    private let months: [(date: Date, key: String)] = {
        let cal = Calendar.current
        let today = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        return (0...11).compactMap { i in
            guard let date = cal.date(byAdding: .month, value: -i, to: today) else { return nil }
            let start = cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
            return (start, df.string(from: start))
        }
    }()

    public var body: some View {
        NavigationStack {
            TabView(selection: $selectedPage) {
                ForEach(Array(months.enumerated()), id: \.element.key) { index, month in
                    let counts = DeliveryStatistics.monthlyJarCounts(deliveries: deliveries, asOf: month.date)
                    JarHistoryPage(boyCount: counts.boy, girlCount: counts.girl, lossCount: counts.loss, monthDate: month.date, monthKey: month.key)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .safeAreaInset(edge: .bottom) {
                PageIndicator(months: months, deliveries: deliveries, selectedPage: selectedPage)
                    .padding(.bottom, 8)
            }
            .navigationTitle("Jar History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .keyboardShortcut(.escape, modifiers: [])
                        .hoverEffect(.highlight)
                        .accessibilityLabel("Close jar history")
                }
            }
        }
    }

    private struct PageIndicator: View {
        let months: [(date: Date, key: String)]
        let deliveries: [Delivery]
        let selectedPage: Int

        var body: some View {
            HStack(spacing: 6) {
                ForEach(months.indices, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: selectedPage == index ? 10 : 7, height: selectedPage == index ? 10 : 7)
                        .animation(.easeInOut(duration: 0.2), value: selectedPage)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(selectedPage + 1) of \(months.count)")
        }

        private func dotColor(for index: Int) -> Color {
            if index == selectedPage { return .storkOrange }
            let counts = DeliveryStatistics.monthlyJarCounts(deliveries: deliveries, asOf: months[index].date)
            return (counts.boy + counts.girl + counts.loss) > 0 ? .storkBlue : .gray.opacity(0.4)
        }
    }
}

private struct JarHistoryPage: View {
    let boyCount: Int
    let girlCount: Int
    let lossCount: Int
    let monthDate: Date
    let monthKey: String
    @State private var reshuffle = false

    var body: some View {
        JarView(boyCount: boyCount, girlCount: girlCount, lossCount: lossCount, monthLabel: monthLabel(), reshuffle: $reshuffle)
            .id(monthKey)
            .padding(.horizontal)
    }

    private func monthLabel() -> String {
        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "LLLL yyyy"
        return df.string(from: monthDate)
    }
}
#endif
