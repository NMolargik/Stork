//
//  SettingsModel.swift
//  StorkFeatureSettings
//
//  Backs the Settings screen: delivery count, delete-all, online state, app version, and
//  (DEBUG) sample-data seeding — all through use-cases.
//

import Foundation
import Observation
import Network
import StorkCore

@MainActor
@Observable
public final class SettingsModel {
    private let loadDeliveriesUseCase: any LoadDeliveries
    private let deleteAllDeliveriesUseCase: any DeleteAllDeliveries
    private let logDeliveryUseCase: any LogDelivery

    public private(set) var deliveries: [Delivery] = []
    public private(set) var lastError: PersistenceError?
    public var isOnline = true

    private var networkMonitor: NWPathMonitor?

    public init(
        loadDeliveries: any LoadDeliveries,
        deleteAllDeliveries: any DeleteAllDeliveries,
        logDelivery: any LogDelivery
    ) {
        self.loadDeliveriesUseCase = loadDeliveries
        self.deleteAllDeliveriesUseCase = deleteAllDeliveries
        self.logDeliveryUseCase = logDelivery
    }

    public var deliveryCount: Int { deliveries.count }

    public func load() {
        do {
            deliveries = try loadDeliveriesUseCase()
            lastError = nil
        } catch {
            lastError = error
        }
    }

    /// Deletes every delivery in one repository transaction (one side-effect pass).
    public func deleteAll() {
        do {
            try deleteAllDeliveriesUseCase()
            lastError = nil
        } catch {
            lastError = error
        }
        load()
    }

    public var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "—"
        return "\(version) (Build \(build))"
    }

    // MARK: - Network monitoring

    public func startNetworkMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { @Sendable [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
        networkMonitor = monitor
    }

    public func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }

    #if DEBUG
    // MARK: - Sample data (DEBUG)

    /// Seeds ~12 months of realistic sample deliveries through the log use-case.
    public func seedSampleData() async -> String {
        let cal = Calendar.current
        let now = Date()
        let startOfCurrentMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now

        let pCSection = 0.323, pVBAC = 0.02, pMale = 0.511, pLoss = 0.07
        let pPreterm = 0.1041, pNICUBase = 0.098, pTwins = 0.0307, pTripPlus = 0.000738
        let pNurseCatch = 0.10, pEpiduralVag = 0.70

        var inserted = 0, insertedBabies = 0

        for monthsAgo in stride(from: 11, through: 0, by: -1) {
            let monthStart = cal.date(byAdding: .month, value: -monthsAgo, to: startOfCurrentMonth)!
            let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart)!
            let monthEnd = min(nextMonth, now)
            let daysInMonth = cal.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 28
            let deliveriesThisMonth = max(8, Int(round(normal(mean: 13.0, sd: 3.0))))

            for _ in 0..<deliveriesThisMonth {
                let randomDay = Int.random(in: 0..<max(1, daysInMonth))
                let dayDate = cal.date(byAdding: .day, value: randomDay, to: monthStart) ?? monthStart
                let hour = Int.random(in: 0...23)
                let minute = [0, 15, 30, 45].randomElement() ?? 0
                var when = cal.date(bySettingHour: hour, minute: minute, second: 0, of: dayDate) ?? dayDate
                if when > now { when = now.addingTimeInterval(-60) }

                let methodPick = Double.random(in: 0...1)
                let method: DeliveryMethod = methodPick < pCSection ? .cSection : (methodPick < pCSection + pVBAC ? .vBac : .vaginal)
                let epidural = method == .vaginal ? Bool.seededRandom(pEpiduralVag) : true

                let multPick = Double.random(in: 0...1)
                let babyCount = multPick < pTripPlus ? 3 : (multPick < pTripPlus + pTwins ? 2 : 1)

                var babies: [Baby] = []
                for _ in 0..<babyCount {
                    let r = Double.random(in: 0...1)
                    let sex: Sex = r < pLoss ? .loss : (r < pLoss + pMale ? .male : .female)
                    let isPreterm = Bool.seededRandom(pPreterm)
                    let nicu = Bool.seededRandom(min(0.85, isPreterm ? pNICUBase + 0.40 : pNICUBase * 0.85))
                    let weight = isPreterm ? clamp(normal(mean: 88, sd: 18), 40, 130) : clamp(normal(mean: 120, sd: 16), 70, 160)
                    let length = isPreterm ? clamp(normal(mean: 18.0, sd: 1.0), 14.0, 20.5) : clamp(normal(mean: 20.0, sd: 0.9), 18.0, 22.5)
                    babies.append(Baby(nurseCatch: Bool.seededRandom(pNurseCatch), nicuStay: nicu, sex: sex, weight: weight, height: length, birthday: when))
                }

                let delivery = Delivery(date: when, babies: babies, babyCount: babies.count, deliveryMethod: method, epiduralUsed: epidural)
                for b in babies { b.delivery = delivery }
                _ = try? logDeliveryUseCase(delivery)
                inserted += 1
                insertedBabies += babies.count
            }
        }

        load()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        let oldest = cal.date(byAdding: .month, value: -11, to: startOfCurrentMonth)!
        return "Added \(inserted) deliveries, \(insertedBabies) babies (\(formatter.string(from: oldest)) – \(formatter.string(from: startOfCurrentMonth)))"
    }
    #endif
}

#if DEBUG
private func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double { Swift.max(lo, Swift.min(hi, x)) }

private func normal(mean: Double, sd: Double) -> Double {
    let u1 = Double.random(in: 0..<1), u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(max(u1, 1e-12))) * cos(2.0 * .pi * u2)
    return mean + sd * z0
}

private extension Bool {
    static func seededRandom(_ p: Double) -> Bool {
        guard p > 0 else { return false }
        if p >= 1 { return true }
        return Double.random(in: 0...1) < p
    }
}
#endif
