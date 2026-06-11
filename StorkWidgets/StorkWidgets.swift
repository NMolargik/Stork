//
//  StorkWidgets.swift
//  StorkWidgets
//

import WidgetKit
import SwiftUI
import Foundation
import SwiftData

// MARK: - Data read (CloudKit-synced SwiftData)

@MainActor
func widgetModelContainer() throws -> ModelContainer {
    let cloudKitContainerID = "iCloud.com.molargiksoftware.Stork"
    let config = ModelConfiguration(
        cloudKitDatabase: .private(cloudKitContainerID)
    )
    return try ModelContainer(for: Delivery.self, Baby.self, DeliveryTag.self, configurations: config)
}

@MainActor
func babiesThisWeekCount() throws -> Int {
    let week = WeekMath.weekRange()
    let start = week.start
    let end = week.end
    let container = try widgetModelContainer()
    let context = ModelContext(container)

    var desc = FetchDescriptor<Delivery>()
    desc.predicate = #Predicate<Delivery> { d in
        d.date >= start && d.date < end
    }
    let deliveries = try context.fetch(desc)
    return deliveries.reduce(0) { sum, delivery in
        sum + (delivery.babies?.count ?? 0)
    }
}

/// Fallback if SwiftData isn't accessible in the widget for any reason.
func readBabiesCountFallback() -> Int {
    guard let defaults = UserDefaults(suiteName: AppGroup.id) else { return 0 }
    return max(defaults.integer(forKey: SharedDefaultsKey.babiesThisWeekCount), 0)
}

// MARK: - Timeline

struct DeliveriesWeekEntry: TimelineEntry {
    let date: Date
    let count: Int
    let week: WeekMath.WeekRange
}

struct DeliveriesWeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeliveriesWeekEntry {
        DeliveriesWeekEntry(date: Date(), count: 3, week: WeekMath.weekRange())
    }

    func getSnapshot(in context: Context, completion: @escaping (DeliveriesWeekEntry) -> Void) {
        let wk = WeekMath.weekRange()
        Task { @MainActor in
            let count: Int
            do { count = try babiesThisWeekCount() }
            catch { count = readBabiesCountFallback() }
            completion(DeliveriesWeekEntry(date: Date(), count: count, week: wk))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeliveriesWeekEntry>) -> Void) {
        let now = Date()
        let wk = WeekMath.weekRange(containing: now)

        // Refresh at next midnight and at week rollover (next Sunday 00:00)
        let cal = WeekMath.sundayFirstCalendar
        let nextMidnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
        let refresh = min(nextMidnight, wk.end)

        Task { @MainActor in
            let count: Int
            do { count = try babiesThisWeekCount() }
            catch { count = readBabiesCountFallback() }
            let entry = DeliveriesWeekEntry(date: now, count: count, week: wk)
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }
}

// MARK: - Views

struct DeliveriesWeekView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DeliveriesWeekEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("Babies\nThis Week")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: true, vertical: true)
            Text("\(entry.count)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .privacySensitive()
                .foregroundStyle(.storkOrange)
            Text(WeekMath.formattedWeekString(entry.week))
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.secondary)
        }
        .padding()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Babies this week")
        .accessibilityValue("\(entry.count), \(WeekMath.formattedWeekString(entry.week))")
    }
}

// MARK: - Widget

struct DeliveriesThisWeekWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.deliveriesThisWeek, provider: DeliveriesWeekProvider()) { entry in
            Link(destination: URL(string: "stork://deliveries/week")!) {
                DeliveriesWeekView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
        }
        .configurationDisplayName("Babies This Week")
        .description("Number of babies from Sunday to Saturday.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    DeliveriesThisWeekWidget()
} timeline: {
    DeliveriesWeekEntry(date: .now, count: 2, week: WeekMath.weekRange())
    DeliveriesWeekEntry(date: .now, count: 5, week: WeekMath.weekRange())
}
