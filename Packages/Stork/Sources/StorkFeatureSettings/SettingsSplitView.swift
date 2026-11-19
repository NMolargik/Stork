//
//  SettingsSplitView.swift
//  StorkFeatureSettings
//
//  Settings as a split view for wide layouts (the unfolded iPhone Duo, iPad in regular
//  width): the Settings list in a leading pane and the selected page beside it, like the
//  iPhone and iPad Settings app. The list and the pages are the same views the pushed
//  layout uses; only the rows' behavior changes (they select instead of pushing) through
//  the `settingsSelection` environment value. Folded Duo and iPhone keep push navigation.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem
import StorkServices

/// The sub-pages Settings opens. The push layout uses `roles`, `export` and `pastBirths`; the
/// wide layout lists every case as a category in the leading pane.
public enum SettingsDestination: Hashable, CaseIterable {
    case general
    case roles
    case icloud
    case export
    case pastBirths
    case privacy
    case about
    case dangerZone

    /// The page selected first on wide layouts, so the detail pane is never empty.
    public static let `default`: SettingsDestination = .general
}

private struct SettingsSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<SettingsDestination?>? = nil
}

extension EnvironmentValues {
    /// Set by `SettingsSplitView`; when present, Settings rows select a page instead of pushing it.
    var settingsSelection: Binding<SettingsDestination?>? {
        get { self[SettingsSelectionKey.self] }
        set { self[SettingsSelectionKey.self] = newValue }
    }
}

/// Pages in the wide split view's detail pane all use the large title; pushed on a phone they stay inline.
struct SettingsTitleDisplayMode: ViewModifier {
    @Environment(\.settingsSelection) private var selection
    func body(content: Content) -> some View {
        content.navigationBarTitleDisplayMode(selection != nil ? .large : .inline)
    }
}

extension View {
    func settingsTitleDisplayMode() -> some View { modifier(SettingsTitleDisplayMode()) }
}

/// A trailing disclosure chevron in the system indicator's size, weight and tertiary color.
private struct DisclosureChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

/// A Settings row that pushes its page, or selects it in the split view's detail pane.
struct SettingsRowLink<Label: View>: View {
    let destination: SettingsDestination
    let label: Label
    @Environment(\.settingsSelection) private var selection

    init(_ destination: SettingsDestination, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
    }

