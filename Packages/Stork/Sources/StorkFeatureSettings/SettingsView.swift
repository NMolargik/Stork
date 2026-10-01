//
//  SettingsView.swift
//  StorkFeatureSettings
//
//  Preferences, app-icon picker, iCloud sync status, an export link (provided by the
//  caller), delete-all, and About. Generic over its export destination so Settings stays
//  decoupled from the Export feature module.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem
import StorkServices

public struct SettingsView<ExportDestination: View>: View {
    @Bindable private var model: SettingsModel
    private let exportDestination: () -> ExportDestination

    @Environment(\.scenePhase) private var scenePhase

    @State private var iconManager = IconManager()
    @State private var pendingIconColor: String?
    @State private var showDeleteAllAlert = false
    @State private var isDeleting = false

    public init(model: SettingsModel, @ViewBuilder exportDestination: @escaping () -> ExportDestination) {
        self.model = model
        self.exportDestination = exportDestination
    }

    public var body: some View {
        Form {
            PreferencesSection()
            AppIconSection(iconManager: iconManager, pendingIconColor: $pendingIconColor)
            SyncSection(model: model)
            DataSection(exportDestination: exportDestination)
            DangerZoneSection(model: model, isDeleting: isDeleting, showDeleteAllAlert: $showDeleteAllAlert)
            #if DEBUG
            DebugSection(model: model)
            #endif
            AboutSection(model: model)
            AttributionsSection()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, let color = pendingIconColor {
                pendingIconColor = nil
                Task { await iconManager.changeAppIcon(to: color) }
            }
        }
        .onAppear {
            model.load()
            model.startNetworkMonitoring()
        }
        .onDisappear { model.stopNetworkMonitoring() }
        .alert(Text("Delete All Deliveries?", bundle: .module), isPresented: $showDeleteAllAlert) {
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Delete All", bundle: .module), role: .destructive) { Task { await deleteAll() } }
        } message: {
            Text("This will permanently delete all \(model.deliveryCount) delivery records and their associated baby data. This action cannot be undone.", bundle: .module)
        }
    }

    private func deleteAll() async {
        isDeleting = true
        defer { isDeleting = false }
        model.deleteAll()
        Haptics.mediumImpact()
    }
}

// MARK: - Sections

private struct PreferencesSection: View {
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    var body: some View {
        Section {
            Toggle(isOn: $useMetricUnits) { Label(String(localized: "Metric Units", bundle: .module), systemImage: "ruler") }
                .tint(.storkPurple)
                .onChange(of: useMetricUnits) { _, _ in Haptics.lightImpact() }
            Toggle(isOn: $useDayMonthYearDates) { Label(String(localized: "Day–Month–Year Dates", bundle: .module), systemImage: "calendar") }
                .tint(.storkPurple)
                .onChange(of: useDayMonthYearDates) { _, _ in Haptics.lightImpact() }
        }
    }
}

