//
//  DeliveryRowView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 10/27/25.
//

import Foundation
import SwiftUI

extension DeliveryRowView {
    @Observable
    class ViewModel {
        private let delivery: Delivery
        
        var maleCount: Int
        var femaleCount: Int
        var lossCount: Int
        var totalBabies: Int
        var showsNICUIcon: Bool
        var showsEpiduralIcon: Bool
        var showsCSectionIcon: Bool
        var babySummary: String
        var gradientColors: [Color]
        var accessibilitySummary: String

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
                DotSegment(color: Color("storkBlue"),   count: maleCount),
                DotSegment(color: Color("storkPink"),   count: femaleCount),
                DotSegment(color: Color("storkPurple"), count: lossCount)
            ].filter { $0.count > 0 }
        }
        
        init(delivery: Delivery) {
            self.delivery = delivery
            let babies = delivery.babies ?? []
            
            // Compute locally first to avoid using self before initialization
            let localMaleCount = babies.filter { $0.sex == .male }.count
            let localFemaleCount = babies.filter { $0.sex == .female }.count
            let localLossCount = babies.filter { $0.sex == .loss }.count
            let localTotal = localMaleCount + localFemaleCount + localLossCount
            let localShowsNICU = babies.contains { $0.nicuStay == true }
            let localShowsEpidural = delivery.epiduralUsed
            let localShowsCSection = delivery.deliveryMethod == .cSection
            let localBabySummary = Self.computeBabySummary(babies: babies)
            let localGradientColors = Self.computeGradientColors(babies: babies)
            let localAccessibility = Self.computeAccessibilitySummary(
                delivery: delivery,
                maleCount: localMaleCount,
                femaleCount: localFemaleCount,
                lossCount: localLossCount
            )
            
            // Now assign to stored properties
            self.maleCount = localMaleCount
            self.femaleCount = localFemaleCount
            self.lossCount = localLossCount
            self.totalBabies = localTotal
            self.showsNICUIcon = localShowsNICU
            self.showsEpiduralIcon = localShowsEpidural
            self.showsCSectionIcon = localShowsCSection
            self.babySummary = localBabySummary
            self.gradientColors = localGradientColors
            self.accessibilitySummary = localAccessibility
        }
        
        var hasSecondary: Bool {
            totalBabies > 0
        }
        
        func primaryTitle(useDayMonthYear: Bool) -> String {
            let date = delivery.date
            
            let timeFormatter = DateFormatter()
            timeFormatter.locale = .current
            timeFormatter.timeStyle = .short
            timeFormatter.dateStyle = .none
            let time = timeFormatter.string(from: date)
            
            let day = Calendar.current.component(.day, from: date)
            let suffix: String
            let ones = day % 10
            let tens = (day / 10) % 10
            if tens == 1 {
                suffix = "th"
            } else {
                switch ones {
                case 1: suffix = "st"
                case 2: suffix = "nd"
                case 3: suffix = "rd"
                default: suffix = "th"
                }
            }
            
            let monthFormatter = DateFormatter()
            monthFormatter.locale = .current
            monthFormatter.setLocalizedDateFormatFromTemplate("MMMM")
            let month = monthFormatter.string(from: date)
            
            if useDayMonthYear {
                return "\(day)\(suffix) \(month) @ \(time)"
            } else {
                return "\(month) \(day)\(suffix) @ \(time)"
            }
        }
        
        func animatedColor(time: TimeInterval, secondsPerStep: Double) -> Color {
            guard gradientColors.count >= 2 else { return gradientColors.first ?? .gray }
            let t = time / secondsPerStep
            let phase = t - floor(t)
            let idx = Int(floor(t)) % gradientColors.count
            let nextIdx = (idx + 1) % gradientColors.count
            return interpolate(gradientColors[idx], gradientColors[nextIdx], phase: phase)
        }
        
        private func interpolate(_ a: Color, _ b: Color, phase: Double) -> Color {
            #if canImport(UIKit)
            var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
            var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
            UIColor(a).getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
            UIColor(b).getRed(&br, green: &bg, blue: &bb, alpha: &ba)
            let p = max(0, min(1, phase))
            let r = ar + (br - ar) * p
            let g = ag + (bg - ag) * p
            let bl = ab + (bb - ab) * p
            let al = aa + (ba - aa) * p
            return Color(red: Double(r), green: Double(g), blue: Double(bl), opacity: Double(al))
            #else
            return a
            #endif
        }
        
        private static func computeBabySummary(babies: [Baby]) -> String {
            let maleCount = babies.filter { $0.sex == .male }.count
            let femaleCount = babies.filter { $0.sex == .female }.count
            let lossCount = babies.filter { $0.sex == .loss }.count
            
            var summaryComponents = [String]()
            if maleCount > 0 {
                summaryComponents.append("\(maleCount) boy\(maleCount > 1 ? "s" : "")")
            }
            if femaleCount > 0 {
                summaryComponents.append("\(femaleCount) girl\(femaleCount > 1 ? "s" : "")")
            }
            if lossCount > 0 {
                summaryComponents.append("\(lossCount) loss\(lossCount > 1 ? "es" : "")")
            }
            
            return summaryComponents.isEmpty ? "No babies" : summaryComponents.joined(separator: " • ")
        }
        
        private static func computeGradientColors(babies: [Baby]) -> [Color] {
            let maleCount = babies.filter { $0.sex == .male }.count
            let femaleCount = babies.filter { $0.sex == .female }.count
            let lossCount = babies.filter { $0.sex == .loss }.count
            
            var colors = Array(repeating: Color("storkBlue"), count: maleCount) +
                         Array(repeating: Color("storkPink"), count: femaleCount) +
                         Array(repeating: Color("storkPurple"), count: lossCount)
            
            if colors.count == 1, let onlyColor = colors.first {
                colors = [onlyColor, onlyColor.opacity(0.8)]
            } else if colors.isEmpty {
                colors = [Color.gray.opacity(0.7), Color.gray.opacity(0.5)]
            }
            
            return colors
        }
        
        private static func computeAccessibilitySummary(delivery: Delivery, maleCount: Int, femaleCount: Int, lossCount: Int) -> String {
            var parts: [String] = []
            parts.append("Delivered on \(delivery.date.formatted(date: .abbreviated, time: .shortened))")
            if maleCount + femaleCount + lossCount > 0 {
                if maleCount > 0 { parts.append("\(maleCount) boy\(maleCount == 1 ? "" : "s")") }
                if femaleCount > 0 { parts.append("\(femaleCount) girl\(femaleCount == 1 ? "" : "s")") }
                if lossCount > 0 { parts.append("\(lossCount) loss\(lossCount == 1 ? "" : "es")") }
            }
            return parts.joined(separator: ", ")
        }
    }
}
