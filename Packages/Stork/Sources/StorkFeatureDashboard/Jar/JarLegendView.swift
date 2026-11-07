//
//  JarLegendView.swift
//  StorkFeatureDashboard
//
//  The jar legend: one chip per category with its count (tap to isolate that category in
//  the jar), notes for C-section cores and linked multiples, and a share button. The
//  remembrance chip uses gentle wording and is never added into a "delivered" total.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct JarLegendView: View {
    let marbles: [JarMarble]
    let monthDate: Date
    let isProUnlocked: Bool
    @Binding var selection: JarCategory?

    @Environment(\.requestProUpgrade) private var requestProUpgrade
    @State private var shareImage: IdentifiableImage?

    private var summary: JarSummary { JarSummary(marbles: marbles) }

    var body: some View {
        let summary = summary
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 8) {
                ForEach(JarCategory.allCases) { category in
                    if category != .remembrance || summary.remembrance > 0 || selection == .remembrance {
                        chip(category, count: summary.count(for: category))
                    }
                }
            }
            if summary.cSection > 0 || summary.multiples > 0 {
                HStack(spacing: 14) {
                    if summary.cSection > 0 {
                        Label {
                            Text("\(summary.cSection) C-section (light center)", bundle: .module)
                        } icon: {
                            Circle().fill(.white).overlay(Circle().strokeBorder(.secondary, lineWidth: 0.5)).frame(width: 8, height: 8)
                        }
                    }
                    if summary.multiples > 0 {
                        Label {
                            Text("\(summary.multiples) in multiples (linked)", bundle: .module)
                        } icon: {
                            Image(systemName: "link").font(.caption2)
                        }
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            if !marbles.isEmpty {
                Button(action: share) {
                    HStack(spacing: 6) {
                        Label(String(localized: "Share Jar", bundle: .module), systemImage: "square.and.arrow.up")
                        if !isProUnlocked { ProBadge() }
                    }
                    .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .accessibilityHint(isProUnlocked ? Text("Shares a picture of this month's jar", bundle: .module)
                                                 : Text("Free users share a lower-resolution picture. Stork Pro shares full resolution.", bundle: .module))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $shareImage) { ShareSheet(items: [$0.image]) }
    }

    @ViewBuilder
    private func chip(_ category: JarCategory, count: Int) -> some View {
        let isSelected = selection == category
        Button {
            Haptics.lightImpact()
            selection = isSelected ? nil : category
        } label: {
            HStack(spacing: 6) {
                Circle().fill(category.color).frame(width: 10, height: 10)
                Text(category.displayName).font(.footnote)
                Text("\(count)").font(.footnote.weight(.semibold)).monospacedDigit()
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(isSelected ? category.color.opacity(0.25) : Color.secondary.opacity(0.12)))
            .overlay(Capsule().strokeBorder(isSelected ? category.color : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(category.displayName), \(count)", bundle: .module))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(Text("Highlights only these marbles in the jar", bundle: .module))
    }

    @MainActor
    private func share() {
        Haptics.lightImpact()
        let renderer = ImageRenderer(
            content: JarShareCardView(marbles: marbles, monthDate: monthDate, highResolution: isProUnlocked)
                .environment(\.colorScheme, .light)
        )
        // Pro: full 3× image. Free: a lower-resolution (1×) variant — still a fine picture
        // for a message, just not poster quality. Data is never locked.
        renderer.scale = isProUnlocked ? 3.0 : 1.0
        if let image = renderer.uiImage { shareImage = IdentifiableImage(image: image) }
    }
}
#endif