private struct AppIconSection: View {
    var iconManager: IconManager
    @Binding var pendingIconColor: String?

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppStorageKeys.selectedIconColor) private var selectedIconColor = "purple"

    private struct IconOption: Identifiable {
        let color: String
        let asset: String
        let uiColor: Color
        var id: String { color }
    }

    private let iconOptions: [IconOption] = [
        .init(color: "purple", asset: "icon-purple-preview", uiColor: .storkPurple),
        .init(color: "blue", asset: "icon-blue-preview", uiColor: .storkBlue),
        .init(color: "pink", asset: "icon-pink-preview", uiColor: .storkPink),
        .init(color: "orange", asset: "icon-orange-preview", uiColor: .storkOrange),
    ]

    var body: some View {
        Section(String(localized: "App Icon", bundle: .module)) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(iconOptions) { option in
                        ZStack(alignment: .topTrailing) {
                            Button {
                                selectedIconColor = option.color
                                Haptics.lightImpact()
                                if scenePhase == .active {
                                    Task { await iconManager.changeAppIcon(to: option.color) }
                                } else {
                                    pendingIconColor = option.color
                                }
                            } label: {
                                Image(option.asset)
                                    .resizable().scaledToFit()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(option.uiColor, lineWidth: 3)
                                            .opacity(selectedIconColor == option.color ? 1 : 0)
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .hoverEffect(.lift)
                            .accessibilityLabel(Text("\(option.color.capitalized) app icon", bundle: .module))
                            .accessibilityAddTraits(selectedIconColor == option.color ? [.isSelected] : [])

                            if selectedIconColor == option.color {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.storkPurple)
                                    .background(.white, in: Circle())
                                    .offset(x: -4, y: 4)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollClipDisabled()
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }
}

private struct SyncSection: View {
    var model: SettingsModel

    @Environment(CloudSyncManager.self) private var cloudSyncManager
    @State private var isSyncingManually = false

    private var syncStatusColor: Color {
        switch cloudSyncManager.syncStatus {
        case .idle: .secondary
        case .syncing: .blue
        case .synced: .green
        case .error: .red
        case .offline: .orange
        }
    }

    private var canSync: Bool {
        cloudSyncManager.isCloudAvailable && !cloudSyncManager.isSyncing && !isSyncingManually && model.isOnline
    }

    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: cloudSyncManager.syncStatus.systemImage)
                    .font(.title3).foregroundStyle(syncStatusColor).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud", bundle: .module).font(.body)
                    Text(cloudSyncManager.syncStatus.displayText).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if cloudSyncManager.isSyncing || isSyncingManually {
                    ProgressView().controlSize(.small)
                } else if canSync {
                    Button {
                        Haptics.lightImpact()
                        Task { await triggerManualSync() }
                    } label: {
                        Text("Sync", bundle: .module).font(.subheadline.bold()).foregroundStyle(.storkBlue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("iCloud Sync Status", bundle: .module))
            .accessibilityValue(cloudSyncManager.syncStatus.displayText)
        } header: {
            Text("Backup & Sync", bundle: .module)
        } footer: {
            if !cloudSyncManager.isCloudAvailable {
                Text("Sign in to iCloud in Settings to enable sync.", bundle: .module)
            }
        }
    }

    private func triggerManualSync() async {
        guard canSync else { return }
        isSyncingManually = true
        defer { isSyncingManually = false }
        await cloudSyncManager.triggerSync()
        Haptics.mediumImpact()
    }
}

private struct DataSection<Destination: View>: View {
    let exportDestination: () -> Destination

    var body: some View {
        Section {
            NavigationLink { exportDestination() } label: {
                Label(String(localized: "Export & Share", bundle: .module), systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("Data", bundle: .module)
        } footer: {
            Text("Export delivery records as PDF or CSV, or share your statistics.", bundle: .module)
        }
    }
}

private struct DangerZoneSection: View {
    var model: SettingsModel
    let isDeleting: Bool
    @Binding var showDeleteAllAlert: Bool

    var body: some View {
        Section {
            Button(role: .destructive) {
                Haptics.lightImpact()
                showDeleteAllAlert = true
            } label: {
                HStack {
                    Label(isDeleting ? "Deleting…" : "Delete All Deliveries", systemImage: "trash")
                    Spacer()
                    if isDeleting { ProgressView().controlSize(.small) }
                }
                .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)
        } footer: {
            Text("This will permanently remove all \(model.deliveryCount) deliveries.", bundle: .module)
        }
    }
}

#if DEBUG
private struct DebugSection: View {
    var model: SettingsModel

    @State private var isSeeding = false
    @State private var seedingSummary: String?

    var body: some View {
        Section {
            Button {
                guard !isSeeding else { return }
                Haptics.lightImpact()
                Task {
                    isSeeding = true
                    seedingSummary = await model.seedSampleData()
                    isSeeding = false
                }
            } label: {
                HStack {
                    Label(isSeeding ? "Seeding…" : "Add Sample Data (1 Year)", systemImage: "wand.and.stars")
                        .foregroundStyle(.orange)
                    Spacer()
                    if isSeeding { ProgressView().controlSize(.small) }
                }
            }
            .buttonStyle(.plain)
            .disabled(isSeeding)

            if let seedingSummary {
                Text(seedingSummary).font(.caption).foregroundStyle(.secondary)
            }
        } header: {
            Label(String(localized: "Developer", bundle: .module), systemImage: "hammer.fill")
        }
    }
}
#endif

private struct AboutSection: View {
    var model: SettingsModel

    var body: some View {
        Section(String(localized: "About", bundle: .module)) {
            LabeledContent(String(localized: "Version", bundle: .module), value: model.appVersion)
            LabeledContent(String(localized: "Developer", bundle: .module)) {
                Link("Nick Molargik", destination: URL(string: "https://www.linkedin.com/in/nicholas-molargik/")!)
                    .foregroundStyle(.storkBlue)
            }
            LabeledContent(String(localized: "Publisher", bundle: .module)) {
                Link("Molargik Software LLC", destination: URL(string: "https://www.molargiksoftware.com")!)
                    .foregroundStyle(.storkBlue)
            }
        }
    }
}

private struct AttributionsSection: View {
    var body: some View {
        Section {
            Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                HStack {
                    Label { Text(" Weather", bundle: .module) } icon: { Image(systemName: "apple.logo") }
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
            .accessibilityLabel(Text("Apple Weather attribution", bundle: .module))
        } header: {
            Text("Attributions", bundle: .module)
        } footer: {
            Text("Weather data provided by Apple Weather.", bundle: .module)
        }
    }
}
#endif
