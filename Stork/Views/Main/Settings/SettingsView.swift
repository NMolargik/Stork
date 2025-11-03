//
//  SettingsView.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI
import SwiftData

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
                Form {
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
                }
                .scrollDisabled(true)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
            } else {
                ContentUnavailableView(
                    "No user found",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("Create a user to edit profile details.")
                )
                .presentationDetents([.fraction(0.5)])
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
