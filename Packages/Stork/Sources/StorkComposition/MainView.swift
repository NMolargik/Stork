//
//  MainView.swift
//  StorkComposition
//
//  One adaptive `TabView` for every platform (tab bar on iPhone, switchable sidebar on
//  iPad/Mac). Builds each screen's view model from `SessionController` factories, owns the
//  add-delivery sheet, milestone celebration, deep-link routing, and the bottom accessory.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem
import StorkServices
import StorkFeatureDeliveries
import StorkFeatureDashboard
import StorkFeatureSettings
import StorkFeatureExport

public struct MainView: View {
    private let session: SessionController
    @Environment(AppRouter.self) private var router

    @State private var listModel: DeliveryListModel
    @State private var dashboardModel: DashboardModel
    @State private var calendarModel: CalendarModel
    @State private var settingsModel: SettingsModel
    @State private var exportModel: ExportModel

    @State private var showingEntrySheet = false
    @State private var showingReorderSheet = false
    @State private var showingStepTrend = false
    @State private var listPath = NavigationPath()
    @State private var pendingCelebration: MilestoneCelebration?
    @State private var milestoneShareImage: IdentifiableImage?

    public init(session: SessionController) {
        self.session = session
        _listModel = State(initialValue: session.makeDeliveryListModel())
        _dashboardModel = State(initialValue: session.makeDashboardModel())
        _calendarModel = State(initialValue: session.makeCalendarModel())
        _settingsModel = State(initialValue: session.makeSettingsModel())
        _exportModel = State(initialValue: session.makeExportModel())
    }

