//
//  YearWrapPromptCard.swift
//  StorkFeatureDashboard
//
//  The seasonal dashboard invitation (December 1 through January 31) to view the Wrap for
//  the year just ending, plus the toolbar menu that opens the Wrap for any year with data.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct YearWrapPromptCard: View {
    let year: Int
    let onOpen: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 30))
                .foregroundStyle(LinearGradient(colors: [.storkPink, .storkPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Your Year in Births", bundle: .module).font(.headline)
                Text("Your \(String(year)) Wrap is ready", bundle: .module)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button {
                Haptics.lightImpact()
                onOpen()
            } label: {
                Text("View Wrap", bundle: .module).font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.storkBlue)
            .buttonBorderShape(.capsule)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [Color.storkPink.opacity(0.22), Color.storkPurple.opacity(0.12), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.storkPink.opacity(0.35)))
        .overlay(alignment: .topTrailing) {
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.tertiary).padding(6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Dismiss", bundle: .module))
            .offset(x: 6, y: -6)
        }
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .contain)
    }
}

/// Toolbar menu: open the Wrap for any year with data.
public struct YearWrapMenu: View {
    private let model: DashboardModel
    @AppStorage(AppStorageKeys.excludedBirthRoles) private var excludedRoles = ""

    public init(model: DashboardModel) { self.model = model }

    public var body: some View {
        let years = model.wrapYears(counting: BirthRoleCounting(storedValue: excludedRoles))
        Menu {
            if years.isEmpty {
                Text("Your Wrap appears once you log a birth", bundle: .module)
            } else {
                ForEach(years, id: \.self) { year in
                    Button {
                        model.presentedWrapYear = year
                    } label: {
                        Label(String(year), systemImage: "sparkles")
                    }
                }
            }
        } label: {
            Image(systemName: "sparkles")
        }
        .accessibilityLabel(Text("Your Year in Births", bundle: .module))
        .hoverEffect(.highlight)
    }
}
#endif
