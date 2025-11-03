//
//  MainView.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI
import SwiftData
import WeatherKit
import Combine

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(UserManager.self) private var userManager: UserManager
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(WeatherManager.self) private var weatherManager: WeatherManager
    @Environment(LocationManager.self) private var locationManager: LocationManager
    
    var resetApplication: () -> Void
    
    @State private var viewModel: ViewModel = ViewModel()
    
    var body: some View {
        Group {
            if isRegularWidth {
                regularWidthView()
            } else {
                compactWidthView()
            }
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
                        }
                    }
            }
        } detail: {
            NavigationStack(path: $viewModel.listPath) {
                HomeView(showingEntrySheet: $viewModel.showingEntrySheet)
                    .navigationTitle("Stork")
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button {
                                viewModel.showingSettingsSheet = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                            }
                            .accessibilityLabel("Settings")
                            .tint(.storkOrange)
                        }
                    }
                    .navigationDestination(for: UUID.self) { deliveryId in
                        if let delivery = (deliveryManager.visibleDeliveries.first { $0.id == deliveryId }
                                           ?? deliveryManager.deliveries.first { $0.id == deliveryId }) {
                            DeliveryDetailView(
                                delivery: delivery,
                                onClose: {
                                    if !viewModel.listPath.isEmpty {
                                        viewModel.listPath.removeLast()
                                    }
                                }
                            )
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
                    showingEntrySheet: $viewModel.showingEntrySheet
                )
                .navigationTitle("Stork")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.handleAddTapped()
                        } label: {
                            Text("New Delivery")
                                .bold()
                                .foregroundStyle(.storkBlue)
                        }
                        .accessibilityIdentifier("addEntryButton")
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
                        }
                    }
            }
            .tabItem {
                AppTab.list.icon()
                Text(AppTab.list.rawValue)
            }
            .tag(AppTab.list)
            
            NavigationStack {
                HospitalsView()
                    .navigationTitle(AppTab.hospitals.rawValue)
            }
            .tabItem {
                AppTab.hospitals.icon()
                Text(AppTab.hospitals.rawValue)
            }
            .tag(AppTab.hospitals)
            
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

                            Text("\(healthManager.todayStepCount) steps")
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
                            Text("Loading weather…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Loading weather")
                    } else if weatherManager.error != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .imageScale(.medium)
                            Text("Weather Unavailable")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Weather unavailable")
                    } else {
                        HStack(spacing: 8) {
                            weatherManager.condition?.weatherSymbolView()
                                .imageScale(.medium)
                            
                            if let temp = weatherManager.temperatureString {
                                Text("\(temp)")
                                    .font(.headline)
                                    .bold()
                                    .monospacedDigit()
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
    
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    }
}

#Preview("MainView") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    return MainView(resetApplication: {})
        .environment(DeliveryManager(context: context))
        .environment(UserManager(context: context))
        .environment(HealthManager())
        .environment(HospitalManager())
        .environment(WeatherManager())
        .environment(LocationManager())
        .environment(InsightManager(deliveryManager: DeliveryManager(context: context)))
}