    var body: some View {
        if let selection {
            let isSelected = selection.wrappedValue == destination
            Button {
                Haptics.lightImpact()
                selection.wrappedValue = destination
            } label: {
                HStack(spacing: 12) {
                    label
                    DisclosureChevron()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(isSelected ? Color.accentColor.opacity(0.18) : nil)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            NavigationLink(value: destination) { label }
        }
    }
}

/// The page a `SettingsDestination` opens, used by the pushed stack and the split detail. The
/// pages are the same section views the single Form shows, so each control has one implementation.
struct SettingsDestinationView<ExportDestination: View>: View {
    let destination: SettingsDestination
    let model: SettingsModel
    let exportDestination: () -> ExportDestination

    var body: some View {
        switch destination {
        case .general:
            Form {
                PreferencesSection()
                #if DEBUG
                DebugSection(model: model)
                #endif
            }
            .navigationTitle(Text("General", bundle: .module))
            .settingsTitleDisplayMode()
        case .roles: RolesPage()
        case .icloud:
            Form { SyncSection(model: model) }
                .navigationTitle(Text("iCloud", bundle: .module))
                .settingsTitleDisplayMode()
        case .export: exportDestination()
        case .pastBirths: PastBirthsHubView(model: model)
        case .privacy:
            Form { PrivacySection() }
                .navigationTitle(Text("Privacy", bundle: .module))
                .settingsTitleDisplayMode()
        case .about:
            Form {
                AboutSection(model: model)
                AttributionsSection()
            }
            .navigationTitle(Text("About", bundle: .module))
            .settingsTitleDisplayMode()
        case .dangerZone:
            Form { DangerZoneSection(model: model) }
                .navigationTitle(Text("Danger Zone", bundle: .module))
                .settingsTitleDisplayMode()
        }
    }
}

/// Which roles count toward the headline total, shown as "counted/all".
enum RolesSummary {
    static func text(for storedValue: String) -> String {
        let counting = BirthRoleCounting(storedValue: storedValue)
        let counted = BirthRole.allCases.filter { counting.counts($0) }.count
        return "\(counted)/\(BirthRole.allCases.count)"
    }
}

/// The leading pane on wide layouts: the Pro card, then one row per category (symbol, title and
/// an optional short value). Nothing else; the controls are on the selected page.
struct SettingsCategoryList: View {
    var model: SettingsModel
    @Environment(CloudSyncManager.self) private var cloudSyncManager
    @AppStorage(AppStorageKeys.excludedBirthRoles) private var excludedRoles = ""

    var body: some View {
        List {
            ProSection(model: model)
            Section {
                row(.general, String(localized: "General", bundle: .module), "gearshape")
                row(.roles, String(localized: "Roles Counted in Totals", bundle: .module), "person.2", value: RolesSummary.text(for: excludedRoles))
            }
            Section {
                row(.icloud, String(localized: "iCloud", bundle: .module), cloudSyncManager.syncStatus.systemImage, value: cloudSyncManager.syncStatus.displayText)
            }
            Section {
                row(.export, String(localized: "Export & Share", bundle: .module), "square.and.arrow.up")
                row(.pastBirths, String(localized: "Past Births & Import", bundle: .module), "tray.and.arrow.down")
            }
            Section {
                row(.privacy, String(localized: "Privacy", bundle: .module), "lock.shield")
                row(.about, String(localized: "About", bundle: .module), "info.circle")
            }
            Section {
                row(.dangerZone, String(localized: "Danger Zone", bundle: .module), "trash", tint: .red)
            }
        }
    }

    private func row(_ destination: SettingsDestination, _ title: String, _ symbol: String, value: String? = nil, tint: Color? = nil) -> some View {
        SettingsRowLink(destination) {
            LabeledContent {
                if let value { Text(value).foregroundStyle(.secondary).lineLimit(1) }
            } label: {
                Label(title, systemImage: symbol).foregroundStyle(tint ?? .primary)
            }
        }
    }
}

/// Which roles count toward the headline total. Nine toggles used to sit inline and push
/// Data and Privacy off screen, so they live one tap away.
struct RolesPage: View {
    @AppStorage(AppStorageKeys.excludedBirthRoles) private var excludedRoles = ""

    var body: some View {
        Form {
            Section {
                ForEach(BirthRole.allCases) { role in
                    Toggle(isOn: binding(for: role)) { Label(role.displayName, systemImage: role.systemImage) }
                        .tint(.storkPurple)
                }
            } footer: {
                Text("Choose which roles count toward your headline birth total. Deliveries with no role recorded always count. Every delivery stays in your history either way.", bundle: .module)
            }
        }
        .navigationTitle(Text("Roles Counted in Totals", bundle: .module))
        .settingsTitleDisplayMode()
    }

    private func binding(for role: BirthRole) -> Binding<Bool> {
        Binding(
            get: { BirthRoleCounting(storedValue: excludedRoles).counts(role) },
            set: { counted in
                var counting = BirthRoleCounting(storedValue: excludedRoles)
                counting.set(role, counted: counted)
                excludedRoles = counting.storedValue
                Haptics.lightImpact()
            }
        )
    }
}

public struct SettingsSplitView<ExportDestination: View>: View {
    private let model: SettingsModel
    private let exportDestination: () -> ExportDestination
    @Binding private var selection: SettingsDestination?
    @State private var layout = LayoutProbe()

    public init(model: SettingsModel, selection: Binding<SettingsDestination?>, @ViewBuilder exportDestination: @escaping () -> ExportDestination) {
        self.model = model
        _selection = selection
        self.exportDestination = exportDestination
    }

    /// On the open Duo: two equal columns around the hinge, the list on the left half and the
    /// selected page on the right half. Elsewhere (iPad): a list column of a comfortable width
    /// and a hairline between the panes.
    public var body: some View {
        GeometryReader { proxy in
        // The same two equal columns (and gap) as every other split screen, on the open Duo
        // and on iPad alike.
        let fold = proxy.foldCenterXIfAvailable
        let hasFold = fold != nil
        let columns = SplitColumns<EmptyView, EmptyView>.columnWidths(total: proxy.size.width, foldCenterX: fold)
        let gap = columns.gap
        let leading = columns.leading
        FoldSplitLayout(leadingWidth: leading, separatorWidth: gap) {
            NavigationStack {
                SettingsView(model: model, exportDestination: exportDestination)
                    // The Duo's vertical bar sits at the far edge of the screen, but the system
                    // still insets the list for it, which would leave this pane well short of
                    // the hinge; ignore that inset.
                    .ignoresSafeArea(.container, edges: PhoneDuo.isDuo ? .trailing : [])
                    .navigationTitle(Text(AppTab.settings.localizedTitle))
                    .statusSubtitle()
                    .environment(\.settingsSelection, $selection)
            }
            Rectangle()
                .fill(hasFold ? AnyShapeStyle(.clear) : AnyShapeStyle(.separator))
                .ignoresSafeArea()
            NavigationStack {
                SettingsDestinationView(destination: selection ?? .default, model: model, exportDestination: exportDestination)
                    .id(selection)
                    .environment(\.settingsSelection, $selection)
            }
        }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .containerLayoutProbe { layout = $0 }
        .onAppear {
            if selection == nil { selection = .default }
            #if DEBUG
            // Simulator verification: `-StorkSettingsPush export|roles|pastbirths|privacy` selects that page.
            switch DebugLaunchOptions.settingsPush {
            case "export": selection = .export
            case "roles": selection = .roles
            case "pastbirths": selection = .pastBirths
            case "privacy": selection = .privacy
            default: break
            }
            #endif
        }
    }
}
#endif
