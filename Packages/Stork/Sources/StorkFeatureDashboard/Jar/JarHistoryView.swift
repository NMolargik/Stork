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
    private let isProUnlocked: Bool
    @State private var selectedPage = 0

    public init(deliveries: [Delivery], isProUnlocked: Bool = false) {
        self.deliveries = deliveries
        self.isProUnlocked = isProUnlocked
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
                    JarHistoryPage(marbles: DeliveryStatistics.jarMarbles(deliveries: deliveries, asOf: month.date), monthDate: month.date, monthKey: month.key, isProUnlocked: isProUnlocked)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .safeAreaInset(edge: .bottom) {
                PageIndicator(months: months, deliveries: deliveries, selectedPage: selectedPage)
                    .padding(.bottom, 8)
            }
            .navigationTitle(Text("Jar History", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .keyboardShortcut(.escape, modifiers: [])
                        .hoverEffect(.highlight)
                        .accessibilityLabel(Text("Close jar history", bundle: .module))
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
            .accessibilityLabel(Text("Page \(selectedPage + 1) of \(months.count)", bundle: .module))
        }

        private func dotColor(for index: Int) -> Color {
            if index == selectedPage { return .storkOrange }
            return !DeliveryStatistics.jarMarbles(deliveries: deliveries, asOf: months[index].date).isEmpty ? .storkBlue : .gray.opacity(0.4)
        }
    }
}

private struct JarHistoryPage: View {
    let marbles: [JarMarble]
    let monthDate: Date
    let monthKey: String
    let isProUnlocked: Bool
    @State private var reshuffle = false
    @State private var selection: JarCategory?

    var body: some View {
        VStack(spacing: 12) {
            JarView(marbles: marbles, highlight: selection, monthLabel: monthLabel(), reshuffle: $reshuffle)
                .id(monthKey)
            JarLegendView(marbles: marbles, monthDate: monthDate, isProUnlocked: isProUnlocked, selection: $selection)
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
    }

    private func monthLabel() -> String {
        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "LLLL yyyy"
        return df.string(from: monthDate)
    }
}
#endif
