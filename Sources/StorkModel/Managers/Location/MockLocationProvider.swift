//
//  MockLocationProvider.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import Foundation

public class MockLocationProvider: LocationProviderInterface {
    private let mockLatitude: Double
    private let mockLongitude: Double
    private let mockCity: String?
    private let mockState: String?

    public init(
        mockLatitude: Double = 40.7128, // Default: New York City latitude
        mockLongitude: Double = -74.0060, // Default: New York City longitude
        mockCity: String? = "Fort Wayne",
        mockState: String? = "IN"
    ) {
        self.mockLatitude = mockLatitude
        self.mockLongitude = mockLongitude
        self.mockCity = mockCity
        self.mockState = mockState
    }

    public func fetchCurrentLocation() async throws -> (latitude: Double, longitude: Double) {
        // Simulate a delay for realism, if necessary
        try await Task.sleep(nanoseconds: 500_000_000) // 500 ms
        return (mockLatitude, mockLongitude)
    }

    public func fetchCityAndState(from location: Location) async throws -> (city: String?, state: String?) {
        // Simulate a delay for realism, if necessary
        try await Task.sleep(nanoseconds: 500_000_000) // 500 ms
        return (mockCity, mockState)
    }

    public func geocodeAddress(_ address: String) async throws -> (latitude: Double, longitude: Double) {
        // Simulate geocoding by returning mock coordinates
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate delay for realism
        
        // Return predefined coordinates for the mock address
        switch address.lowercased() {
        case "1600 amphitheatre parkway, mountain view, ca":
            return (37.4220, -122.0841) // Googleplex
        case "one apple park way, cupertino, ca":
            return (37.3349, -122.0090) // Apple HQ
        case "fort wayne, in":
            return (41.0793, -85.1394) // Fort Wayne, Indiana
        default:
            return (mockLatitude, mockLongitude) // Default to mock location
        }
    }
}
