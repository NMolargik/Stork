//
//  JarShareCardView.swift
//  StorkFeatureDashboard
//
//  A static, shareable picture of a month's jar: colored marbles (twins joined by a
//  string, C-section marbles with a light core), the legend with counts, and a month label.
//  Aggregate only — no names, no notes, no dates finer than the month.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct JarShareCardView: View {
    let marbles: [JarMarble]
    let monthDate: Date
    /// Pro renders at full resolution; the free variant adds a small "Stork" caption.
    let highResolution: Bool

    private let cardWidth: CGFloat = 340
    private let diameter: CGFloat = 24

    private var summary: JarSummary { JarSummary(marbles: marbles) }

    private var monthTitle: String {
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return df.string(from: monthDate)
    }

    var body: some View {
        let summary = summary
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "circle.hexagongrid.fill").font(.title2).foregroundStyle(Color.storkBlue)
                Text(monthTitle).font(.headline).fontWeight(.semibold)
                Spacer()
            }

            jar

            VStack(alignment: .leading, spacing: 6) {
                ForEach(JarCategory.allCases.filter { $0 != .remembrance }) { category in
                    legendRow(category, count: summary.count(for: category))
                }
                if summary.remembrance > 0 {
                    legendRow(.remembrance, count: summary.remembrance)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                // Remembrance is deliberately outside this number.
                Text("Babies delivered: \(summary.delivered)", bundle: .module).font(.subheadline.weight(.semibold))
                Spacer()
                Image("storkicon").resizable().scaledToFit().frame(width: 20, height: 20)
            }
        }
        .padding(20)
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color.storkBlue.opacity(0.15), Color.storkBlue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(uiColor: .systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 1))
    }

    private func legendRow(_ category: JarCategory, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle().fill(category.color).frame(width: 10, height: 10)
            Text(category.displayName).font(.caption)
            Spacer()
            Text(verbatim: "\(count)").font(.caption.weight(.semibold)).monospacedDigit()
        }
    }

    // MARK: - Jar

    private var ordered: [JarMarble] {
        // Siblings adjacent, then grouped by category for a tidy pile.
        marbles.sorted {
            let l = ($0.linkID?.uuidString ?? "~"), r = ($1.linkID?.uuidString ?? "~")
            if l != r { return l < r }
            return $0.category.rawValue < $1.category.rawValue
        }
    }

    private var jar: some View {
        let inner = cardWidth - 40 - 24
        let cols = max(1, Int(inner / diameter))
        let items = ordered
        let rows = max(1, (items.count + cols - 1) / cols)
        let height = max(120, CGFloat(rows) * diameter * 0.9 + 24)
        func point(_ i: Int) -> CGPoint {
            let row = i / cols, col = i % cols
            let shift = row % 2 == 0 ? 0 : diameter / 2
            return CGPoint(x: 12 + diameter / 2 + CGFloat(col) * diameter + shift,
                           y: height - 12 - diameter / 2 - CGFloat(row) * diameter * 0.9)
        }
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1))
            // Twin strings first, under the marbles.
            ForEach(Array(items.enumerated()), id: \.offset) { i, marble in
                if i > 0, let link = marble.linkID, items[i - 1].linkID == link {
                    Path { p in p.move(to: point(i - 1)); p.addLine(to: point(i)) }
                        .stroke(Color.primary.opacity(0.6), lineWidth: 2)
                }
            }
            ForEach(Array(items.enumerated()), id: \.offset) { i, marble in
                let c = point(i)
                Circle()
                    .fill(marble.category.color.opacity(0.85))
                    .overlay {
                        if marble.isCSection { Circle().fill(.white.opacity(0.9)).frame(width: diameter * 0.34, height: diameter * 0.34) }
                    }
                    .frame(width: diameter - 2, height: diameter - 2)
                    .position(c)
            }
        }
        .frame(width: cardWidth - 40, height: height)
    }
}
#endif
