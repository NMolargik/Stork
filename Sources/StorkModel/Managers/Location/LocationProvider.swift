//
//  LocationProvider.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//


import SkipFoundation
import Combine
import SkipModel

#if !SKIP
import CoreLocation
#endif

public class LocationProvider: NSObject, LocationProviderInterface {
    public private(set) var location: Location?
    private var completion: ((Result<(Double, Double), Error>) -> Void)?
    public private(set) var city: String? = nil
    public private(set) var state: String? = nil
    
#if !SKIP
    let locationManager = CLLocationManager()
#endif
    
    public override init() {
        super.init()
    #if !SKIP
        locationManager.delegate = self
    #endif
    }
    
    public func isAuthorized() -> Bool {
        #if !SKIP
        return self.locationManager.authorizationStatus == .authorizedWhenInUse
        #else
        return true
        #endif
    }
    
    public func fetch() async throws {
        let (latitude, longitude) = try await fetchCurrentLocation()
        location = Location(latitude: latitude, longitude: longitude)
        
        let (city, state) = try await fetchCityAndState(from: location!)
        self.city = city
        self.state = state
    }
    
    public func fetchCurrentLocation() async throws -> (latitude: Double, longitude: Double) {
        #if !SKIP
            requestLocationOrAuthorization()

            return try await withCheckedThrowingContinuation { continuation in
                self.completion = { result in
                    // Ensure continuation is only called once
                    guard self.completion != nil else { return }
                    self.completion = nil // Clear completion to prevent reuse
                    
                    switch result {
                    case .success(let location):
                        continuation.resume(returning: location)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                // **Safety Timeout**: Ensure continuation doesn't leak
                Task {
                    try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    if self.completion != nil {
                        self.completion = nil
                        continuation.resume(throwing: NSError(
                            domain: "LocationError",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Location request timed out."]
                        ))
                    }
                }
            }
        #else
            let context = ProcessInfo.processInfo.androidContext
            guard let (latitude, longitude) = fetchCurrentLocation(context) else {
                throw NSError(
                    domain: "LocationError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to fetch location in SKIP context."]
                )
            }
            return (latitude, longitude)
        #endif
    }
    
    public func geocodeAddress(_ address: String) async throws -> (latitude: Double, longitude: Double) {
    #if !SKIP
        // For non-SKIP environments (e.g., iOS/macOS)
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw NSError(
                domain: "GeocodingError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not geocode address."]
            )
        }
        return (latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    #else
        let context = ProcessInfo.processInfo.androidContext
        guard let (latitude, longitude) = geocodeAddress(context, address) else {
            throw NSError(
                domain: "GeocodingError",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not geocode address in SKIP context."]
            )
        }
        return (latitude, longitude)
    #endif
    }
    
    
    public func fetchCityAndState(from location: Location) async throws -> (city: String?, state: String?) {
    #if !SKIP
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
        
        guard let placemark = placemarks.first else {
            throw NSError(
                domain: "ReverseGeocodingError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not determine city and state from location."]
            )
        }
        let city = placemark.locality // City or town name
        let state = placemark.administrativeArea // Full state name
        
        return (city, state)
    #else
        let context = ProcessInfo.processInfo.androidContext
        guard let (city, state) = fetchCityAndState(context, location.latitude, location.longitude) else {
            throw NSError(
                domain: "ReverseGeocodingError",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not fetch city and state in SKIP context."]
            )
        }
        return (city, state)
    #endif

    }
    
    let stateAbbreviations: [String: String] = [
        "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR", "California": "CA",
        "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE", "Florida": "FL", "Georgia": "GA",
        "Hawaii": "HI", "Idaho": "ID", "Illinois": "IL", "Indiana": "IN", "Iowa": "IA",
        "Kansas": "KS", "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
        "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
        "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV", "New Hampshire": "NH",
        "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY", "North Carolina": "NC",
        "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK", "Oregon": "OR", "Pennsylvania": "PA",
        "Rhode Island": "RI", "South Carolina": "SC", "South Dakota": "SD", "Tennessee": "TN",
        "Texas": "TX", "Utah": "UT", "Vermont": "VT", "Virginia": "VA", "Washington": "WA",
        "West Virginia": "WV", "Wisconsin": "WI", "Wyoming": "WY"
    ]
}

#if !SKIP
extension LocationProvider: CLLocationManagerDelegate {

    private func requestLocationOrAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            locationManager.requestLocation()
        }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if completion != nil {
            requestLocationOrAuthorization()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        completion?(.success((location.coordinate.latitude, location.coordinate.longitude)))
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
    }
}
#endif

