//
//  LocationProviderInterface.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import Foundation

public protocol LocationProviderInterface {
    func isAuthorized() -> Bool
    
    /// Fetches the current latitude and longitude.
    func fetchCurrentLocation() async throws -> (latitude: Double, longitude: Double)

    /// Fetches the city and state for a given location.
    func fetchCityAndState(from location: Location) async throws -> (city: String?, state: String?)
    
    func geocodeAddress(_ address: String) async throws -> (latitude: Double, longitude: Double)
}
