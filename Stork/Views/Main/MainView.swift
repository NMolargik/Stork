//
//  MainView.swift
//  Stork
//

import SwiftUI
import SwiftData
import UIKit

/// One adaptive navigation model for every platform: tab bar on iPhone,
/// switchable tab bar / sidebar on iPad and Mac, sidebar on visionOS —
/// per the Liquid Glass era HIG, instead of a forked NavigationSplitView.
struct MainView: View {
    @Environment(DeliveryManager.self) private var deliveryManager
    @Environment(ExportManager.self) private var exportManager
    #if !os(visionOS)
    @Environment(HealthManager.self) private var healthManager
    #endif

    @Binding var pendingDeepLink: DeepLink?

    @State private var viewModel = ViewModel()
    @State private var milestoneShareImage: IdentifiableImage?

    var body: some View {
        ZStack {
            adaptiveTabs

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
            // Read-only sheet — keep the standard swipe-to-dismiss (HIG).
            StepTrendSheet()
                .presentationDetents([.medium])
        }
        .task {
            guard healthManager.isStepTrackingSupported else { return }
            await healthManager.requestAuthorization()
            if healthManager.isAuthorized {
                healthManager.startObservingStepCount()
            }
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

    // MARK: - Adaptive tabs

    private var adaptiveTabs: some View {
        TabView(selection: $viewModel.appTab) {
            Tab(String(localized: AppTab.dashboard.localizedTitle), systemImage: AppTab.dashboard.systemImage, value: .dashboard) {
                NavigationStack {
                    DashboardView(
                        showingEntrySheet: $viewModel.showingEntrySheet,
                        showingReorderSheet: $viewModel.showingReorderSheet
                    )
                    .minimizeToolbarOnScrollIfAvailable()
                    .navigationTitle("Stork")
                    .toolbar { dashboardToolbar }
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
        .tabViewStyle(.sidebarAdaptable)
        // No per-tab tint: an explicit ancestor tint cascades into toolbar
        // buttons and even overrides the destructive red on swipe actions.
        // The app-wide AccentColor is the single accent; roles supply
        // semantic colors (HIG).
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

    // MARK: - Dashboard toolbar

    @ToolbarContentBuilder
    private var dashboardToolbar: some ToolbarContent {
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
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        #endif

        ToolbarItem(placement: .confirmationAction) {
            AddDeliveryToolbarButton(action: { viewModel.handleAddTapped() }, showsTip: true)
        }
    }

    // MARK: - Helpers

    private func handleDeepLink(_ link: DeepLink?) {
        guard let link else { return }
        defer { pendingDeepLink = nil }
        viewModel.handle(deepLink: link)
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
        .environment(ToastManager())
        #if !os(visionOS)
        .environment(HealthManager())
        #endif
}
