//
//  JarHistoryView.swift
//  Stork
//
//  Created by Nick Molargik on 2/16/26.
//

import SwiftUI

struct JarHistoryView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPage: Int = 0

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

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedPage) {
                ForEach(Array(months.enumerated()), id: \.element.key) { index, month in
                    let counts = jarCounts(for: month.date)
                    JarHistoryPage(
                        boyCount: counts.boy,
                        girlCount: counts.girl,
                        lossCount: counts.loss,
                        monthDate: month.date,
                        monthKey: month.key
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .safeAreaInset(edge: .bottom) {
                pageIndicator
                    .padding(.bottom, 8)
            }
            .navigationTitle("Jar History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundStyle(.storkOrange)
                    .keyboardShortcut(.escape, modifiers: [])
                    .hoverEffect(.highlight)
                }
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(months.indices, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: selectedPage == index ? 10 : 7, height: selectedPage == index ? 10 : 7)
                    .animation(.easeInOut(duration: 0.2), value: selectedPage)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index == selectedPage {
            return .storkOrange
        }
        let counts = jarCounts(for: months[index].date)
        let total = counts.boy + counts.girl + counts.loss
        return total > 0 ? .storkBlue : .gray.opacity(0.4)
    }

    private func jarCounts(for monthStart: Date) -> (boy: Int, girl: Int, loss: Int) {
        let cal = Calendar.current
        let endExclusive = cal.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart

        let recentDeliveries = deliveryManager.deliveries.filter { d in
            (d.date >= monthStart) && (d.date < endExclusive)
        }
        let babies = recentDeliveries.flatMap { $0.babies ?? [] }
        let boy  = babies.lazy.filter { $0.sex == .male }.count
        let girl = babies.lazy.filter { $0.sex == .female }.count
        let loss = babies.lazy.filter { $0.sex == .loss }.count
        return (boy, girl, loss)
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
        JarView(
            boyCount: boyCount,
            girlCount: girlCount,
            lossCount: lossCount,
            monthLabel: monthLabel(),
            reshuffle: $reshuffle
        )
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
