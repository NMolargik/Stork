//
//  MainView.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI
import SwiftData
import UIKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false
    @AppStorage(AppStorageKeys.hasSeenHospitalRemovalNotice) private var hasSeenHospitalRemovalNotice: Bool = false

    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(UserManager.self) private var userManager: UserManager
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(WeatherManager.self) private var weatherManager: WeatherManager
    @Environment(LocationManager.self) private var locationManager: LocationManager
    @Environment(ExportManager.self) private var exportManager: ExportManager

    var resetApplication: () -> Void
    @Binding var pendingDeepLink: DeepLink?

    @State private var viewModel: ViewModel = ViewModel()
    @State private var showHospitalRemovalAlert: Bool = false
    @State private var milestoneShareImage: IdentifiableImage?
    
    var body: some View {
        ZStack {
            Group {
                if isRegularWidth {
                    regularWidthView()
                } else {
                    compactWidthView()
                }
            }
            .onAppear {
                // Show hospital removal notice to existing users who haven't seen it
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

            // Milestone celebration overlay
            if let milestone = deliveryManager.pendingMilestoneCelebration {
                MilestoneCelebrationView(
                    milestone: milestone,
                    userName: userManager.currentUser.map { "\($0.firstName) \($0.lastName)" },
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
        .onChange(of: pendingDeepLink) { _, newLink in
            handleDeepLink(newLink)
        }
        .onAppear {
            // Handle any pending deep link on appear
            if pendingDeepLink != nil {
                handleDeepLink(pendingDeepLink)
            }
        }
    }

    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }

        // Reset the deep link after handling
        defer { pendingDeepLink = nil }

        switch link {
        case .newDelivery:
            viewModel.showingEntrySheet = true
        case .home:
            viewModel.appTab = .home
        case .deliveries, .weeklyDeliveries:
            viewModel.appTab = .list
        case .settings:
            if isRegularWidth {
                viewModel.showingSettingsSheet = true
            } else {
                viewModel.appTab = .settings
            }
        }
    }

    private func shareMilestone(_ milestone: DeliveryManager.MilestoneCelebration) {
        let milestoneType: CardImageRenderer.MilestoneType = milestone.type == .babies ? .babies : .deliveries
        if let image = exportManager.renderMilestoneCard(
            count: milestone.count,
            milestoneType: milestoneType,
            userName: userManager.currentUser.map { "\($0.firstName) \($0.lastName)" }
        ) {
            milestoneShareImage = IdentifiableImage(image: image)
        }
    }
    
    // MARK: - iPAD
    
    @ViewBuilder
    private func regularWidthView() -> some View {
        NavigationSplitView {
            NavigationStack {
                DeliveryListView(showingEntrySheet: $viewModel.showingEntrySheet)
                    .navigationTitle("Deliveries")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                viewModel.handleAddTapped()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                }
                                .foregroundStyle(.storkBlue)
                            }
                            .accessibilityIdentifier("addEntryButton")
                            .tint(.storkBlue)
                            .keyboardShortcut("n", modifiers: .command)
                            .hoverEffect(.highlight)
                        }
                    }
            }
        } detail: {
            NavigationStack(path: $viewModel.listPath) {
                HomeView(showingEntrySheet: $viewModel.showingEntrySheet, showingReorderSheet: $viewModel.showingReorderSheet)
                    .navigationTitle("Stork")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                viewModel.showingReorderSheet = true
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                            }
                            .accessibilityLabel("Reorder cards")
                            .tint(.storkPurple)
                            .keyboardShortcut("r", modifiers: .command)
                            .hoverEffect(.highlight)
                        }

                        if #available(iOS 26.0, *) {
                            ToolbarSpacer(.flexible, placement: .topBarTrailing)
                        }

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
                        
                        if #available(iOS 26.0, *) {
                            ToolbarSpacer(.flexible, placement: .topBarTrailing)
                        }

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
                    }
                    .navigationDestination(for: UUID.self) { deliveryId in
                        if let delivery = (deliveryManager.visibleDeliveries.first { $0.id == deliveryId }
                                           ?? deliveryManager.deliveries.first { $0.id == deliveryId }) {
                            DeliveryDetailView(delivery: delivery)
                        } else {
                            ContentUnavailableView(
                                "Delivery Not Found",
                                systemImage: "exclamationmark.triangle",
                                description: Text("The selected delivery could not be loaded.")
                            )
                        }
                    }
            }
        }
        .sheet(isPresented: $viewModel.showingSettingsSheet) {
            NavigationStack {
                SettingsView(
                    onSignOut: {
                        resetApplication()
                    }
                )
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
                        viewModel.showingCalendarSheet = false
                        // Navigate after sheet dismisses
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.appTab = .list
                            viewModel.listPath.append(deliveryId)
                        }
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
        .sheet(isPresented: $viewModel.showingEntrySheet) {
            DeliveryEntryView(
                onDeliverySaved: { delivery, reviewScene in
                    viewModel.updateDelivery(delivery: delivery, reviewScene: reviewScene, deliveryManager: deliveryManager)
                    viewModel.appTab = .home
                }
            )
            .interactiveDismissDisabled(true)
            .presentationDetents([.large])
        }
        .onChange(of: viewModel.listPath) { _, newValue in
            if newValue.count == 0 {
                viewModel.lastPushedDeliveryID = nil
            }
        }
    }
    
    // MARK: - iPHONE
    
    @ViewBuilder
    private func compactWidthView() -> some View {
        TabView(selection: $viewModel.appTab) {
            NavigationStack {
                HomeView(
                    showingEntrySheet: $viewModel.showingEntrySheet,
                    showingReorderSheet: $viewModel.showingReorderSheet
                )
                .navigationTitle("Stork")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showingReorderSheet = true
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundStyle(.storkPurple)
                        }
                        .accessibilityLabel("Reorder cards")
                        .accessibilityHint("Customize the order of home screen cards")
                        .keyboardShortcut("r", modifiers: .command)
                        .hoverEffect(.highlight)
                    }

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.flexible, placement: .topBarTrailing)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.handleAddTapped()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.blue)
                        }
                        .accessibilityIdentifier("addEntryButton")
                        .keyboardShortcut("n", modifiers: .command)
                        .hoverEffect(.highlight)
                    }
                }
            }
            .tabItem {
                AppTab.home.icon()
                Text(AppTab.home.rawValue)
            }
            .tag(AppTab.home)
            
            NavigationStack(path: $viewModel.listPath) {
                DeliveryListView(showingEntrySheet: $viewModel.showingEntrySheet)
                    .navigationTitle(AppTab.list.rawValue)
                    .navigationDestination(for: UUID.self) { deliveryId in
                        if let delivery = (deliveryManager.visibleDeliveries.first { $0.id == deliveryId }
                                           ?? deliveryManager.deliveries.first { $0.id == deliveryId }) {
                            DeliveryDetailView(delivery: delivery)
                        } else {
                            ContentUnavailableView(
                                "Delivery Not Found",
                                systemImage: "exclamationmark.triangle",
                                description: Text("The selected delivery could not be loaded.")
                            )
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                viewModel.handleAddTapped()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                    Text("Add")
                                        .bold()
                                }
                                .foregroundStyle(.storkBlue)
                            }
                            .accessibilityIdentifier("addEntryButton")
                            .keyboardShortcut("n", modifiers: .command)
                            .hoverEffect(.highlight)
                        }
                    }
            }
            .tabItem {
                AppTab.list.icon()
                Text(AppTab.list.rawValue)
            }
            .tag(AppTab.list)
            
            NavigationStack {
                DeliveryCalendarView()
                    .navigationTitle(AppTab.calendar.rawValue)
                    .navigationDestination(for: UUID.self) { deliveryId in
                        if let delivery = (deliveryManager.visibleDeliveries.first { $0.id == deliveryId }
                                           ?? deliveryManager.deliveries.first { $0.id == deliveryId }) {
                            DeliveryDetailView(delivery: delivery)
                        } else {
                            ContentUnavailableView(
                                "Delivery Not Found",
                                systemImage: "exclamationmark.triangle",
                                description: Text("The selected delivery could not be loaded.")
                            )
                        }
                    }
            }
            .tabItem {
                AppTab.calendar.icon()
                Text(AppTab.calendar.rawValue)
            }
            .tag(AppTab.calendar)
            
            NavigationStack {
                SettingsView(
                    onSignOut: {
                        resetApplication()
                    }
                )
                .navigationTitle(AppTab.settings.rawValue)
            }
            .tabItem {
                AppTab.settings.icon()
                Text(AppTab.settings.rawValue)
            }
            .tag(AppTab.settings)
        }
        .tint(viewModel.appTab.color())
        .tabViewBottomAccessoryIfAvailable {
            HStack(spacing: 12) {
                Group {
                    if healthManager.isAuthorized {
                        HStack(spacing: 10) {
                            Image(systemName: "figure.walk")
                                .imageScale(.medium)

                            Text("\(healthManager.todayStepCount) steps today")
                                .font(.headline)
                                .bold()
                                .monospacedDigit()
                            
                            Spacer(minLength: 0)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Today's steps")
                        .accessibilityValue(Text("\(healthManager.todayStepCount)"))
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.walk")
                                .imageScale(.medium)
                                .foregroundStyle(.storkPurple)
                            Text("Connect Health")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .task {
                            await healthManager.requestAuthorization()
                            healthManager.startObservingStepCount()
                        }
                        .accessibilityLabel("Connect Health to show pedometer")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Spacer()
                
                // Weather pill
                Group {
                    if weatherManager.isFetching {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Loading...")
                    } else if weatherManager.error != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .imageScale(.medium)
                            Text("Unavailable")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .onTapGesture {
                                    Task {
                                        await weatherManager.refresh()
                                    }
                                }
                        }
                        .accessibilityLabel("Weather unavailable")
                    } else {
                        HStack(spacing: 8) {
                            weatherManager.condition?.weatherSymbolView()
                                .imageScale(.medium)
                            
                            if let temp = weatherManager.temperatureString {
                                if useMetricUnits,
                                   let fValue = Double(temp.filter("0123456789.-".contains)) {
                                    let celsius = (fValue - 32) * 5 / 9
                                    Text(String(format: "%.1f°C", celsius))
                                        .font(.headline)
                                        .bold()
                                        .monospacedDigit()
                                } else {
                                    Text("\(temp)")
                                        .font(.headline)
                                        .bold()
                                        .monospacedDigit()
                                }
                            }
                        }
                        .task {
                            await weatherManager.refresh()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current weather")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
            }
        }
        .sheet(isPresented: $viewModel.showingEntrySheet) {
            DeliveryEntryView(
                onDeliverySaved: { delivery, reviewScene in
                    viewModel.appTab = .home
                    viewModel.updateDelivery(delivery: delivery, reviewScene: reviewScene, deliveryManager: deliveryManager)
                    
                })
            .interactiveDismissDisabled(true)
            .presentationDetents([.large])
        }
        .onChange(of: viewModel.listPath) { _, newValue in
            if newValue.count == 0 {
                viewModel.lastPushedDeliveryID = nil
            }
        }
    }
    
    // MARK: - Helpers

    private var isRegularWidth: Bool {
        hSizeClass == .regular
    }
}

// MARK: - Helper Types

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview("MainView") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    return MainView(resetApplication: {}, pendingDeepLink: .constant(nil))
        .environment(DeliveryManager(context: context))
        .environment(UserManager(context: context))
        .environment(HealthManager())
        .environment(WeatherManager())
        .environment(LocationManager())
        .environment(InsightManager(deliveryManager: DeliveryManager(context: context)))
        .environment(ExportManager())
}