    public var body: some View {
        ZStack {
            AdaptiveTabs(
                session: session,
                router: router,
                listModel: listModel,
                dashboardModel: dashboardModel,
                calendarModel: calendarModel,
                settingsModel: settingsModel,
                exportModel: exportModel,
                showingEntrySheet: $showingEntrySheet,
                showingReorderSheet: $showingReorderSheet,
                showingStepTrend: $showingStepTrend,
                listPath: $listPath,
                onReloadAll: reloadAll
            )

            if let celebration = pendingCelebration {
                MilestoneCelebrationView(milestone: celebration,
                                         onDismiss: { pendingCelebration = nil },
                                         onShare: { shareMilestone(celebration) })
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .sheet(item: $milestoneShareImage) { ShareSheet(items: [$0.image]) }
        .sheet(isPresented: $showingEntrySheet) {
            DeliveryEntryView(model: session.makeDeliveryEntryModel()) { celebration in
                reloadAll()
                router.select(.dashboard)
                if let celebration { pendingCelebration = celebration }
            }
            .interactiveDismissDisabled()
            .presentationDetents([.large])
        }
        #if canImport(HealthKit)
        .sheet(isPresented: $showingStepTrend) {
            StepTrendSheet(manager: session.healthManager).presentationDetents([.medium])
        }
        .task {
            guard session.healthManager.isStepTrackingSupported else { return }
            await session.healthManager.requestAuthorization()
            if session.healthManager.isAuthorized { session.healthManager.startObservingStepCount() }
        }
        #endif
        .onChange(of: router.pendingDeepLink) { _, link in handleDeepLink(link) }
        .task {
            // One signal for every store change — local saves, Siri logs, Settings
            // delete-all, and CloudKit imports. Cancelled automatically on disappear.
            for await _ in session.observeDeliveryChanges() {
                reloadAll()
            }
        }
        .onAppear {
            reloadAll()
            handleDeepLink(router.pendingDeepLink)
        }
        .environment(session.cloudSyncManager)
    }

    // MARK: - Tabs

    private struct AdaptiveTabs: View {
        var session: SessionController
        @Bindable var router: AppRouter
        var listModel: DeliveryListModel
        var dashboardModel: DashboardModel
        var calendarModel: CalendarModel
        var settingsModel: SettingsModel
        var exportModel: ExportModel
        @Binding var showingEntrySheet: Bool
        @Binding var showingReorderSheet: Bool
        @Binding var showingStepTrend: Bool
        @Binding var listPath: NavigationPath
        let onReloadAll: () -> Void

        var body: some View {
            TabView(selection: $router.selectedTab) {
                Tab(String(localized: AppTab.dashboard.localizedTitle), systemImage: AppTab.dashboard.systemImage, value: .dashboard) {
                    NavigationStack {
                        DashboardView(model: dashboardModel, showingReorderSheet: $showingReorderSheet)
                            .minimizeToolbarOnScrollIfAvailable()
                            .navigationTitle(Text("Stork", bundle: .module))
                            .toolbar { DashboardToolbar(showingEntrySheet: $showingEntrySheet, showingReorderSheet: $showingReorderSheet) }
                    }
                }
                Tab(String(localized: AppTab.list.localizedTitle), systemImage: AppTab.list.systemImage, value: .list) {
                    NavigationStack(path: $listPath) {
                        DeliveryListView(model: listModel, showingEntrySheet: $showingEntrySheet)
                            .navigationTitle(Text(AppTab.list.localizedTitle))
                            .navigationDestination(for: Delivery.self) { deliveryDetail($0) }
                            .toolbar { ToolbarItem(placement: .confirmationAction) { AddDeliveryToolbarButton { showingEntrySheet = true } } }
                    }
                }
                Tab(String(localized: AppTab.calendar.localizedTitle), systemImage: AppTab.calendar.systemImage, value: .calendar) {
                    NavigationStack {
                        DeliveryCalendarView(model: calendarModel)
                            .navigationTitle(Text(AppTab.calendar.localizedTitle))
                            .navigationDestination(for: Delivery.self) { deliveryDetail($0) }
                            .toolbar { ToolbarItem(placement: .confirmationAction) { AddDeliveryToolbarButton { showingEntrySheet = true } } }
                    }
                }
                Tab(String(localized: AppTab.settings.localizedTitle), systemImage: AppTab.settings.systemImage, value: .settings) {
                    NavigationStack {
                        SettingsView(model: settingsModel) { ExportView(model: exportModel) }
                            .navigationTitle(Text(AppTab.settings.localizedTitle))
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .tabViewBottomAccessoryIfAvailable {
                HStack(spacing: 12) {
                    #if canImport(HealthKit)
                    StepCountPill(manager: session.healthManager) { showingStepTrend = true }
                    #endif
                    Spacer()
                    WeatherPill(manager: session.weatherManager)
                }
            }
        }

        private func deliveryDetail(_ delivery: Delivery) -> DeliveryDetailView {
            DeliveryDetailView(
                delivery: delivery,
                onDelete: { listModel.delete(delivery); onReloadAll() },
                makeEditModel: { session.makeDeliveryEntryModel(existing: delivery) },
                onEdited: { onReloadAll() }
            )
        }
    }

    private struct DashboardToolbar: ToolbarContent {
        @Binding var showingEntrySheet: Bool
        @Binding var showingReorderSheet: Bool

        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingReorderSheet = true } label: { Image(systemName: "arrow.up.arrow.down") }
                    .accessibilityLabel(Text("Reorder cards", bundle: .module))
                    .keyboardShortcut("r", modifiers: .command)
                    .hoverEffect(.highlight)
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .confirmationAction) {
                AddDeliveryToolbarButton(action: { showingEntrySheet = true }, showsTip: true)
            }
        }
    }

    // MARK: - Helpers

    private func reloadAll() {
        listModel.load()
        dashboardModel.load()
        calendarModel.load()
        settingsModel.load()
        exportModel.load()
    }

    private func handleDeepLink(_ link: DeepLink?) {
        guard let link else { return }
        defer { router.pendingDeepLink = nil }
        switch link {
        case .newDelivery:
            showingEntrySheet = true
        case .delivery(let id):
            if let match = listModel.deliveries.first(where: { $0.id == id }) {
                router.select(.list)
                listPath.append(match)
            }
        case .dashboard, .deliveries, .weeklyDeliveries, .calendar, .settings:
            break // router.open already selected the tab
        }
    }

    private func shareMilestone(_ milestone: MilestoneCelebration) {
        let type: CardImageRenderer.MilestoneType = milestone.type == .babies ? .babies : .deliveries
        if let image = exportModel.manager.renderMilestoneCard(count: milestone.count, milestoneType: type) {
            milestoneShareImage = IdentifiableImage(image: image)
        }
    }
}

// MARK: - Helper types

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
