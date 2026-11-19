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
    @Environment(StatusCenter.self) private var status

    @State private var listModel: DeliveryListModel
    @State private var dashboardModel: DashboardModel
    @State private var calendarModel: CalendarModel
    @State private var settingsModel: SettingsModel
    @State private var exportModel: ExportModel

    @State private var showingEntrySheet = false
    @State private var showingReorderSheet = false
    @State private var showingStepTrend = false
    @State private var listPath = NavigationPath()
    /// Whether the delivery list is showing its side-by-side layout (reported by the list).
    @State private var listIsSplit = false
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
                listIsSplit: $listIsSplit,
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
            // Shared straight from the celebration that follows a log: never a review moment.
            ShareSheet(items: [item.image])
        }
        .sheet(item: $paywallFeature) { feature in
            StorkProPaywallView(store: session.storeManager, highlighted: feature)
        }
        .sheet(isPresented: grandfatherThankYouBinding) {
            GrandfatherThankYouView { session.storeManager.markGrandfatherThankYouShown() }
        }
        .environment(\.isProUnlocked, session.storeManager.isProUnlocked)
        .environment(\.noteReviewMoment, ReviewMomentNotifier { session.noteReviewMoment($0) })
        .environment(\.requestProUpgrade, ProUpgradeRequest { feature in paywallFeature = feature })
        .sheet(isPresented: $showingEntrySheet) {
            DeliveryEntryView(model: session.makeDeliveryEntryModel()) { celebration in
                reloadAll()
                router.select(.dashboard)
                status.show(String(localized: "Delivery saved", bundle: .module))
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
            // Never the first Health prompt: that comes from onboarding or "Connect Health".
            guard session.healthManager.isStepTrackingSupported else { return }
            await session.healthManager.resumeIfPreviouslyRequested()
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
            AlternateIconReset.runOnce()
            reloadAll()
            handleDeepLink(router.pendingDeepLink)
            #if DEBUG
            if let host = DebugLaunchOptions.openLink, let url = URL(string: "stork://\(host)"), let link = DeepLink(url: url) {
                router.open(link)
            }
            switch DebugLaunchOptions.openSheet {
            case "reorder": router.select(.dashboard); showingReorderSheet = true
            case "trend": router.select(.dashboard); showingStepTrend = true
            case "firstDelivery":
                if let first = listModel.deliveries.first { router.select(.list); listModel.selectedDeliveryID = first.id; if !listIsSplit { listPath.append(first) } }
            default: break
            }
            #endif
        }
        .onChange(of: listIsSplit) { _, split in
            // A delivery pushed before the list knew it was wide would cover the split view.
            if split, !listPath.isEmpty { listPath = NavigationPath() }
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
        @Binding var listIsSplit: Bool
        let onReloadAll: () -> Void

        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        /// The page shown in the wide Settings split view.
        @State private var settingsSelection: SettingsDestination? = .default

        /// Wide layouts (the unfolded iPhone Duo, iPad in regular width) show Settings as a
        /// list beside the selected page. The folded Duo and iPhone are compact and push.
        private var usesSettingsSplitView: Bool { horizontalSizeClass == .regular }

        /// The system bottom accessory spans the window and would run under the Duo's hinge,
        /// and the Duo's tab bar is a vertical strip, so on the Duo the step pill is a strip
        /// kept inside the leading pane instead.
        private var showsStepPill: Bool {
            #if DEBUG
            if DebugLaunchOptions.hideHealthPill { return false }
            #endif
            return router.selectedTab == .dashboard
        }

        var body: some View {
            TabView(selection: $router.selectedTab) {
                Tab(String(localized: AppTab.dashboard.localizedTitle), systemImage: AppTab.dashboard.systemImage, value: .dashboard) {
                    NavigationStack {
                        DashboardView(model: dashboardModel, showingReorderSheet: $showingReorderSheet)
                            .minimizeToolbarOnScrollIfAvailable()
                            .navigationTitle(Text("Stork", bundle: .module))
                            .statusSubtitle()
                            .toolbar { DashboardToolbar(model: dashboardModel, showingEntrySheet: $showingEntrySheet, showingReorderSheet: $showingReorderSheet) }
                    }
                    .duoStripClearance(isEnabled: showsStepPill)
                    #if canImport(HealthKit)
                    .environment(\.bottomAccessoryClearance, showsStepPill && session.healthManager.isStepTrackingSupported ? (PhoneDuo.isDuo ? 56 : 84) : 0)
                    #endif
                }
                Tab(String(localized: AppTab.list.localizedTitle), systemImage: AppTab.list.systemImage, value: .list) {
                    NavigationStack(path: $listPath) {
                        DeliveryListView(model: listModel, showingEntrySheet: $showingEntrySheet, isShowingSplit: $listIsSplit, detail: { deliveryDetail($0, isEmbedded: true) })
                            .navigationTitle(Text(AppTab.list.localizedTitle))
                            .statusSubtitle()
                            .navigationDestination(for: Delivery.self) { deliveryDetail($0) }
                            .toolbar { ToolbarItem(placement: .confirmationAction) { AddDeliveryToolbarButton { showingEntrySheet = true } } }
                    }
                }
                Tab(String(localized: AppTab.calendar.localizedTitle), systemImage: AppTab.calendar.systemImage, value: .calendar) {
                    NavigationStack {
                        DeliveryCalendarView(model: calendarModel)
                            .navigationTitle(Text(AppTab.calendar.localizedTitle))
                            .statusSubtitle()
                            .navigationDestination(for: Delivery.self) { deliveryDetail($0) }
                            .toolbar { ToolbarItem(placement: .confirmationAction) { AddDeliveryToolbarButton { showingEntrySheet = true } } }
                    }
                }
                Tab(String(localized: AppTab.settings.localizedTitle), systemImage: AppTab.settings.systemImage, value: .settings) {
                    if usesSettingsSplitView {
                        SettingsSplitView(model: settingsModel, selection: $settingsSelection) { ExportView(model: exportModel) }
                    } else {
                        NavigationStack {
                            SettingsView(model: settingsModel) { ExportView(model: exportModel) }
                                .navigationTitle(Text(AppTab.settings.localizedTitle))
                                .statusSubtitle()
                        }
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            #if canImport(HealthKit)
            .tabViewBottomAccessoryIfAvailable(isEnabled: showsStepPill && !PhoneDuo.isDuo) {
                HStack(spacing: 12) {
                    StepCountPill(manager: session.healthManager) { showingStepTrend = true }
                    Spacer()
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if PhoneDuo.isDuo, showsStepPill, #available(iOS 26.0, *) {
                    DuoStepStrip(manager: session.healthManager) { showingStepTrend = true }
                }
            }
            #endif
        }

        @Environment(StatusCenter.self) private var status

        private func deliveryDetail(_ delivery: Delivery, isEmbedded: Bool = false) -> DeliveryDetailView {
            DeliveryDetailView(
                delivery: delivery,
                onDelete: { listModel.delete(delivery); onReloadAll() },
                makeEditModel: { session.makeDeliveryEntryModel(existing: delivery) },
                onEdited: { onReloadAll(); status.show(String(localized: "Delivery updated", bundle: .module)) },
                isEmbedded: isEmbedded
            )
        }
    }

    #if canImport(HealthKit)
    /// The step pill on the iPhone Duo, as an ordinary bottom inset (which already stops short
    /// of the tab strip). Open, it stays inside the leading pane so nothing sits on the hinge.
    @available(iOS 26.0, *)
    private struct DuoStepStrip: View {
        let manager: HealthManager
        let onShowTrend: () -> Void
        @State private var layout = LayoutProbe()

        var body: some View {
            Color.clear
                .frame(height: 52)
                .overlay {
                    if manager.isStepTrackingSupported {
                        let pill = StepCountPill(manager: manager, onShowTrend: onShowTrend)
                        if let fold = layout.foldCenterX {
                            pill
                                .frame(width: min(max(0, fold - 48), 360))
                                .glassEffect(.regular.interactive(), in: Capsule())
                                .frame(width: fold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            pill
                                .glassEffect(.regular.interactive(), in: Capsule())
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .containerLayoutProbe { layout = $0 }
        }
    }
    #endif

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
                listModel.selectedDeliveryID = match.id
                // Wide layouts show it in the split view's detail pane; compact ones push.
                if !listIsSplit { listPath.append(match) }
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

#if canImport(HealthKit)
private extension View {
    /// Keeps the Duo's step strip from covering the end of the page: the strip floats over
    /// the content, and the system does not inset tab content for it.
    @ViewBuilder
    func duoStripClearance(isEnabled: Bool) -> some View {
        if PhoneDuo.isDuo, isEnabled {
            safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 60) }
        } else {
            self
        }
    }
}
#else
private extension View {
    func duoStripClearance(isEnabled: Bool) -> some View { self }
}
#endif
#endif
