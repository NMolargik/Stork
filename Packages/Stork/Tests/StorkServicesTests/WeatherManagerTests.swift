//
//  WeatherManagerTests.swift
//  StorkServicesTests
//
//  Verifies WeatherManager's error mapping with fake location and weather providers.
//

import Testing
import Foundation
import CoreLocation
@testable import StorkServices

private struct FailingWeatherProvider: WeatherProviding {
    func currentConditions(for location: CLLocation) async throws -> CurrentConditions {
        throw WeatherError.weatherServiceFailed
    }
}

@MainActor
private final class FakeLocationProvider: LocationProviding {
    var isAuthorized: Bool = true
    var locationToReturn: CLLocation = CLLocation(latitude: 41.0793, longitude: -85.1394)
    var errorToThrow: Error?
    private(set) var requestCount = 0

    func requestAuthorization() {}

    func currentLocation() async throws -> CLLocation {
        requestCount += 1
        if let errorToThrow { throw errorToThrow }
        return locationToReturn
    }
}

@Suite("WeatherManager Behavior Tests")
@MainActor
struct WeatherManagerTests {

    @Test("Refresh without a location provider sets an error")
    func missingLocationProvider() async {
        let manager = WeatherManager(provider: FailingWeatherProvider())
        await manager.refresh()
        #expect(manager.error as? WeatherError == WeatherError.locationProviderMissing)
    }

    @Test("Location failure maps to locationUnavailable")
    func locationFailure() async {
        let location = FakeLocationProvider()
        location.errorToThrow = LocationError.notAuthorized
        let manager = WeatherManager(provider: FailingWeatherProvider(), locationProvider: location)
        await manager.refresh()
        #expect(manager.error as? WeatherError == WeatherError.locationUnavailable)
    }

    @Test("Weather service failure maps to weatherServiceFailed")
    func weatherFailure() async {
        let manager = WeatherManager(provider: FailingWeatherProvider(), locationProvider: FakeLocationProvider())
        await manager.refresh()
        #expect(manager.error as? WeatherError == WeatherError.weatherServiceFailed)
    }
}
