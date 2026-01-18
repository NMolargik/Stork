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
    @Environment(DeliveryManager.self) private var deliveryManager
    @Environment(CloudSyncManager.self) private var cloudSyncManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false
    @AppStorage(AppStorageKeys.selectedIconColor) private var selectedIconColor = "purple"

    @State private var viewModel = ViewModel()
    @State private var iconManager = IconManager()
    @State private var pendingIconColor: String?
    @State private var showDeleteAllAlert = false
    @State private var isDeleting = false
    @State private var isSyncingManually = false

    #if DEBUG
    @State private var isSeeding = false
    @State private var seedingSummary: String?
    @State private var showOnboardingPreview = false
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
            // MARK: - Profile
            Section {
                Button {
                    viewModel.editingUser = true
                    Haptics.lightImpact()
                } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.storkPurple)

                        if let user = manager.currentUser {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(user.firstName) \(user.lastName)")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text(user.role.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Edit Profile")
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit user profile")
                .accessibilityHint("Opens form to edit your name, birthday, and role")
            }

            // MARK: - Preferences
            Section {
                Toggle(isOn: $useMetricUnits) {
                    Label("Metric Units", systemImage: "ruler")
                }
                .tint(.storkPurple)
                .accessibilityLabel("Use metric units")
                .accessibilityHint("Switch between imperial and metric units for weight and length measurements")
                .onChange(of: useMetricUnits) { _, _ in Haptics.lightImpact() }

                Toggle(isOn: $useDayMonthYearDates) {
                    Label("Day–Month–Year Dates", systemImage: "calendar")
                }
                .tint(.storkPurple)
                .accessibilityLabel("Use day month year date format")
                .accessibilityHint("Switch between Month–Day–Year and Day–Month–Year formats for dates")
                .onChange(of: useDayMonthYearDates) { _, _ in Haptics.lightImpact() }
            } header: {
                Text("Preferences")
            }

            // MARK: - App Icon Picker
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(iconOptions) { option in
                            ZStack(alignment: .topTrailing) {
                                Image(option.asset)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(.storkPurple, lineWidth: 3)
                                            .opacity(selectedIconColor == option.color ? 1 : 0)
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 14))
                                    .onTapGesture {
                                        selectedIconColor = option.color
                                        Haptics.lightImpact()

                                        if scenePhase == .active {
                                            Task { await iconManager.changeAppIcon(to: option.color) }
                                        } else {
                                            pendingIconColor = option.color
                                        }
                                    }

                                if selectedIconColor == option.color {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.storkPurple)
                                        .background(.white, in: Circle())
                                        .offset(x: -4, y: 4)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("App Icon")
            }

            // MARK: - iCloud Sync
            Section {
                HStack(spacing: 12) {
                    Image(systemName: syncStatusIcon)
                        .font(.title3)
                        .foregroundStyle(syncStatusColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud")
                            .font(.body)
                        Text(cloudSyncManager.syncStatus.displayText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if cloudSyncManager.isSyncing || isSyncingManually {
                        ProgressView()
                            .controlSize(.small)
                    } else if canSync {
                        Button {
                            Haptics.lightImpact()
                            Task { await triggerManualSync() }
                        } label: {
                            Text("Sync")
                                .font(.subheadline.bold())
                                .foregroundStyle(.storkBlue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("iCloud Sync Status")
                .accessibilityValue(cloudSyncManager.syncStatus.displayText)
            } header: {
                Text("Backup & Sync")
            } footer: {
                if !cloudSyncManager.isCloudAvailable {
                    Text("Sign in to iCloud in Settings to enable sync.")
                }
            }

            // MARK: - Export & Share
            Section {
                NavigationLink {
                    ExportView()
                } label: {
                    Label("Export & Share", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Export and Share")
                .accessibilityHint("Export data or share statistics as images")
            } header: {
                Text("Data")
            } footer: {
                Text("Export delivery records as PDF or CSV, or share your statistics.")
            }

            // MARK: - Danger Zone
            Section {
                Button(role: .destructive) {
                    Haptics.lightImpact()
                    showDeleteAllAlert = true
                } label: {
                    HStack {
                        Label(isDeleting ? "Deleting…" : "Delete All Deliveries", systemImage: "trash")
                        Spacer()
                        if isDeleting {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
                .accessibilityLabel("Delete all deliveries")
                .accessibilityHint("Permanently removes all delivery records")
            } footer: {
                Text("This will permanently remove all \(deliveryManager.deliveries.count) deliveries.")
            }

            #if DEBUG
            // MARK: - Debug Tools
            Section {
                Button {
                    guard !isSeeding else { return }
                    Haptics.lightImpact()
                    Task { await seedRealisticData() }
                } label: {
                    HStack {
                        Label(isSeeding ? "Seeding…" : "Add Sample Data (1 Year)", systemImage: "wand.and.stars")
                            .foregroundStyle(.orange)
                        Spacer()
                        if isSeeding {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isSeeding)

                if let seedingSummary {
                    Text(seedingSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Haptics.lightImpact()
                    showOnboardingPreview = true
                } label: {
                    Label("Preview Onboarding", systemImage: "hand.wave")
                        .foregroundStyle(.storkPurple)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.lightImpact()
                    triggerTestMilestone()
                } label: {
                    Label("Test Milestone", systemImage: "party.popper")
                        .foregroundStyle(.yellow)
                }
                .buttonStyle(.plain)
            } header: {
                Label("Developer", systemImage: "hammer.fill")
            }
            #endif

            // MARK: - About
            Section {
                LabeledContent("Version", value: viewModel.appVersion)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("App version \(viewModel.appVersion)")

                LabeledContent("Developer") {
                    Link("Nick Molargik", destination: URL(string: "https://www.linkedin.com/in/nicholas-molargik/")!)
                        .foregroundStyle(.storkBlue)
                }
                .accessibilityHint("Opens LinkedIn profile")

                LabeledContent("Publisher") {
                    Link("Molargik Software LLC", destination: URL(string: "https://www.molargiksoftware.com")!)
                        .foregroundStyle(.storkBlue)
                }
                .accessibilityHint("Opens publisher website")
            } header: {
                Text("About")
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, let color = pendingIconColor {
                pendingIconColor = nil
                Task { await iconManager.changeAppIcon(to: color) }
            }
        }
        .onAppear { viewModel.startNetworkMonitoring() }
        .onDisappear { viewModel.stopNetworkMonitoring() }
        .alert("Delete All Deliveries?", isPresented: $showDeleteAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                Task { await deleteAllDeliveries() }
            }
        } message: {
            Text("This will permanently delete all \(deliveryManager.deliveries.count) delivery records and their associated baby data. This action cannot be undone.")
        }
        #if DEBUG
        .sheet(isPresented: $showOnboardingPreview) {
            OnboardingView(onFinished: {
                showOnboardingPreview = false
            })
            .environment(userManager)
            .environment(LocationManager())
            .environment(HealthManager())
            .interactiveDismissDisabled()
        }
        #endif
    }

    // MARK: - Delete All
    @MainActor
    private func deleteAllDeliveries() async {
        isDeleting = true
        defer { isDeleting = false }
        deliveryManager.deleteAllDeliveries()
        Haptics.mediumImpact()
    }

    // MARK: - iCloud Sync Helpers

    private var syncStatusIcon: String {
        cloudSyncManager.syncStatus.systemImage
    }

    private var syncStatusColor: Color {
        switch cloudSyncManager.syncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .error:
            return .red
        case .offline:
            return .orange
        }
    }

    private var canSync: Bool {
        cloudSyncManager.isCloudAvailable &&
        !cloudSyncManager.isSyncing &&
        !isSyncingManually &&
        viewModel.isOnline
    }

    @MainActor
    private func triggerManualSync() async {
        guard canSync else { return }
        isSyncingManually = true
        defer { isSyncingManually = false }
        await cloudSyncManager.triggerSync()
        Haptics.mediumImpact()
    }

    #if DEBUG
    // MARK: - Realistic Data Seeding
    @MainActor
    private func seedRealisticData() async {
        guard !isSeeding else { return }
        isSeeding = true
        defer { isSeeding = false }

        let cal = Calendar.current
        let now = Date()

        // Start from 11 months ago, end with current month (12 months total)
        // e.g., if today is Jan 17, 2026, we generate data from Feb 2025 through Jan 2026
        let startOfCurrentMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now

        // National averages and distributions (pLoss elevated for realistic sample variety)
        let pCSection = 0.323
        let pVBAC = 0.02
        let pMale = 0.511
        let pLoss = 0.07  // ~7% gives roughly 1 loss per month in sample data
        let pPreterm = 0.1041
        let pNICUBase = 0.098
        let pTwins = 0.0307
        let pTripPlus = 0.000738
        let pNurseCatch = 0.10
        let pEpiduralVag = 0.70

        // Work schedule: typical nurse works 3x 12-hour shifts per week
        // Model ~12-15 deliveries per month with realistic gaps
        func monthlyDeliveryTarget() -> Int {
            max(8, Int(round(normal(mean: 13.0, sd: 3.0))))
        }

        // Vacation weeks (randomly skip 2-3 weeks per year)
        var vacationWeeks: Set<Int> = []
        let vacationCount = Int.random(in: 2...3)
        while vacationWeeks.count < vacationCount {
            vacationWeeks.insert(Int.random(in: 0..<52))
        }

        var inserted = 0
        var insertedBabies = 0

        // Generate data for 12 months: from 11 months ago through current month
        // monthsAgo: 11 = oldest (11 months ago), 0 = current month
        for monthsAgo in stride(from: 11, through: 0, by: -1) {
            let monthStart = cal.date(byAdding: .month, value: -monthsAgo, to: startOfCurrentMonth)!
            let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart)!

            // For current month, only go up to today; for past months, use full month
            let monthEnd = min(nextMonth, now)
            let daysInMonth = cal.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 28

            let deliveriesThisMonth = monthlyDeliveryTarget()

            // Generate working days (simulate 3 shifts per week pattern with some variation)
            var workingDays: [Int] = []
            for week in 0..<5 {
                let weekStart = week * 7
                // Pick 2-4 random days per week to simulate shift pattern
                let shiftsThisWeek = Int.random(in: 2...4)
                var daysThisWeek = Array(0..<7).shuffled().prefix(shiftsThisWeek).map { weekStart + $0 }
                daysThisWeek = daysThisWeek.filter { $0 < daysInMonth }

                // Check if this is a vacation week
                let absoluteWeek = (11 - monthsAgo) * 4 + week
                if vacationWeeks.contains(absoluteWeek % 52) {
                    continue // Skip this week (vacation)
                }
                workingDays.append(contentsOf: daysThisWeek)
            }

            // Distribute deliveries across working days
            guard !workingDays.isEmpty else { continue }
            for _ in 0..<deliveriesThisMonth {
                let randomDay = workingDays.randomElement() ?? 0
                let dayDate = cal.date(byAdding: .day, value: randomDay, to: monthStart) ?? monthStart

                // Deliveries happen at all hours, slightly weighted toward night shift
                let hour: Int
                let hourRoll = Double.random(in: 0...1)
                if hourRoll < 0.4 {
                    hour = Int.random(in: 19...23) // Evening shift
                } else if hourRoll < 0.7 {
                    hour = Int.random(in: 0...6) // Night shift
                } else {
                    hour = Int.random(in: 7...18) // Day shift
                }
                let minute = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55].randomElement() ?? 0
                var when = cal.date(bySettingHour: hour, minute: minute, second: 0, of: dayDate) ?? dayDate
                if when > now { when = now.addingTimeInterval(-60) }

                // Delivery method
                let methodPick = Double.random(in: 0...1)
                let method: DeliveryMethod = {
                    if methodPick < pCSection { return .cSection }
                    else if methodPick < (pCSection + pVBAC) { return .vBac }
                    else { return .vaginal }
                }()

                // Epidural
                let epiduralUsed: Bool = {
                    switch method {
                    case .cSection, .vBac: return true
                    case .vaginal: return Bool.random(probability: pEpiduralVag)
                    }
                }()

                // Baby count
                let multPick = Double.random(in: 0...1)
                let babyCount: Int = {
                    if multPick < pTripPlus { return 3 }
                    else if multPick < (pTripPlus + pTwins) { return 2 }
                    else { return 1 }
                }()

                var babies: [Baby] = []
                for _ in 0..<babyCount {
                    let r = Double.random(in: 0...1)
                    let sex: Sex = (r < pLoss) ? .loss : (r < pLoss + pMale ? .male : .female)
                    let isPreterm = Bool.random(probability: pPreterm)
                    let nicuProb = min(0.85, isPreterm ? (pNICUBase + 0.40) : (pNICUBase * 0.85))
                    let nicuStay = Bool.random(probability: nicuProb)
                    let nurseCatch = Bool.random(probability: pNurseCatch)

                    let weightOz: Double
                    let lengthIn: Double
                    if isPreterm {
                        weightOz = clamp(normal(mean: 88, sd: 18), min: 40, max: 130)
                        lengthIn = clamp(normal(mean: 18.0, sd: 1.0), min: 14.0, max: 20.5)
                    } else {
                        weightOz = clamp(normal(mean: 120, sd: 16), min: 70, max: 160)
                        lengthIn = clamp(normal(mean: 20.0, sd: 0.9), min: 18.0, max: 22.5)
                    }

                    let baby = Baby(
                        nurseCatch: nurseCatch,
                        nicuStay: nicuStay,
                        sex: sex,
                        weight: weightOz,
                        height: lengthIn,
                        birthday: when,
                        delivery: nil
                    )
                    babies.append(baby)
                }

                let delivery = Delivery(
                    date: when,
                    babies: babies,
                    babyCount: babies.count,
                    deliveryMethod: method,
                    epiduralUsed: epiduralUsed
                )

                for b in babies { b.delivery = delivery }
                modelContext.insert(delivery)
                inserted += 1
                insertedBabies += babies.count
            }
        }

        do {
            try modelContext.save()
            await deliveryManager.refresh()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            let oldestMonth = cal.date(byAdding: .month, value: -11, to: startOfCurrentMonth)!
            seedingSummary = "Added \(inserted) deliveries, \(insertedBabies) babies (\(formatter.string(from: oldestMonth)) – \(formatter.string(from: startOfCurrentMonth)))"
            Haptics.mediumImpact()
        } catch {
            seedingSummary = "Failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Test Milestone Celebration
    private func triggerTestMilestone() {
        // Pick a random milestone for testing
        let testMilestones: [(Int, DeliveryManager.MilestoneCelebration.MilestoneType)] = [
            (100, .babies),
            (250, .babies),
            (500, .babies),
            (1000, .babies),
            (100, .deliveries),
            (500, .deliveries)
        ]
        let (count, type) = testMilestones.randomElement() ?? (500, .babies)
        deliveryManager.pendingMilestoneCelebration = DeliveryManager.MilestoneCelebration(
            count: count,
            type: type
        )
    }
    #endif
}

// MARK: - Seeding Helpers
#if DEBUG
fileprivate func clamp(_ x: Double, min lo: Double, max hi: Double) -> Double {
    Swift.max(lo, Swift.min(hi, x))
}

fileprivate func normal(mean: Double, sd: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(max(u1, 1e-12))) * cos(2.0 * .pi * u2)
    return mean + sd * z0
}

fileprivate extension Bool {
    static func random(probability p: Double) -> Bool {
        guard p > 0 else { return false }
        if p >= 1 { return true }
        return Double.random(in: 0...1) < p
    }
}
#endif

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
        .environment(DeliveryManager(context: context))
        .environment(CloudSyncManager())
}
