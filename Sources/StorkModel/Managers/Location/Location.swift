//
//  Location.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import Foundation

/// A lat/lon location (in degrees).
public struct Location : Hashable, Codable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public func coordinates(fractionalDigits: Int? = nil) -> (latitude: Double, longitude: Double) {
        guard let fractionalDigits = fractionalDigits else {
            return (latitude, longitude)
        }
        let factor = pow(10.0, Double(fractionalDigits))
        return (latitude: Double(round(latitude * factor)) / factor, longitude: Double(round(longitude * factor)) / factor)
    }

    /// Calculate the distance from another Location using the Haversine formula and returns the distance in kilometers
    public func distance(from location: Location) -> Double {
        let lat1 = self.latitude
        let lon1 = self.longitude
        let lat2 = location.latitude
        let lon2 = location.longitude

        let dLat = (lat2 - lat1).toRadians
        let dLon = (lon2 - lon1).toRadians

        let slat: Double = sin(dLat / 2.0)
        let slon: Double = sin(dLon / 2.0)
        let a: Double = slat * slat + cos(lat1.toRadians) * cos(lat2.toRadians) * slon * slon
        let c: Double = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))

        return c * 6371.0 // earthRadiusKilometers
    }
}
