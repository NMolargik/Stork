//
//  HospitalsView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI
import CoreLocation

extension HospitalsView {
    @Observable
    class ViewModel {
        var searchText: String = ""
        var userState: String?

        /// Returns hospitals filtered by search text (or by user's state when search is empty),
        /// and promotes the user's primary hospital to the top when present.
        func filteredHospitals(hospitals: [Hospital], primaryId: String?) -> [Hospital] {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            // Step 1: Filter base set
            let base: [Hospital]
            if query.isEmpty, let state = userState, !state.isEmpty {
                base = hospitals.filter { $0.state.lowercased() == state.lowercased() }
            } else {
                base = hospitals.filter { hospital in
                    guard !query.isEmpty else { return true }
                    return hospital.facilityName.lowercased().contains(query)
                        || hospital.citytown.lowercased().contains(query)
                        || hospital.state.lowercased().contains(query)
                        || hospital.zipCode.lowercased().contains(query)
                }
            }

            // Step 2: Promote primary hospital to top
            guard let primaryId, let idx = base.firstIndex(where: { $0.remoteId == primaryId }) else { return base }
            var reordered = base
            let primary = reordered.remove(at: idx)
            reordered.insert(primary, at: 0)
            return reordered
        }

        /// Asynchronously resolves and stores the user's state using CoreLocation reverse geocoding.
        @MainActor
        func startUserStateLookup(locationManager: LocationManager) async {
            do {
                let location = try await locationManager.currentLocation()
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first, let state = placemark.administrativeArea {
                    self.userState = state
                } else {
                    self.userState = nil
                }
            } catch {
                print("Failed to get user location: \(error)")
                self.userState = nil
            }
        }
    }
}
