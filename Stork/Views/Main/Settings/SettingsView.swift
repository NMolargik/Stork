//
//  SettingsView.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI
import SwiftData

// MARK: - Settings View
struct SettingsView: View {
    @Environment(UserManager.self) private var userManager
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false
    @AppStorage(AppStorageKeys.selectedIconColor) private var selectedIconColor = "purple"

    @State private var viewModel = ViewModel()
    @State private var iconManager = IconManager()
    @State private var pendingIconColor: String?

    #if DEBUG
    @State private var showDebugTools = false
    #endif

    private struct IconOption: Identifiable, Equatable {
        let color: String
        let asset: String
        var id: String { color }
    }

    private let iconOptions: [IconOption] = [
        .init(color: "purple", asset: "icon-purple-preview"),
        .init(color: "blue", asset: "icon-blue-preview"),
        .init(color: "pink", asset: "icon-pink-preview"),
        .init(color: "orange", asset: "icon-orange-preview")
    ]

    var onSignOut: () -> Void

    var body: some View {
        @Bindable var manager = userManager

        Form {
            // MARK: - Units & Date Format
            Toggle("Use Metric Units", isOn: $useMetricUnits)
                .tint(.green)
                .onChange(of: useMetricUnits) { _, _ in Haptics.lightImpact() }

            Toggle("Use Day–Month–Year Dates", isOn: $useDayMonthYearDates)
                .tint(.green)
                .accessibilityHint("Switch between Month–Day–Year and Day–Month–Year formats for dates.")
                .onChange(of: useDayMonthYearDates) { _, _ in Haptics.lightImpact() }

            // MARK: - Edit User
            Button {
                viewModel.editingUser = true
                Haptics.lightImpact()
            } label: {
                Text("Edit User")
                    .bold()
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)

            #if DEBUG
            Button {
                Haptics.lightImpact()
                showDebugTools = true
            } label: {
                Text("Debug Tools")
                    .bold()
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            #endif

//            // MARK: - App Icon Picker
//            Section("App Icon") {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(iconOptions) { option in
//                            ZStack(alignment: .topTrailing) {
//                                Image(option.asset)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 80, height: 80)
//                                    .clipShape(RoundedRectangle(cornerRadius: 16))
//                                    .overlay(
//                                        RoundedRectangle(cornerRadius: 16)
//                                            .stroke(.green, lineWidth: 4)
//                                            .opacity(selectedIconColor == option.color ? 1 : 0)
//                                    )
//                                    .contentShape(RoundedRectangle(cornerRadius: 16))
//                                    .onTapGesture {
//                                        selectedIconColor = option.color
//                                        Haptics.lightImpact()
//
//                                        if scenePhase == .active {
//                                            Task { await iconManager.changeAppIcon(to: option.color) }
//                                        } else {
//                                            pendingIconColor = option.color
//                                        }
//                                    }
//
//                                if selectedIconColor == option.color {
//                                    Image(systemName: "checkmark.circle.fill")
//                                        .foregroundStyle(.green)
//                                        .background(.thinMaterial, in: Circle())
//                                        .offset(x: -6, y: 6)
//                                }
//                            }
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//            }

            // MARK: - App Info
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
                .presentationDetents([.fraction(0.7)])
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
        #if DEBUG
        .sheet(isPresented: $showDebugTools) {
            let hospitalId = userManager.currentUser?.primaryHospitalId ?? "DEBUG_HOSPITAL_ID"
            DebugSeedDeliveriesView(hospitalId: hospitalId)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        #endif
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, let color = pendingIconColor {
                pendingIconColor = nil
                Task { await iconManager.changeAppIcon(to: color) }
            }
        }
        .onAppear { viewModel.startNetworkMonitoring() }
        .onDisappear { viewModel.stopNetworkMonitoring() }
    }
}

// MARK: - Preview
#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    return SettingsView(onSignOut: {})
        .environment(UserManager(context: context))
}
