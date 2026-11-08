//
//  MainView.swift
//  StorkComposition
//
//  One adaptive `TabView` for every platform (tab bar on iPhone, switchable sidebar on
//  iPad/Mac). Builds each screen's view model from `SessionController` factories, owns the
//  add-delivery sheet, milestone celebration, deep-link routing, the bottom accessory, and
//  the Stork Pro paywall (presented from this stable root for every gated feature).
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
import StorkFeaturePro

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
    /// The gated feature the user tapped; non-nil presents the paywall.
    @State private var paywallFeature: ProFeature?

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
        .sheet(item: $milestoneShareImage) { item in
            ShareSheet(items: [item.image]) { completed in
                if completed { session.noteMilestoneCardShared() }
            }
        }
        .sheet(item: $paywallFeature) { feature in
            StorkProPaywallView(store: session.storeManager, highlighted: feature)
        }
        .sheet(isPresented: grandfatherThankYouBinding) {
            GrandfatherThankYouView { session.storeManager.markGrandfatherThankYouShown() }
        }
        .environment(\.isProUnlocked, session.storeManager.isProUnlocked)
        .environment(\.requestProUpgrade, ProUpgradeRequest { feature in paywallFeature = feature })
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
                            .toolbar { DashboardToolbar(model: dashboardModel, showingEntrySheet: $showingEntrySheet, showingReorderSheet: $showingReorderSheet) }
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
            #if canImport(HealthKit)
            .tabViewBottomAccessoryIfAvailable(isEnabled: router.selectedTab == .dashboard) {
                HStack(spacing: 12) {
                    StepCountPill(manager: session.healthManager) { showingStepTrend = true }
                    Spacer()
                }
            }
            #endif
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
        let model: DashboardModel
        @Binding var showingEntrySheet: Bool
        @Binding var showingReorderSheet: Bool

        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                DashboardMoreMenu(model: model, showingReorderSheet: $showingReorderSheet)
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .confirmationAction) {
                AddDeliveryToolbarButton(action: { showingEntrySheet = true }, showsTip: true)
            }
        }
    }

    // MARK: - Helpers

    /// Presents the one-time thank-you for pre-3.0 buyers; dismissing records it as shown.
    private var grandfatherThankYouBinding: Binding<Bool> {
        Binding(
            get: { session.storeManager.shouldShowGrandfatherThankYou && paywallFeature == nil },
            set: { if !$0 { session.storeManager.markGrandfatherThankYouShown() } }
        )
    }

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
        case .pro:
            // Locked widgets link here; the celebration overlay (if any) stays underneath.
            paywallFeature = .lockScreenWidgets
        case .dashboard, .deliveries, .weeklyDeliveries, .calendar, .settings:
            break // router.open already selected the tab
        }
    }

    /// Milestone share cards are Stork Pro: free users land on the paywall in context.
    private func shareMilestone(_ milestone: MilestoneCelebration) {
        guard session.storeManager.isProUnlocked else {
            paywallFeature = .milestoneShareCards
            return
        }
        let type: CardImageRenderer.MilestoneType = milestone.type == .babies ? .babies : .deliveries
        if let image = exportModel.manager.renderMilestoneCard(count: milestone.count, milestoneType: type) {
            milestoneShareImage = IdentifiableImage(image: image)
        }
    }
}
#endif
