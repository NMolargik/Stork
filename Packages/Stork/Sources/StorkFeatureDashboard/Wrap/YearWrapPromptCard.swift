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

/// The dashboard's single overflow menu: the Year Wrap (one entry per year with data) and
/// card reordering. One button instead of two keeps the toolbar down to "more" and "add".
public struct DashboardMoreMenu: View {
    private let model: DashboardModel
    @Binding private var showingReorderSheet: Bool
    @AppStorage(AppStorageKeys.excludedBirthRoles) private var excludedRoles = ""

    public init(model: DashboardModel, showingReorderSheet: Binding<Bool>) {
        self.model = model
        _showingReorderSheet = showingReorderSheet
    }

    public var body: some View {
        let years = model.wrapYears(counting: BirthRoleCounting(storedValue: excludedRoles))
        Menu {
            if years.count > 1 {
                Menu {
                    ForEach(years, id: \.self) { year in
                        Button(String(year)) { model.presentedWrapYear = year }
                    }
                } label: {
                    Label(String(localized: "Year in Births…", bundle: .module), systemImage: "sparkles")
                }
            } else if let year = years.first {
                Button { model.presentedWrapYear = year } label: {
                    Label(String(localized: "Year in Births…", bundle: .module), systemImage: "sparkles")
                }
            } else {
                Button {} label: {
                    Label(String(localized: "Year in Births…", bundle: .module), systemImage: "sparkles")
                }
                .disabled(true)
            }
            Section {
                Button { showingReorderSheet = true } label: {
                    Label(String(localized: "Reorder Cards…", bundle: .module), systemImage: "arrow.up.arrow.down")
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel(Text("More", bundle: .module))
        .hoverEffect(.highlight)
    }
}
#endif
