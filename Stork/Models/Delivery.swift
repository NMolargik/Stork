//
//  Delivery.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation
import SwiftData

/// Represents a delivery event within the Stork application.
@Model
final class Delivery {
    var id: UUID = UUID()
    var date: Date = Date.now
    @Relationship(deleteRule: .cascade) var babies: [Baby]?
    var babyCount: Int = 0
    var deliveryMethod: DeliveryMethod = DeliveryMethod.vaginal
    var epiduralUsed: Bool = false
    var notes: String?
    @Relationship(inverse: \DeliveryTag.deliveries) var tags: [DeliveryTag]?

    init(
        id: UUID = UUID(),
        date: Date,
        babies: [Baby] = [],
        babyCount: Int,
        deliveryMethod: DeliveryMethod,
        epiduralUsed: Bool,
        notes: String? = nil,
        tags: [DeliveryTag] = []
    ) {
        self.id = id
        self.date = date
        self.babies = babies
        self.babyCount = babyCount
        self.deliveryMethod = deliveryMethod
        self.epiduralUsed = epiduralUsed
        self.notes = notes
        self.tags = tags
    }

    init?(from dictionary: [String: Any], id: String?) {
        print("\n[Delivery Init Debug] Provided dictionary: " + String(describing: dictionary))
        print("[Delivery Init Debug] Provided id: " + String(describing: id))

        // If no id is provided from Firebase, keep auto-generated UUID()
        if id == nil {
            print("[Delivery Init Debug] Warning: id is nil from Firebase; using a new UUID().")
        }

        guard let dateTimestamp = dictionary["date"] as? TimeInterval else {
            print("[Delivery Init Debug] Error: date missing or not a TimeInterval. Value: " + String(describing: dictionary["date"]))
            return nil
        }

        var babyCountValue: Int = 0
        if let bcNumber = dictionary["babyCount"] as? NSNumber { babyCountValue = bcNumber.intValue }
        else if let bcInt = dictionary["babyCount"] as? Int { babyCountValue = bcInt }
        else if let bcDouble = dictionary["babyCount"] as? Double { babyCountValue = Int(bcDouble) }
        else if let bcString = dictionary["babyCount"] as? String, let bcFromString = Int(bcString) { babyCountValue = bcFromString }

        guard let deliveryMethodRawValue = dictionary["deliveryMethod"] as? String,
              let deliveryMethod = DeliveryMethod(rawValue: deliveryMethodRawValue) else {
            print("[Delivery Init Debug] Error: deliveryMethod missing/invalid. Value: " + String(describing: dictionary["deliveryMethod"]))
            return nil
        }
        guard let epiduralUsed = dictionary["epiduralUsed"] as? Bool else {
            print("[Delivery Init Debug] Error: epiduralUsed missing or not a Bool. Value: " + String(describing: dictionary["epiduralUsed"]))
            return nil
        }

        // Parse babies
        var babiesData: [Any]?
        if let babiesArray = dictionary["babies"] as? [Any] {
            babiesData = babiesArray
        } else if let singleBaby = dictionary["babies"] as? [String: Any] {
            babiesData = [singleBaby]
        }
        guard let babiesList = babiesData else {
            print("[Delivery Init Debug] Error: 'babies' field missing or invalid (expected an array or single dictionary).")
            return nil
        }

        let isoFormatter = ISO8601DateFormatter()
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        var parsedBabies = [Baby]()
        for (index, item) in babiesList.enumerated() {
            guard let babyMap = item as? [String: Any] else {
                print("[Delivery Init Debug] Error: 'babies' entry at index \(index) is invalid. Value: " + String(describing: item))
                return nil
            }
            let nurseCatch = (babyMap["nurseCatch"] as? Bool) ?? false
            let nicuStay = (babyMap["nicuStay"] as? Bool) ?? false
            var sex: Sex = .male
            if let sexRaw = babyMap["sex"] as? String, let s = Sex(rawValue: sexRaw) { sex = s }
            let weight = (babyMap["weight"] as? Double) ?? 121.6
            let height = (babyMap["height"] as? Double) ?? 19.0
            var birthday = Date()
            if let birthdayString = babyMap["birthday"] as? String {
                birthday = isoFormatter.date(from: birthdayString) ?? fallbackFormatter.date(from: birthdayString) ?? Date()
            }
            let baby = Baby(
                nurseCatch: nurseCatch,
                nicuStay: nicuStay,
                sex: sex,
                weight: weight,
                height: height,
                birthday: birthday,
                delivery: nil
            )
            parsedBabies.append(baby)
        }

        // Initialize self
        self.id = UUID()
        self.date = Date(timeIntervalSince1970: dateTimestamp)
        self.babies = []
        self.deliveryMethod = deliveryMethod
        self.epiduralUsed = epiduralUsed
        self.babyCount = babyCountValue > 0 ? babyCountValue : parsedBabies.count

        self.babies = parsedBabies
        for baby in self.babies ?? [] { baby.delivery = self }
    }

    static func sample() -> Delivery {
        let delivery = Delivery(
            date: Date(),
            babyCount: 3,
            deliveryMethod: .vaginal,
            epiduralUsed: true,
            notes: "Twins on Christmas! Such a memorable delivery.",
            tags: []
        )
        let b1 = Baby(nurseCatch: true, nicuStay: false, sex: .male, weight: 121.6, height: 19.0, birthday: Date(), delivery: delivery)
        let b2 = Baby(nurseCatch: false, nicuStay: true, sex: .female, weight: 121.6, height: 19.0, birthday: Date(), delivery: delivery)
        let b3 = Baby(nurseCatch: false, nicuStay: false, sex: .loss, weight: 121.6, height: 19.0, birthday: Date(), delivery: delivery)
        delivery.babies = [b1, b2, b3]
        return delivery
    }
}

