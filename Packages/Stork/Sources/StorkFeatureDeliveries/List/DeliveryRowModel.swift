//
//  DeliveryRowModel.swift
//  StorkFeatureDeliveries
//
//  Precomputed presentation for a single delivery row: sex tallies, summary, gradient,
//  badge symbols, and the animated-title formatting.
//

import SwiftUI
import StorkCore
import StorkDesignSystem

@MainActor
@Observable
final class DeliveryRowModel {
    private let delivery: Delivery

    let maleCount: Int
    let femaleCount: Int
    let lossCount: Int
    let totalBabies: Int
    let showsNICUIcon: Bool
    let showsEpiduralIcon: Bool
    let showsCSectionIcon: Bool
    let babySummary: String
    let gradientColors: [Color]
    let accessibilitySummary: String

    struct DotSegment {
        let color: Color
        let count: Int
    }

    var nicuSymbolName: String? { showsNICUIcon ? "bed.double" : nil }
    var epiduralSymbolName: String? { showsEpiduralIcon ? "syringe.fill" : nil }
    var cSectionSymbolName: String? { showsCSectionIcon ? "c.circle" : nil }

    var iconForegroundColor: Color { .black }
    var iconBackgroundColor: Color { .white }

    var dotSegments: [DotSegment] {
        [
            DotSegment(color: .storkBlue, count: maleCount),
            DotSegment(color: .storkPink, count: femaleCount),
            DotSegment(color: .storkPurple, count: lossCount),
        ].filter { $0.count > 0 }
    }

    var hasSecondary: Bool { totalBabies > 0 }

    init(delivery: Delivery) {
        self.delivery = delivery
        let babies = delivery.babies ?? []

        let male = babies.count { $0.sex == .male }
        let female = babies.count { $0.sex == .female }
        let loss = babies.count { $0.sex == .loss }

        maleCount = male
        femaleCount = female
        lossCount = loss
        totalBabies = male + female + loss
        showsNICUIcon = babies.contains { $0.nicuStay }
        showsEpiduralIcon = delivery.epiduralUsed
        showsCSectionIcon = delivery.deliveryMethod == .cSection
        babySummary = Self.computeBabySummary(male: male, female: female, loss: loss)
        gradientColors = Self.computeGradientColors(male: male, female: female, loss: loss)
        accessibilitySummary = Self.computeAccessibilitySummary(delivery: delivery, male: male, female: female, loss: loss)
    }

    func primaryTitle(useDayMonthYear: Bool) -> String {
        let date = delivery.date

        let timeFormatter = DateFormatter()
        timeFormatter.locale = .current
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        let time = timeFormatter.string(from: date)

        let day = Calendar.current.component(.day, from: date)
        let suffix = Self.ordinalSuffix(for: day)

        let monthFormatter = DateFormatter()
        monthFormatter.locale = .current
        monthFormatter.setLocalizedDateFormatFromTemplate("MMMM")
        let month = monthFormatter.string(from: date)

        return useDayMonthYear ? "\(day)\(suffix) \(month) @ \(time)" : "\(month) \(day)\(suffix) @ \(time)"
    }

    private static func ordinalSuffix(for day: Int) -> String {
        if (day / 10) % 10 == 1 { return "th" }
        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    private static func computeBabySummary(male: Int, female: Int, loss: Int) -> String {
        var parts: [String] = []
        if male > 0 { parts.append("\(male) boy\(male > 1 ? "s" : "")") }
        if female > 0 { parts.append("\(female) girl\(female > 1 ? "s" : "")") }
        if loss > 0 { parts.append("\(loss) loss\(loss > 1 ? "es" : "")") }
        return parts.isEmpty ? "No babies" : parts.joined(separator: " • ")
    }

    private static func computeGradientColors(male: Int, female: Int, loss: Int) -> [Color] {
        var colors = Array(repeating: Color.storkBlue, count: male)
            + Array(repeating: Color.storkPink, count: female)
            + Array(repeating: Color.storkPurple, count: loss)
        if colors.count == 1, let only = colors.first {
            colors = [only, only.opacity(0.8)]
        } else if colors.isEmpty {
            colors = [.gray.opacity(0.7), .gray.opacity(0.5)]
        }
        return colors
    }

    private static func computeAccessibilitySummary(delivery: Delivery, male: Int, female: Int, loss: Int) -> String {
        var parts: [String] = ["Delivered on \(delivery.date.formatted(date: .abbreviated, time: .shortened))"]
        if male > 0 { parts.append(String(localized: "^[\(male) boy](inflect: true)", bundle: .module)) }
        if female > 0 { parts.append(String(localized: "^[\(female) girl](inflect: true)", bundle: .module)) }
        if loss > 0 { parts.append(String(localized: "^[\(loss) loss](inflect: true)", bundle: .module)) }
        return parts.joined(separator: ", ")
    }
}
