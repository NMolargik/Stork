//
//  DebugSampleBirths.swift
//  StorkCore
//
//  DEBUG-only deterministic sample births spanning the previous and current calendar
//  year, with roles, twins, nurse catches, a triplet set, and a few losses. Used by the
//  "Add Sample Data (2 Years)" debug button and the `-StorkSeedWrapSample` launch option.
//

#if DEBUG
import Foundation

public enum DebugSampleBirths {

    /// Roughly 20 months of births ending just before `now`, deterministic for a given day.
    public static func twoYears(now: Date = .now, calendar: Calendar = .current) -> [Delivery] {
        var rng = SplitMix(seed: 0x57_0121)
        let thisYear = calendar.component(.year, from: now)
        let start = calendar.date(from: DateComponents(year: thisYear - 1, month: 3, day: 1)) ?? now
        let roles: [BirthRole?] = [.primaryNurse, .primaryNurse, .primaryNurse, .transitionNurse, .transitionNurse, .chargeNurse, .preceptor, nil]
        var result: [Delivery] = []
        var day = start
        var index = 0
        while day < now {
            // Two or three days in five have a birth; a late-spring cluster gives a clear busiest month.
            let month = calendar.component(.month, from: day)
            let perDay = (month == 5 || month == 10) ? 2 : 1
            if rng.chance(0.42) {
                for _ in 0..<perDay where rng.chance(0.8) {
                    let hour = rng.int(0, 23)
                    guard let when = calendar.date(bySettingHour: hour, minute: rng.int(0, 3) * 15, second: 0, of: day), when < now else { continue }
                    index += 1
                    let multiples = index % 17 == 0 ? 2 : (index % 61 == 0 ? 3 : 1)
                    var babies: [Baby] = []
                    for b in 0..<multiples {
                        let loss = (index % 23 == 0 && b == 0) && multiples == 1
                        babies.append(Baby(
                            nurseCatch: rng.chance(0.12),
                            nicuStay: rng.chance(0.08),
                            sex: loss ? .loss : (rng.chance(0.51) ? .male : .female),
                            weight: 90 + Double(rng.int(0, 60)),
                            height: 18 + Double(rng.int(0, 40)) / 10,
                            birthday: when
                        ))
                    }
                    let method: DeliveryMethod = rng.chance(0.3) ? .cSection : (rng.chance(0.03) ? .vBac : .vaginal)
                    let delivery = Delivery(
                        date: when, babies: babies, babyCount: babies.count, deliveryMethod: method,
                        epiduralUsed: method != .vaginal || rng.chance(0.7), role: roles[rng.int(0, roles.count - 1)]
                    )
                    for baby in babies { baby.delivery = delivery }
                    result.append(delivery)
                }
            }
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? now
        }
        return result
    }

    private struct SplitMix {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
        mutating func chance(_ p: Double) -> Bool { Double(next() % 10_000) / 10_000 < p }
        mutating func int(_ lo: Int, _ hi: Int) -> Int { lo + Int(next() % UInt64(hi - lo + 1)) }
    }
}
#endif
