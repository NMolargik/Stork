//
//  MainView.swift
//  Stork
//

import SwiftUI
import SwiftData
import UIKit

struct MainView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @Environment(DeliveryManager.self) private var deliveryManager
    @Environment(ExportManager.self) private var exportManager
    #if !os(visionOS)
    @Environment(HealthManager.self) private var healthManager
    #endif

    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false
    @AppStorage(AppStorageKeys.hasSeenHospitalRemovalNotice) private var hasSeenHospitalRemovalNotice: Bool = false

    @Binding var pendingDeepLink: DeepLink?

    @State private var viewModel = ViewModel()
    @State private var showHospitalRemovalAlert: Bool = false
    @State private var milestoneShareImage: IdentifiableImage?

    var body: some View {
        ZStack {
            Group {
                if isRegularWidth {
                    regularWidthView
                } else {
                    compactWidthView
                }
            }
            .onAppear {
                // One-time notice for users who had data before hospital
                // tracking was removed for HIPAA reasons.
                if isOnboardingComplete && !hasSeenHospitalRemovalNotice {
                    showHospitalRemovalAlert = true
                }
            }
            .alert("Hospitals Removed", isPresented: $showHospitalRemovalAlert) {
                Button("Got It", role: .cancel) {
                    hasSeenHospitalRemovalNotice = true
                }
            } message: {
                Text("To better protect your privacy, Stork no longer stores hospital information. Correlating delivery dates with specific facilities posed a small but real re-identification risk under HIPAA. Your delivery records remain intact—only the hospital field has been removed.")
            }

            if let milestone = deliveryManager.pendingMilestoneCelebration {
                MilestoneCelebrationView(
                    milestone: milestone,
                    onDismiss: {
                        deliveryManager.dismissMilestoneCelebration()
                    },
                    onShare: {
                        shareMilestone(milestone)
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .sheet(item: $milestoneShareImage) { imageWrapper in
            ShareSheet(items: [imageWrapper.image])
        }
        .sheet(isPresented: $viewModel.showingEntrySheet) {
            DeliveryEntryView(
                onDeliverySaved: { delivery, reviewScene in
                    viewModel.appTab = .dashboard
                    viewModel.saveNewDelivery(delivery: delivery, reviewScene: reviewScene, deliveryManager: deliveryManager)
                }
            )
            .interactiveDismissDisabled(true)
            .presentationDetents([.large])
        }
        #if !os(visionOS)
        .sheet(isPresented: $viewModel.showingStepTrendSheet) {
            StepTrendSheet()
                .interactiveDismissDisabled()
                .presentationDetents([.medium])
        }
        #endif
        .onChange(of: pendingDeepLink) { _, newLink in
            handleDeepLink(newLink)
        }
        .onChange(of: viewModel.listPath) { _, newValue in
            if newValue.isEmpty {
                viewModel.lastPushedDeliveryID = nil
            }
        }
        .onAppear {
            if pendingDeepLink != nil {
                handleDeepLink(pendingDeepLink)
            }
        }
    }

    // MARK: - Regular width (iPad / visionOS)

    private var regularWidthView: some View {
        NavigationSplitView {
            NavigationStack {
                DeliveryListView(showingEntrySheet: $viewModel.showingEntrySheet)
                    .navigationTitle("Deliveries")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            AddDeliveryToolbarButton { viewModel.handleAddTapped() }
                        }
                    }
            }
        } detail: {
            NavigationStack(path: $viewModel.listPath) {
                DashboardView(showingEntrySheet: $viewModel.showingEntrySheet, showingReorderSheet: $viewModel.showingReorderSheet)
                    .minimizeToolbarOnScrollIfAvailable()
                    .navigationTitle("Stork")
                    .toolbar { dashboardToolbar(showsSettingsButton: true) }
                    .navigationDestination(for: UUID.self) { deliveryId in
                        DeliveryDestinationView(deliveryId: deliveryId)
                    }
            }
        }
        .sheet(isPresented: $viewModel.showingSettingsSheet) {
            NavigationStack {
                SettingsView()
                    .interactiveDismissDisabled()
                    .presentationDetents([.large])
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") {
                                viewModel.showingSettingsSheet = false
                            }
                            .keyboardShortcut(.escape, modifiers: [])
                            .hoverEffect(.highlight)
                        }
                    }
            }
        }
        .sheet(isPresented: $viewModel.showingCalendarSheet) {
            NavigationStack {
                DeliveryCalendarView(
                    onDeliverySelected: { deliveryId in
                        viewModel.navigateFromCalendar(to: deliveryId)
                    }
                )
                .interactiveDismissDisabled()
                .presentationDetents([.large])
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            viewModel.showingCalendarSheet = false
                        }
                        .keyboardShortcut(.escape, modifiers: [])
                        .hoverEffect(.highlight)
                    }
                }
            }
        }
        #if !os(visionOS)
        .task {
            guard healthManager.isStepTrackingSupported else { return }
            await healthManager.requestAuthorization()
            if healthManager.isAuthorized {
                healthManager.startObservingStepCount()
            }
        }
        #endif
    }

    // MARK: - Compact width (iPhone)

    private var compactWidthView: some View {
        TabView(selection: $viewModel.appTab) {
            Tab(String(localized: AppTab.dashboard.localizedTitle), systemImage: AppTab.dashboard.systemImage, value: .dashboard) {
                NavigationStack {
                    DashboardView(
                        showingEntrySheet: $viewModel.showingEntrySheet,
                        showingReorderSheet: $viewModel.showingReorderSheet
                    )
                    .minimizeToolbarOnScrollIfAvailable()
                    .navigationTitle("Stork")
                    .toolbar { dashboardToolbar(showsSettingsButton: false) }
                }
            }

            Tab(String(localized: AppTab.list.localizedTitle), systemImage: AppTab.list.systemImage, value: .list) {
                NavigationStack(path: $viewModel.listPath) {
                    DeliveryListView(showingEntrySheet: $viewModel.showingEntrySheet)
                        .navigationTitle(Text(AppTab.list.localizedTitle))
                        .navigationDestination(for: UUID.self) { deliveryId in
                            DeliveryDestinationView(deliveryId: deliveryId)
                        }
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                AddDeliveryToolbarButton { viewModel.handleAddTapped() }
                            }
                        }
                }
            }

            Tab(String(localized: AppTab.calendar.localizedTitle), systemImage: AppTab.calendar.systemImage, value: .calendar) {
                NavigationStack {
                    DeliveryCalendarView()
                        .navigationTitle(Text(AppTab.calendar.localizedTitle))
                        .navigationDestination(for: UUID.self) { deliveryId in
                            DeliveryDestinationView(deliveryId: deliveryId)
                        }
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                AddDeliveryToolbarButton { viewModel.handleAddTapped() }
                            }
                        }
                }
            }

            Tab(String(localized: AppTab.settings.localizedTitle), systemImage: AppTab.settings.systemImage, value: .settings) {
                NavigationStack {
                    SettingsView()
                        .navigationTitle(Text(AppTab.settings.localizedTitle))
                }
            }
        }
        .tint(viewModel.appTab.color())
        .tabViewBottomAccessoryIfAvailable {
            HStack(spacing: 12) {
                #if !os(visionOS)
                StepCountPill {
                    viewModel.showingStepTrendSheet = true
                }
                #endif

                Spacer()

                WeatherPill()
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private func dashboardToolbar(showsSettingsButton: Bool) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.showingReorderSheet = true
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Reorder cards")
            .accessibilityHint("Customize the order of dashboard cards")
            .keyboardShortcut("r", modifiers: .command)
            .hoverEffect(.highlight)
        }

        #if !os(visionOS)
        stepToolbarItem

        ToolbarSpacer(.flexible, placement: .topBarTrailing)
        #endif

        if showsSettingsButton {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showingCalendarSheet = true
                } label: {
                    Image(systemName: "calendar")
                }
                .accessibilityLabel("Calendar")
                .tint(.storkPink)
                .keyboardShortcut("k", modifiers: .command)
                .hoverEffect(.highlight)
            }

            #if !os(visionOS)
            ToolbarSpacer(.flexible, placement: .topBarTrailing)
            #endif

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showingSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
                .tint(.storkOrange)
                .keyboardShortcut(",", modifiers: .command)
                .hoverEffect(.highlight)
            }
        } else {
            ToolbarItem(placement: .confirmationAction) {
                AddDeliveryToolbarButton(action: { viewModel.handleAddTapped() }, showsTip: true)
            }
        }
    }

    #if !os(visionOS)
    /// The step pill lives in the bottom accessory on iPhone; only regular
    /// width needs a toolbar entry — and only where a pedometer exists
    /// (hidden for "Designed for iPad" on Mac / Apple Vision Pro).
    @ToolbarContentBuilder
    private var stepToolbarItem: some ToolbarContent {
        if isRegularWidth && healthManager.isStepTrackingSupported {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.lightImpact()
                    if !healthManager.isAuthorized {
                        Task {
                            await healthManager.requestAuthorization()
                            if healthManager.isAuthorized {
                                healthManager.startObservingStepCount()
                            }
                        }
                    }
                    viewModel.showingStepTrendSheet = true
                } label: {
                    Label(
                        healthManager.isAuthorized ? "\(healthManager.todayStepCount)" : "Steps",
                        systemImage: "figure.walk"
                    )
                }
                .tint(.storkPurple)
            }
        }
    }
    #endif

    // MARK: - Helpers

    private var isRegularWidth: Bool {
        hSizeClass == .regular
    }

    private func handleDeepLink(_ link: DeepLink?) {
        guard let link else { return }
        defer { pendingDeepLink = nil }
        viewModel.handle(deepLink: link, isRegularWidth: isRegularWidth)
    }

    private func shareMilestone(_ milestone: MilestoneCelebration) {
        let milestoneType: CardImageRenderer.MilestoneType = milestone.type == .babies ? .babies : .deliveries
        if let image = exportManager.renderMilestoneCard(
            count: milestone.count,
            milestoneType: milestoneType
        ) {
            milestoneShareImage = IdentifiableImage(image: image)
        }
    }
}

// MARK: - Helper Types

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview("MainView") {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: Delivery.self, Baby.self, DeliveryTag.self, configurations: config)
    }()

    MainView(pendingDeepLink: .constant(nil))
        .modelContainer(container)
        .environment(DeliveryManager(container: container))
        .environment(WeatherManager())
        .environment(LocationManager())
        .environment(ExportManager())
        .environment(CloudSyncManager())
        #if !os(visionOS)
        .environment(HealthManager())
        #endif
}
