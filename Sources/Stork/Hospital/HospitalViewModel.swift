//
//  HospitalViewModel.swift
//
//
//  Created by Nick Molargik on 11/21/24.
//

import SkipFoundation
import SwiftUI
import StorkModel

@MainActor
class HospitalViewModel: ObservableObject {
    // MARK: - AppStorage
    @AppStorage("errorMessage") var errorMessage: String = ""

    // MARK: - Published Properties
    @Published private(set) var hospitals: [Hospital] = []
    @Published private(set) var primaryHospital: Hospital?

    @Published var isWorking: Bool = false
    @Published var searchQuery: String = ""
    @Published var searchEnabled: Bool = true
    #if SKIP
    @Published var usingLocation: Bool = false
    #else
    @Published var usingLocation: Bool = true
    #endif
    
    @Published var selectedHospital: Hospital?
    @Published var isMissingHospitalSheetPresented: Bool = false

    // MARK: - Dependencies
    private let hospitalRepository: HospitalRepositoryInterface
    let locationProvider: LocationProviderInterface

    // MARK: - Initializer
    init(hospitalRepository: HospitalRepositoryInterface,
         locationProvider: LocationProviderInterface)
    {
        self.hospitalRepository = hospitalRepository
        self.locationProvider = locationProvider
    }
    
    func reset() {
        self.hospitals = []
        self.primaryHospital = nil
        self.selectedHospital = nil
        self.searchQuery = ""
        self.usingLocation = true
    }

    // MARK: - Fetch Hospitals Nearby
    /// Fetches hospitals near the user's current location.
    public func fetchHospitalsNearby() async {
        resetSearch()
        await executeAsync {
            let location = try await self.locationProvider.fetchCurrentLocation()
            let cityState = try await self.locationProvider.fetchCityAndState(
                from: Location(latitude: location.latitude, longitude: location.longitude)
            )
            
            if cityState.city == "" || cityState.state == "" {
                return
            }

            self.hospitals = try await self.hospitalRepository.getHospitals(
                state: cityState.state ?? "CA"
            )
            
            self.hospitals.sort { $0.facility_name < $1.facility_name }
        }
    }

    // MARK: - Search Hospitals by Partial Name
    /// Searches hospitals by a partial name.
    public func searchHospitals() async {
        usingLocation = false
        await executeAsync {
            do {
                self.hospitals = try await self.hospitalRepository.searchHospitals(byPartialName: self.searchQuery)
            } catch {
                self.hospitals = []
            }
        }
    }

    // MARK: - Create a Missing Hospital
    public func createMissingHospital(name: String) async throws -> Hospital {
        try await hospitalRepository.createHospital(name: name)
    }

    // MARK: - Fetch User's Primary Hospital
    /// Loads the primary hospital for a given profile, if it exists.
    public func getUserPrimaryHospital(profile: Profile) async {
        guard !profile.primaryHospitalId.isEmpty else { return }
        await executeAsync {
            self.primaryHospital = try await self.hospitalRepository.getHospital(byId: profile.primaryHospitalId)
        }
    }

    // MARK: - Update Hospital with a New Delivery
    /// Updates hospital stats (deliveryCount, babyCount) after a new delivery.
    public func updateHospitalWithNewDelivery(hospital: Hospital, babyCount: Int) async {
        await executeAsync {
            let updatedHospital = try await self.hospitalRepository.updateHospitalStats(
                hospital: hospital,
                additionalDeliveryCount: 1, // Hard-coded to 1 extra delivery
                additionalBabyCount: babyCount
            )

            // Update hospital in local array
            self.hospitals = self.hospitals.map { $0.id == hospital.id ? updatedHospital : $0 }
        }
    }

    // MARK: - Private Helper Methods
    private func resetSearch() {
        searchQuery = ""
        usingLocation = true
    }

    /// Handles async tasks with error management.
    private func executeAsync(_ task: @escaping () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }

        do {
            try await task()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
