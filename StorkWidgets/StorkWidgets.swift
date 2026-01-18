//
//  StorkWidgets.swift
//  StorkWidgets
//
//  Created by Nick Molargik on 11/3/25.
//

import WidgetKit
import SwiftUI
import Foundation
import SwiftData

// Where the app writes the current week's count
enum SharedKeys {
    static let deliveriesThisWeekCount = "deliveriesThisWeekCount"
}

// MARK: - Week helpers (Sunday → Saturday)
struct WeekRange {
    let start: Date // Sunday 00:00
    let end: Date   // next Sunday 00:00 (exclusive)
}

extension Calendar {
    static var gregorianUS: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.firstWeekday = 1 // Sunday
        cal.minimumDaysInFirstWeek = 1
        return cal
    }
}

func currentWeekRange(now: Date = Date(), calendar: Calendar = .gregorianUS) -> WeekRange {
    let weekday = calendar.component(.weekday, from: now) // 1..7 (Sun=1)
    let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -(weekday - 1), to: now)!)
    let end = calendar.date(byAdding: .day, value: 7, to: start)!
    return WeekRange(start: start, end: end)
}

func formattedWeekString(_ range: WeekRange) -> String {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.setLocalizedDateFormatFromTemplate("MMM d")
    let startText = df.string(from: range.start)
    let endText = df.string(from: Calendar.gregorianUS.date(byAdding: .day, value: -1, to: range.end)!)
    return "\(startText) – \(endText)"
}

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
    let week = currentWeekRange()
    let start = week.start
    let end = week.end
    let container = try widgetModelContainer()
    let context = ModelContext(container)

    var desc = FetchDescriptor<Delivery>()
    desc.predicate = #Predicate<Delivery> { d in
        d.date >= start && d.date < end
    }
    // If you have a large store, you can limit properties here or prefetch relationships.
    let deliveries = try context.fetch(desc)
    let totalBabies = deliveries.reduce(0) { sum, delivery in
        sum + (delivery.babies?.count ?? 0)
    }
    return totalBabies
}

/// Fallback if SwiftData isn't accessible in the widget for any reason.
func readBabiesCountFallback() -> Int {
    guard let defaults = UserDefaults(suiteName: AppGroup.id) else { return 0 }
    // Allow the app to write a precomputed babies-this-week count if needed.
    let count = defaults.integer(forKey: "babiesThisWeekCount")
    return max(count, 0)
}

// MARK: - Timeline
struct DeliveriesWeekEntry: TimelineEntry {
    let date: Date
    let count: Int
    let week: WeekRange
}

struct DeliveriesWeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeliveriesWeekEntry {
        let wk = currentWeekRange()
        return DeliveriesWeekEntry(date: Date(), count: 3, week: wk)
    }

    func getSnapshot(in context: Context, completion: @escaping (DeliveriesWeekEntry) -> Void) {
        let wk = currentWeekRange()
        Task { @MainActor in
            let count: Int
            do { count = try babiesThisWeekCount() }
            catch { count = readBabiesCountFallback() }
            completion(DeliveriesWeekEntry(date: Date(), count: count, week: wk))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeliveriesWeekEntry>) -> Void) {
        let now = Date()
        let wk = currentWeekRange(now: now)

        // Refresh at next midnight and at week rollover (next Sunday 00:00)
        let nextMidnight = Calendar.gregorianUS.startOfDay(for: Calendar.gregorianUS.date(byAdding: .day, value: 1, to: now)!)
        let nextWeekStart = wk.end
        let refresh = min(nextMidnight, nextWeekStart)

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
            Text(formattedWeekString(entry.week))
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Widget
struct DeliveriesThisWeekWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DeliveriesThisWeekWidget", provider: DeliveriesWeekProvider()) { entry in
            if #available(iOS 17.0, *) {
                Link(destination: URL(string: "stork://deliveries/week")!) {
                    DeliveriesWeekView(entry: entry)
                        .containerBackground(.fill.tertiary, for: .widget)
                }
            } else {
                Link(destination: URL(string: "stork://deliveries/week")!) {
                    DeliveriesWeekView(entry: entry)
                        .padding()
                        .background()
                }
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
    DeliveriesWeekEntry(date: .now, count: 2, week: currentWeekRange())
    DeliveriesWeekEntry(date: .now, count: 5, week: currentWeekRange())
}
