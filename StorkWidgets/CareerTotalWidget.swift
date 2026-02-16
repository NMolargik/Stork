//
//  CareerTotalWidget.swift
//  StorkWidgets
//
//  Created by Nick Molargik on 1/17/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Career Total Entry
struct CareerTotalEntry: TimelineEntry {
    let date: Date
    let totalBabies: Int
    let totalDeliveries: Int
}

// MARK: - Career Total Provider
struct CareerTotalProvider: TimelineProvider {
    func placeholder(in context: Context) -> CareerTotalEntry {
        CareerTotalEntry(date: Date(), totalBabies: 1234, totalDeliveries: 567)
    }

    func getSnapshot(in context: Context, completion: @escaping (CareerTotalEntry) -> Void) {
        Task { @MainActor in
            let entry = fetchCareerTotals()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CareerTotalEntry>) -> Void) {
        Task { @MainActor in
            let entry = fetchCareerTotals()
            // Refresh every hour
            let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            completion(timeline)
        }
    }

    @MainActor
    private func fetchCareerTotals() -> CareerTotalEntry {
        do {
            let container = try widgetModelContainer()
            let context = ModelContext(container)

            // Fetch all deliveries
            let deliveryDesc = FetchDescriptor<Delivery>()
            let deliveries = try context.fetch(deliveryDesc)

            let totalDeliveries = deliveries.count
            let totalBabies = deliveries.reduce(0) { $0 + ($1.babies?.count ?? 0) }

            return CareerTotalEntry(
                date: Date(),
                totalBabies: totalBabies,
                totalDeliveries: totalDeliveries
            )
        } catch {
            // Fallback to UserDefaults
            let defaults = UserDefaults(suiteName: AppGroup.id)
            let babies = defaults?.integer(forKey: "careerTotalBabies") ?? 0
            let deliveries = defaults?.integer(forKey: "careerTotalDeliveries") ?? 0
            return CareerTotalEntry(date: Date(), totalBabies: babies, totalDeliveries: deliveries)
        }
    }
}

// MARK: - Career Total Small View
struct CareerTotalSmallView: View {
    let entry: CareerTotalEntry

    var body: some View {
        VStack(spacing: 8) {
            Image("storkicon")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Text("\(entry.totalBabies)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .privacySensitive()

            Text("Career Total")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Career Total Widget
struct CareerTotalWidget: Widget {
    let kind: String = "CareerTotalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CareerTotalProvider()) { entry in
            if #available(iOS 17.0, *) {
                Link(destination: URL(string: "stork://dashboard")!) {
                    CareerTotalSmallView(entry: entry)
                        .containerBackground(.fill.tertiary, for: .widget)
                }
            } else {
                Link(destination: URL(string: "stork://dashboard")!) {
                    CareerTotalSmallView(entry: entry)
                        .padding()
                        .background()
                }
            }
        }
        .configurationDisplayName("Career Total")
        .description("Your lifetime baby count.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    CareerTotalWidget()
} timeline: {
    CareerTotalEntry(date: .now, totalBabies: 1234, totalDeliveries: 567)
    CareerTotalEntry(date: .now, totalBabies: 1235, totalDeliveries: 568)
}
