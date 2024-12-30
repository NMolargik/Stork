//
//  HospitalViewModel.swift
//
//
//  Created by Nick Molargik on 11/21/24.
//

import Foundation
import SwiftUI
import StorkModel

@MainActor
class HospitalViewModel: ObservableObject {
    // MARK: - AppStorage
    @AppStorage("errorMessage") var errorMessage: String = ""

    // MARK: - Published Properties
    @Published var hospitals: [Hospital] = []
    @Published var primaryHospital: Hospital?
    
    @Published var isWorking: Bool = false
    @Published var searchQuery: String = ""
    @Published var searchEnabled: Bool = true
    @Published var usingLocation: Bool = true
    @Published var selectedHospital: Hospital?
    @Published var isMissingHospitalSheetPresented: Bool = false
    
    // MARK: - Dependencies
    let hospitalRepository: HospitalRepositoryInterface
    let locationProvider: LocationProviderInterface

    // MARK: - Initializer
    public init(hospitalRepository: HospitalRepositoryInterface,
                locationProvider: LocationProviderInterface)
    {
        self.hospitalRepository = hospitalRepository
        self.locationProvider = locationProvider
        
        Task {
            do {
                try await fetchHospitalsNearby()
            } catch {
                // Error handling is done within `fetchHospitalsNearby()`
            }
        }
    }
    
    // MARK: - Fetch Hospitals Nearby
    /// Fetches hospitals near the user's current location.
    public func fetchHospitalsNearby() async throws {
        searchQuery = ""
        usingLocation = true
        isWorking = true
        defer { isWorking = false }
        
        do {
            let location = try await locationProvider.fetchCurrentLocation()
            let cityState = try await locationProvider.fetchCityAndState(
                from: Location(latitude: location.latitude, longitude: location.longitude)
            )
            
            self.hospitals = try await hospitalRepository.getHospitals(
                byCity: cityState.city ?? "San Francisco",
                andState: cityState.state ?? "CA"
            )
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Search Hospitals by Partial Name
    /// Searches hospitals by a partial name.
    public func searchHospitals() async throws {
        usingLocation = false
        isWorking = true
        defer { isWorking = false }
        
        do {
            let results = try await hospitalRepository.searchHospitals(byPartialName: searchQuery)
            self.hospitals = results
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Fetch User's Primary Hospital
    /// Loads the primary hospital for a given profile, if it exists.
    public func getUserPrimaryHospital(profile: Profile) async throws {
        guard !profile.primaryHospitalId.isEmpty else {
            return
        }
        do {
            self.primaryHospital = try await hospitalRepository.getHospital(byId: profile.primaryHospitalId)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Update Hospital with a New Delivery
    /// Updates hospital stats (deliveryCount, babyCount) after a new delivery.
    public func updateHospitalWithNewDelivery(hospital: Hospital, babyCount: Int) async throws {
        isWorking = true
        defer { isWorking = false }
        
        do {
            let updatedHospital = try await hospitalRepository.updateHospitalStats(
                hospital: hospital,
                additionalDeliveryCount: 1, // Hard-coded to 1 extra delivery
                additionalBabyCount: babyCount
            )
            
            // Replace the existing hospital in the local array
            if let index = hospitals.firstIndex(where: { $0.id == hospital.id }) {
                hospitals[index] = updatedHospital
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
