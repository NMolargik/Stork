//
//  SettingsView.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI
import SwiftData
import Network

struct SettingsView: View {
    @Environment(UserManager.self) private var userManager: UserManager

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false

    @State private var viewModel = ViewModel()
    
    var onSignOut: () -> Void
    var onDeletion: () -> Void

    var body: some View {
        @Bindable var manager = userManager
        
        Form {
            Toggle("Use Metric Units", isOn: $useMetricUnits)
                .tint(.green)
                .onChange(of: useMetricUnits) { _, _ in Haptics.lightImpact() }
            
            Toggle("Use Day–Month–Year Dates", isOn: $useDayMonthYearDates)
                .tint(.green)
                .accessibilityHint("Switch between Month–Day–Year and Day–Month–Year formats for dates.")
                .onChange(of: useDayMonthYearDates) { _, _ in Haptics.lightImpact() }
            
            Button {
                viewModel.editingUser = true
                Haptics.lightImpact()
            } label: {
                Text("Edit User")
                    .bold()
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            
            Section("Stork") {
                LabeledContent("Version") {
                    Text(viewModel.appVersion)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Developer") {
                    Link("Nick Molargik", destination: URL(string: "https://www.linkedin.com/in/nicholas-molargik/")!)
                        .foregroundStyle(.storkBlue)
                }
                
                LabeledContent("Publisher") {
                    Link("Molargik Software LLC", destination: URL(string: "https://www.molargiksoftware.com")!)
                        .foregroundStyle(.storkBlue)
                }
            }
        }
        .sheet(isPresented: $viewModel.editingUser) {
            if let user = manager.currentUser {
                UserEditView(
                    firstName: Binding(
                        get: { user.firstName },
                        set: { user.firstName = $0 }
                    ),
                    lastName: Binding(
                        get: { user.lastName },
                        set: { user.lastName = $0 }
                    ),
                    birthday: Binding(
                        get: { user.birthday },
                        set: { user.birthday = $0 }
                    ),
                    role: Binding(
                        get: { user.role },
                        set: { user.role = $0 }
                    ),
                    validationMessage: ""
                )
                .padding(.top)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            } else {
                ContentUnavailableView(
                    "No user found",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("Create a user to edit profile details.")
                )
            }
        }
        .onAppear { viewModel.startNetworkMonitoring() }
        .onDisappear { viewModel.stopNetworkMonitoring() }
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    SettingsView(
        onSignOut: {},
        onDeletion: {}
    )
    .environment(UserManager(context: context))
}


extension SettingsView {
    @Observable
    class ViewModel {
        // UI state
        var editingUser: Bool = false
        var showSignOutConfirmation: Bool = false
        var showDeleteConfirmation: Bool = false
        var showingFarewell: Bool = false
        var pendingProfileImageData: Data? = nil

        // Network state
        private var networkMonitor: NWPathMonitor?
        var isOnline: Bool = true

        // App metadata
        var appVersion: String {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
            let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "—"
            return "\(version) (Build \(build))"
        }
        var bundleIdentifier: String { Bundle.main.bundleIdentifier ?? "—" }

        // Lifecycle
        func startNetworkMonitoring() {
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { [weak self] path in
                DispatchQueue.main.async {
                    self?.isOnline = (path.status == .satisfied)
                }
            }
            let queue = DispatchQueue(label: "NetworkMonitor")
            monitor.start(queue: queue)
            self.networkMonitor = monitor
        }

        func stopNetworkMonitoring() {
            networkMonitor?.cancel()
            networkMonitor = nil
        }
    }
}
