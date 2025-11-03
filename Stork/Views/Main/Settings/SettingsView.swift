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
    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingIconColor: String?

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false
    @AppStorage(AppStorageKeys.selectedIconColor) private var selectedIconColor: String = "purple"

    @State private var viewModel = ViewModel()

    @State private var isChangingIcon = false
    @State private var iconRetryCount = 0
    private let maxIconRetries = 3
    
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

    // Map our UI colors to the actual Info.plist alternate icon KEYS.
    // Update these to match whatever Xcode generated in your asset catalog / Info.plist.
    private let alternateIconKeyForColor: [String: String] = [
        // Primary icon is Purple (nil), so no entry for "purple"
        "blue": "IconBlue",
        "pink": "IconPink",
        "orange": "IconOrange"
    ]
    // Which color corresponds to the PRIMARY icon (nil in API calls)
    private let primaryIconColorKey: String = "purple"

    private func availableAlternateIconKeys() -> [String] {
        guard
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let alternates = icons["CFBundleAlternateIcons"] as? [String: Any]
        else { return [] }
        return Array(alternates.keys).sorted()
    }
    
    private func topMostViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
    
    private func canPresentIconAlertNow() -> Bool {
        // No modal on screen and app is active
        guard UIApplication.shared.applicationState == .active else { return false }
        if let top = topMostViewController(), top.presentedViewController != nil { return false }
        return true
    }
    
    private func scheduleOnNextRunloop(_ block: @escaping () -> Void) {
        DispatchQueue.main.async { block() }
    }
    
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
//                                        guard !isChangingIcon else { return }
//                                        if scenePhase == .active {
//                                            isChangingIcon = true
//                                            iconRetryCount = 0
//                                            changeAppIcon(color: option.color)
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, let color = pendingIconColor {
                pendingIconColor = nil
                isChangingIcon = true
                iconRetryCount = 0
                changeAppIcon(color: color)
            }
        }
        .onAppear { viewModel.startNetworkMonitoring() }
        .onDisappear { viewModel.stopNetworkMonitoring() }
    }
    
    @MainActor
    private func changeAppIcon(color: String) {
        let supported = UIApplication.shared.supportsAlternateIcons
        let current = UIApplication.shared.alternateIconName ?? "nil (primary)"
        print("Supports alternates:", supported, "| Current alternate:", current)

        guard supported else {
            print("Alternate icons not supported on this device.")
            isChangingIcon = false
            return
        }

        // Ensure we can present the system alert (no modals, active app)
        guard canPresentIconAlertNow() else {
            print("Cannot present icon alert yet (modal or inactive). Deferring to next runloop.")
            scheduleOnNextRunloop { [color] in self.changeAppIcon(color: color) }
            return
        }

        let availableKeys = availableAlternateIconKeys()
        print("Available alternate icon keys from Info.plist:", availableKeys)

        let targetIsPrimary = (color == primaryIconColorKey)
        let targetKey = targetIsPrimary ? nil : alternateIconKeyForColor[color]

        if !targetIsPrimary {
            guard let mappedKey = targetKey else {
                print("No mapped alternate icon key for color '\(color)'. Update alternateIconKeyForColor.")
                isChangingIcon = false
                return
            }
            guard availableKeys.contains(mappedKey) else {
                print("Mapped key '\(mappedKey)' not found in Info.plist alternates. Check your asset catalog / Info.plist.")
                isChangingIcon = false
                return
            }
        }

        if (targetIsPrimary && UIApplication.shared.alternateIconName == nil) ||
           (!targetIsPrimary && UIApplication.shared.alternateIconName == targetKey) {
            print("Already using desired icon; no change.")
            isChangingIcon = false
            return
        }

        UIApplication.shared.setAlternateIconName(targetKey) { error in
            if let error = error as NSError? {
                if error.domain == NSPOSIXErrorDomain && error.code == 35 && self.iconRetryCount < self.maxIconRetries {
                    self.iconRetryCount += 1
                    let delay = 0.4 + Double(self.iconRetryCount) * 0.3
                    print("Icon change temporarily unavailable; retry \(self.iconRetryCount)/\(self.maxIconRetries) in \(delay)s...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.changeAppIcon(color: color)
                    }
                } else {
                    print("Failed request to update the app’s icon: \(error)")
                    self.isChangingIcon = false
                }
            } else {
                print("Successfully changed icon to:", targetKey ?? "primary")
                self.isChangingIcon = false
            }
        }
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
